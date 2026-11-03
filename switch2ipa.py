#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
==============================================================================
NSWPORTIOS: switch2ipa
Compilador universal de juegos de Nintendo Switch (NSP, XCI, NSZ, XCZ) a IPA para iOS.
==============================================================================
"""

import os
import sys
import re
import shutil
import argparse
import subprocess
from pathlib import Path

# Colores para la consola
class Colors:
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'
    END = '\033[0m'

def print_banner():
    banner = f"""{Colors.CYAN}{Colors.BOLD}
  ╔════════════════════════════════════════════════════════════════════╗
  ║                 NSWPORTIOS : SWITCH ➔ iOS (.IPA)                   ║
  ║  Compilador Nativo para NSP, XCI, NSZ y XCZ a Apple Silicon (iOS)  ║
  ╚════════════════════════════════════════════════════════════════════╝{Colors.END}
"""
    print(banner)

def find_prod_keys(base_dir, custom_keys_path=None):
    """Busca el archivo prod.keys en el directorio keys/ o en ubicaciones estándar."""
    if custom_keys_path and Path(custom_keys_path).is_file():
        return Path(custom_keys_path).resolve()

    candidates = [
        base_dir / "keys" / "prod.keys",
        base_dir / "keys" / "keys.txt",
        Path.home() / "Library/Mobile Documents/com~apple~CloudDocs/Games Roms/NSP/Key y FW/prod.keys",
        Path.home() / ".switch" / "prod.keys",
        Path.home() / ".config" / "yuzu" / "keys" / "prod.keys",
        Path.home() / ".config" / "Ryujinx" / "system" / "prod.keys",
        Path.home() / "Library" / "Application Support" / "Ryujinx" / "system" / "prod.keys",
    ]

    keys_dir = base_dir / "keys"
    if keys_dir.exists():
        for kf in keys_dir.glob("*.keys"):
            if not kf.name.startswith("._") and kf.is_file() and kf not in candidates:
                candidates.insert(0, kf)

    for cand in candidates:
        if not cand.name.startswith("._") and cand.is_file() and cand.stat().st_size > 0:
            return cand.resolve()

    return None

def scan_games(input_dir):
    """Escanea el directorio input en busca de archivos de Switch válidos."""
    supported_exts = {'.nsp', '.xci', '.nsz', '.xcz'}
    files = []
    for ext in supported_exts:
        files.extend(list(input_dir.glob(f"*{ext}")))
        files.extend(list(input_dir.glob(f"*{ext.upper()}")))

    valid_files = [f for f in files if not f.name.startswith('._') and f.stat().st_size > 0]
    return sorted(valid_files, key=lambda x: x.name.lower())

def group_games_by_title(files):
    """Agrupa juegos por título o title ID si hay base, updates y DLCs."""
    games = {}
    for f in files:
        m = re.search(r'\[([0-9A-Fa-f]{16})\]', f.name)
        if m:
            tid_raw = int(m.group(1), 16)
            low = tid_raw & 0xFFF
            if low == 0:
                base_tid = tid_raw
            elif low == 0x800:
                base_tid = tid_raw & ~0xFFF
            else:
                base_tid = (tid_raw & ~0xFFF) - 0x1000
            key = f"{base_tid:016X}"
        else:
            clean_name = re.sub(r'\[.*?\]|\(.*?\)', '', f.stem).strip().lower()
            key = clean_name or f.stem

        if key not in games:
            games[key] = []
        games[key].append(f)
    return games

def ensure_python_environment(base_dir):
    """Localiza el ejecutable de Python 3.12 con las dependencias."""
    candidates = [
        Path.home() / ".nswportios_venv" / "bin" / "python3",
        base_dir / "tools" / "venv" / "bin" / "python3",
    ]
    for c in candidates:
        if c.exists():
            return str(c)

    # Si el python actual es >= 3.12
    if sys.version_info >= (3, 12):
        return sys.executable

    return sys.executable

def find_engine_repo(base_dir):
    """Localiza el repositorio del motor de compilación."""
    candidates = [
        Path.home() / ".nxnative",
        base_dir / "core",
        Path("/tmp/nxnative_core")
    ]
    for c in candidates:
        if (c / "scripts" / "build_ipa_from_nsp.py").exists() and (c / "dm" / "games").exists():
            return c
    return base_dir / "core"

def is_icloud_dataless(path):
    """Comprueba si un archivo en iCloud está en la nube sin descargar (dataless)."""
    try:
        res = subprocess.run(["ls", "-lO", str(path)], capture_output=True, text=True)
        return "dataless" in res.stdout
    except Exception:
        return False

def prepare_local_game_dir(files, temp_base):
    """Crea un directorio temporal con symlinks SOLO a archivos descargados (no dataless).
    Retorna la ruta del directorio o None si no hay archivos válidos."""
    import tempfile
    local_dir = Path(temp_base) / "game_input"
    local_dir.mkdir(parents=True, exist_ok=True)

    # Limpiar symlinks anteriores
    for existing in local_dir.iterdir():
        if existing.is_symlink():
            existing.unlink()

    valid = 0
    skipped = []
    for f in files:
        if is_icloud_dataless(f):
            skipped.append(f.name)
        else:
            link = local_dir / f.name
            if not link.exists():
                link.symlink_to(f.resolve())
            valid += 1

    if skipped:
        print(f"{Colors.YELLOW}[AVISO] {len(skipped)} archivo(s) en iCloud (no descargados) fueron omitidos:{Colors.END}")
        for s in skipped:
            print(f"   ☁️  {s}")
        if valid > 0:
            print(f"{Colors.GREEN}✓ {valid} archivo(s) locales listos para compilar.{Colors.END}")

    return local_dir if valid > 0 else None

def check_python_deps(py_exec):
    """Verifica que todas las dependencias de Python estén instaladas."""
    check_code = """
import sys
missing = []
try: import lz4.block
except ImportError: missing.append('lz4')
try: import capstone; assert capstone.__version__.startswith('5.')
except: missing.append('"capstone>=5,<6"')
try: import fontTools
except ImportError: missing.append('fonttools')
try: import backports.zstd
except ImportError: missing.append('backports.zstd')
if missing:
    print(','.join(missing))
    sys.exit(1)
"""
    res = subprocess.run([py_exec, "-c", check_code], capture_output=True, text=True)
    if res.returncode != 0:
        return res.stdout.strip().split(',')
    return []

def extract_title_id(filename):
    """Extrae el Title ID base de un archivo de juego."""
    m = re.search(r'\[([0-9A-Fa-f]{16})\]', filename)
    if m:
        tid_raw = int(m.group(1), 16)
        low = tid_raw & 0xFFF
        if low == 0:
            return f"{tid_raw:016X}"
        elif low == 0x800:
            return f"{(tid_raw & ~0xFFF):016X}"
        else:
            return f"{((tid_raw & ~0xFFF) - 0x1000):016X}"
    return None

def main():
    print_banner()

    base_dir = Path(__file__).resolve().parent
    core_dir = find_engine_repo(base_dir)
    build_script = core_dir / "scripts" / "build_ipa_from_nsp.py"
    input_dir = base_dir / "input"
    keys_dir = base_dir / "keys"
    output_dir = base_dir / "output"

    input_dir.mkdir(parents=True, exist_ok=True)
    keys_dir.mkdir(parents=True, exist_ok=True)
    output_dir.mkdir(parents=True, exist_ok=True)

    parser = argparse.ArgumentParser(
        description="NSWPORTIOS: Compilador universal de juegos Nintendo Switch a IPA nativo de iOS",
        formatter_class=argparse.RawTextHelpFormatter
    )
    parser.add_argument("-i", "--input", help="Archivo o carpeta del juego a compilar (por defecto: busca en input/)")
    parser.add_argument("-k", "--keys", help="Ruta al archivo prod.keys (por defecto: busca en keys/)")
    parser.add_argument("-o", "--output", help="Ruta o carpeta de salida del .ipa (por defecto: output/)")
    parser.add_argument("-l", "--lang", default="es", help="Idioma preferido para el juego (ej. es, es-419, en, ja, fr, de). Por defecto: es")
    parser.add_argument("--fps", action="store_true", default=True, help="Mostrar contador de FPS en pantalla (por defecto: activado)")
    parser.add_argument("--no-fps", action="store_false", dest="fps", help="Ocultar contador de FPS en pantalla")
    parser.add_argument("--romfs", choices=["bundle", "separate"], default="bundle",
                        help="bundle = incluye assets en el .ipa (recomendado)\nseparate = extrae romfs para copiar por USB (juegos gigantes)")
    parser.add_argument("--platform", choices=["ios", "mac-app"], default="ios",
                        help="ios = compila un .ipa para iPhone/iPad\nmac-app = compila una app nativa para macOS")

    args = parser.parse_args()

    # 1. Localizar prod.keys
    keys_file = find_prod_keys(base_dir, args.keys)
    if not keys_file:
        print(f"{Colors.RED}{Colors.BOLD}[!] Archivo 'prod.keys' no encontrado.{Colors.END}")
        print(f"\n{Colors.YELLOW}Para continuar:{Colors.END}")
        print(f"1. Copia tu archivo {Colors.BOLD}prod.keys{Colors.END} en la carpeta:")
        print(f"   📂 {Colors.CYAN}{keys_dir}{Colors.END}")
        print(f"2. Vuelve a ejecutar este comando.\n")
        return 1

    print(f"{Colors.GREEN}✓ prod.keys detectado:{Colors.END} {keys_file}")

    # 2. Localizar Juegos
    target_dir = None
    target_title_id = None

    if args.input:
        in_path = Path(args.input).resolve()
        if in_path.is_file():
            # Si es un archivo individual, extraer su title id
            target_title_id = extract_title_id(in_path.name)
            print(f"{Colors.GREEN}✓ Archivo seleccionado:{Colors.END} {in_path.name}")
            if target_title_id:
                print(f"{Colors.GREEN}✓ Title ID identificado:{Colors.END} {target_title_id}")
            if is_icloud_dataless(in_path):
                print(f"{Colors.YELLOW}{Colors.BOLD}[AVISO] El archivo está en iCloud Drive pero aún NO se ha descargado a tu Mac (icono de nubecita ☁️).{Colors.END}")
                print(f"{Colors.CYAN}Iniciando descarga desde iCloud... (por favor espera a que termine de descargarse en Finder antes de compilar){Colors.END}")
                subprocess.run(["brctl", "download", str(in_path)])
                return 1
            # Crear directorio temporal con solo este archivo (evita leer archivos iCloud vecinos)
            temp_game_dir = Path.home() / ".nswportios_build" / "game_input"
            temp_game_dir.mkdir(parents=True, exist_ok=True)
            for old_link in temp_game_dir.iterdir():
                if old_link.is_symlink():
                    old_link.unlink()
            (temp_game_dir / in_path.name).symlink_to(in_path)
            # Si hay archivos de updates/DLC con el mismo base title ID en la misma carpeta, incluirlos
            if target_title_id:
                parent = in_path.parent
                for sibling in parent.iterdir():
                    if sibling == in_path or sibling.name.startswith("._"):
                        continue
                    sibling_tid = extract_title_id(sibling.name)
                    if sibling_tid and not is_icloud_dataless(sibling):
                        # Incluir updates (0x800) y DLCs del mismo base title
                        tid_raw = int(re.search(r'\[([0-9A-Fa-f]{16})\]', sibling.name).group(1), 16)
                        base_raw = int(target_title_id, 16)
                        if (tid_raw & ~0xFFF) == base_raw or (tid_raw & ~0xFFF) == (base_raw & ~0xFFF):
                            link = temp_game_dir / sibling.name
                            if not link.exists():
                                link.symlink_to(sibling.resolve())
                                print(f"{Colors.GREEN}  + Update/DLC incluido:{Colors.END} {sibling.name}")
            target_dir = temp_game_dir
        elif in_path.is_dir():
            # Si es un directorio, filtrar archivos dataless
            supported_exts = {'.nsp', '.xci', '.nsz', '.xcz'}
            all_games = [f for f in in_path.iterdir()
                         if f.suffix.lower() in supported_exts and not f.name.startswith("._")]
            local_dir = prepare_local_game_dir(all_games, Path.home() / ".nswportios_build")
            if local_dir is None:
                print(f"{Colors.RED}[ERROR] No hay archivos de juego descargados localmente en la carpeta.{Colors.END}")
                print(f"{Colors.YELLOW}Descarga primero el juego de iCloud Drive (clic derecho → Descargar ahora).{Colors.END}")
                return 1
            target_dir = local_dir
        else:
            print(f"{Colors.RED}[ERROR] La ruta especificada en --input no existe: {args.input}{Colors.END}")
            return 1
    else:
        games_found = scan_games(input_dir)
        if not games_found:
            print(f"{Colors.RED}{Colors.BOLD}[!] No se encontraron juegos en la carpeta 'input/'.{Colors.END}")
            print(f"\n{Colors.YELLOW}Formatos admitidos:{Colors.END} .nsp, .xci, .nsz, .xcz")
            print(f"\n{Colors.YELLOW}Pasos para compilar:{Colors.END}")
            print(f"1. Coloca tu juego (junto con updates o DLCs si los tienes) en:")
            print(f"   📂 {Colors.CYAN}{input_dir}{Colors.END}")
            print(f"2. Vuelve a ejecutar {Colors.BOLD}./switch2ipa{Colors.END}\n")
            return 1

        grouped = group_games_by_title(games_found)
        if len(grouped) == 1:
            selected_key = list(grouped.keys())[0]
            game_files = grouped[selected_key]
            print(f"{Colors.GREEN}✓ Juego detectado:{Colors.END}")
            for gf in game_files:
                size_mb = gf.stat().st_size / (1024 * 1024)
                print(f"   • {gf.name} ({size_mb:.1f} MB)")
            target_dir = input_dir
            if len(selected_key) == 16:
                target_title_id = selected_key
        else:
            print(f"\n{Colors.YELLOW}Se detectaron múltiples juegos en 'input/':{Colors.END}")
            keys_list = list(grouped.keys())
            for idx, k in enumerate(keys_list, start=1):
                files = grouped[k]
                base_file = files[0].name
                print(f"  [{idx}] {base_file} (+{len(files)-1} archivos relacionados)")

            try:
                choice = input(f"\nSelecciona el número del juego a compilar [1-{len(keys_list)}]: ").strip()
                selected_idx = int(choice) - 1
                if 0 <= selected_idx < len(keys_list):
                    selected_key = keys_list[selected_idx]
                    target_dir = input_dir
                    if len(selected_key) == 16:
                        target_title_id = selected_key
                else:
                    print(f"{Colors.RED}Selección inválida.{Colors.END}")
                    return 1
            except (ValueError, KeyboardInterrupt):
                print(f"\nOperación cancelada.")
                return 1

    # 3. Validar Script Core
    if not build_script.exists():
        print(f"{Colors.RED}[ERROR] No se encontró el motor de compilación en {build_script}{Colors.END}")
        return 1

    # 4. Preparar entorno Python
    py_exec = ensure_python_environment(base_dir)

    # 4.1 Verificar dependencias Python
    missing_deps = check_python_deps(py_exec)
    if missing_deps:
        print(f"{Colors.YELLOW}[AVISO] Instalando dependencias faltantes: {', '.join(missing_deps)}{Colors.END}")
        subprocess.run([py_exec, "-m", "pip", "install", "--quiet"] + missing_deps)
        # Verificar de nuevo
        still_missing = check_python_deps(py_exec)
        if still_missing:
            print(f"{Colors.RED}[ERROR] No se pudieron instalar: {', '.join(still_missing)}{Colors.END}")
            print(f"{Colors.YELLOW}Ejecuta manualmente: {py_exec} -m pip install {' '.join(still_missing)}{Colors.END}")
            return 1
        print(f"{Colors.GREEN}✓ Dependencias instaladas correctamente.{Colors.END}")

    # 5. Construir comando
    cmd = [
        py_exec,
        str(build_script),
        str(target_dir),
        "-k", str(keys_file),
        "-l", args.lang,
        "--platform", args.platform,
        "--romfs", args.romfs,
    ]

    if target_title_id:
        cmd.extend(["--title-id", target_title_id])

    # Flags de tolerancia para maximizar compatibilidad
    cmd.append("--allow-other-metal")
    cmd.append("--allow-damaged")

    if args.fps:
        cmd.append("--show-fps")
    else:
        cmd.append("--no-fps")

    temp_work = Path.home() / ".nswportios_build"
    temp_work.mkdir(exist_ok=True)
    cmd.extend(["--work-dir", str(temp_work)])
    cmd.extend(["--progress", "lines"])

    print(f"\n{Colors.BLUE}{Colors.BOLD}--- Iniciando Pipeline de Compilación a iOS ---{Colors.END}")
    print(f"• Motor: {Colors.CYAN}nxnative (NSO Rewriter + Horizon HLE + Metal 3){Colors.END}")
    print(f"• Python: {Colors.CYAN}{py_exec}{Colors.END}")
    print(f"• Idioma: {Colors.CYAN}{args.lang}{Colors.END}")
    print(f"• Plataforma: {Colors.CYAN}{args.platform}{Colors.END}")
    print(f"• RomFS: {Colors.CYAN}{args.romfs}{Colors.END}")
    print(f"• FPS en pantalla: {Colors.CYAN}{'Sí' if args.fps else 'No'}{Colors.END}")

    # 6.1 Verificar Metal Toolchain antes de compilar
    metal_check = subprocess.run(
        ["xcrun", "-sdk", "iphoneos", "metal", "--version"],
        capture_output=True, text=True
    )
    if metal_check.returncode != 0:
        print(f"\n{Colors.YELLOW}[AVISO] Metal Toolchain no instalado. Es necesario para compilar shaders de iOS.{Colors.END}")
        print(f"{Colors.CYAN}Instalando Metal Toolchain (puede tardar unos minutos)...{Colors.END}")
        install_res = subprocess.run(
            ["xcodebuild", "-downloadComponent", "MetalToolchain"],
            capture_output=True, text=True
        )
        if install_res.returncode != 0:
            print(f"{Colors.RED}[ERROR] No se pudo instalar el Metal Toolchain.{Colors.END}")
            print(f"{Colors.YELLOW}Instálalo manualmente: xcodebuild -downloadComponent MetalToolchain{Colors.END}")
            return 1
        print(f"{Colors.GREEN}✓ Metal Toolchain instalado correctamente.{Colors.END}")
    else:
        metal_ver = metal_check.stdout.strip().split('\n')[0] if metal_check.stdout else "OK"
        print(f"• Metal: {Colors.CYAN}{metal_ver}{Colors.END}")

    print()  # Línea en blanco antes del pipeline

    try:
        env = os.environ.copy()
        extra_paths = [
            str(Path.home() / ".local" / "bin"),
            str(Path.home() / ".dotnet"),
            "/opt/homebrew/bin",
            "/usr/local/bin"
        ]
        env["PATH"] = ":".join(extra_paths) + ":" + env.get("PATH", "")
        env["DOTNET_ROOT"] = str(Path.home() / ".dotnet")

        proc = subprocess.run(cmd, env=env)
        if proc.returncode != 0:
            print(f"\n{Colors.RED}[ERROR] La compilación falló con código {proc.returncode}.{Colors.END}")
            return proc.returncode

        # 6. Buscar el IPA generado y moverlo a output/
        ipas = list(target_dir.glob("*.ipa")) + list(temp_work.glob("*.ipa")) + list(base_dir.glob("*.ipa"))
        if ipas:
            newest_ipa = max(ipas, key=lambda p: p.stat().st_mtime)
            final_ipa = output_dir / newest_ipa.name
            shutil.move(str(newest_ipa), str(final_ipa))
            ipa_size_mb = final_ipa.stat().st_size / (1024 * 1024)

            print(f"\n{Colors.GREEN}{Colors.BOLD}================================================================{Colors.END}")
            print(f"{Colors.GREEN}{Colors.BOLD}            ¡COMPILACIÓN EXITOSA! .IPA GENERADO                 {Colors.END}")
            print(f"{Colors.GREEN}{Colors.BOLD}================================================================{Colors.END}")
            print(f"📦 Archivo: {Colors.CYAN}{final_ipa.name}{Colors.END}")
            print(f"📊 Tamaño:  {Colors.CYAN}{ipa_size_mb:.2f} MB{Colors.END}")
            print(f"📂 Ubicación: {Colors.CYAN}{final_ipa}{Colors.END}")
            print(f"\n{Colors.YELLOW}{Colors.BOLD}Instrucciones de Instalación en iOS / iPadOS:{Colors.END}")
            print(f"1. Abre tu herramienta de Sideloading favorita (AltStore, SideStore, Sideloadly o TrollStore).")
            print(f"2. Conecta tu iPhone o iPad e instala el archivo .ipa ubicado en la carpeta 'output/'.")
            print(f"3. Si tu herramienta de sideloading tiene la opción 'Increased Memory Limit', actívala.")
            print(f"4. ¡A jugar de forma nativa a 60 FPS con aceleración Metal!\n")
        else:
            print(f"\n{Colors.YELLOW}El proceso terminó pero no se encontró un archivo .ipa generado.{Colors.END}")

    except KeyboardInterrupt:
        print(f"\n{Colors.RED}Compilación interrumpida por el usuario.{Colors.END}")
        return 1
    except Exception as e:
        print(f"\n{Colors.RED}[ERROR INESPERADO]: {e}{Colors.END}")
        return 1

    return 0

if __name__ == "__main__":
    sys.exit(main())
