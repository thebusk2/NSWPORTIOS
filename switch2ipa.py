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
        Path.home() / ".switch" / "prod.keys",
        Path.home() / ".config" / "yuzu" / "keys" / "prod.keys",
        Path.home() / ".config" / "Ryujinx" / "system" / "prod.keys",
        Path.home() / "Library" / "Application Support" / "Ryujinx" / "system" / "prod.keys",
    ]

    # También buscar cualquier archivo .keys dentro de keys/
    keys_dir = base_dir / "keys"
    if keys_dir.exists():
        for kf in keys_dir.glob("*.keys"):
            if kf.is_file() and kf not in candidates:
                candidates.insert(0, kf)

    for cand in candidates:
        if cand.is_file() and cand.stat().st_size > 0:
            return cand.resolve()

    return None

def scan_games(input_dir):
    """Escanea el directorio input en busca de archivos de Switch válidos."""
    supported_exts = {'.nsp', '.xci', '.nsz', '.xcz'}
    files = []
    for ext in supported_exts:
        files.extend(list(input_dir.glob(f"*{ext}")))
        files.extend(list(input_dir.glob(f"*{ext.upper()}")))

    # Filtrar archivos ocultos o de macOS AppleDouble (._*)
    valid_files = [f for f in files if not f.name.startswith('._') and f.stat().st_size > 0]
    return sorted(valid_files, key=lambda x: x.name.lower())

def group_games_by_title(files):
    """Agrupa juegos por título o title ID si hay base, updates y DLCs."""
    games = {}
    for f in files:
        # Extraer title ID si existe en formato [0100XXXXXXXXXXXX]
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
            # Agrupar por nombre aproximado antes de corchetes
            clean_name = re.sub(r'\[.*?\]|\(.*?\)', '', f.stem).strip().lower()
            key = clean_name or f.stem

        if key not in games:
            games[key] = []
        games[key].append(f)
    return games

def ensure_python_environment(base_dir):
    """Comprueba si el venv con las herramientas está disponible, de lo contrario usa el Python actual."""
    venv_py = base_dir / "tools" / "venv" / "bin" / "python3"
    if venv_py.exists():
        return str(venv_py)
    return sys.executable

def check_system_dependencies():
    """Valida herramientas de compilación esenciales."""
    errors = []
    if not shutil.which("xcodebuild"):
        errors.append("xcodebuild (Instala Xcode desde la App Store o selecciona la ruta con xcode-select)")
    return errors

def main():
    print_banner()

    base_dir = Path(__file__).resolve().parent
    core_dir = base_dir / "core"
    build_script = core_dir / "scripts" / "build_ipa_from_nsp.py"
    input_dir = base_dir / "input"
    keys_dir = base_dir / "keys"
    output_dir = base_dir / "output"

    # Crear directorios base si no existen
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
    parser.add_argument("--setup", action="store_true", help="Ejecuta la comprobación e instalación de dependencias del sistema")

    args = parser.parse_args()

    # Si se pide setup
    if args.setup:
        setup_script = base_dir / "setup.sh"
        if setup_script.exists():
            subprocess.run(["bash", str(setup_script)])
            return 0
        else:
            print(f"{Colors.RED}[ERROR] No se encontró setup.sh en {base_dir}{Colors.END}")
            return 1

    # Validar dependencias del sistema
    sys_errors = check_system_dependencies()
    if sys_errors:
        print(f"{Colors.RED}[!] Faltan herramientas esenciales del sistema:{Colors.END}")
        for err in sys_errors:
            print(f"  • {err}")
        print(f"\n{Colors.YELLOW}Ejecuta './setup.sh' para configurar el entorno automáticamente.{Colors.END}\n")
        return 1

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
    if args.input:
        in_path = Path(args.input).resolve()
        if in_path.is_file():
            # Crear una carpeta temporal o apuntar a la carpeta del archivo
            target_dir = in_path.parent
        elif in_path.is_dir():
            target_dir = in_path
        else:
            print(f"{Colors.RED}[ERROR] La ruta especificada en --input no existe: {args.input}{Colors.END}")
            return 1
    else:
        # Escaneo en input/
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
            # Solo un juego detectado
            selected_key = list(grouped.keys())[0]
            game_files = grouped[selected_key]
            print(f"{Colors.GREEN}✓ Juego detectado:{Colors.END}")
            for gf in game_files:
                size_mb = gf.stat().st_size / (1024 * 1024)
                print(f"   • {gf.name} ({size_mb:.1f} MB)")
            target_dir = input_dir
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
                    # Si están todos en input_dir, pasamos el title id del seleccionado
                    target_dir = input_dir
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

    if args.fps:
        cmd.append("--show-fps")
    else:
        cmd.append("--no-show-fps")

    # Carpeta temporal de trabajo
    temp_work = base_dir / "temp_build"
    temp_work.mkdir(exist_ok=True)
    cmd.extend(["--work-dir", str(temp_work)])

    print(f"\n{Colors.BLUE}{Colors.BOLD}--- Iniciando Pipeline de Compilación a iOS ---{Colors.END}")
    print(f"• Motor: {Colors.CYAN}nxnative (NSO Rewriter + Horizon HLE + Metal 3){Colors.END}")
    print(f"• Idioma: {Colors.CYAN}{args.lang}{Colors.END}")
    print(f"• Plataforma: {Colors.CYAN}{args.platform}{Colors.END}")
    print(f"• RomFS: {Colors.CYAN}{args.romfs}{Colors.END}")
    print(f"• FPS en pantalla: {Colors.CYAN}{'Sí' if args.fps else 'No'}{Colors.END}\n")

    try:
        env = os.environ.copy()
        # Añadir dotnet y brew al PATH si existen
        extra_paths = ["/opt/homebrew/bin", "/usr/local/bin", str(Path.home() / ".dotnet")]
        env["PATH"] = ":".join(extra_paths) + ":" + env.get("PATH", "")

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
            print(f"\n{Colors.YELLOW}El proceso terminó pero no se encontró un archivo .ipa generado en las rutas habituales.{Colors.END}")

    except KeyboardInterrupt:
        print(f"\n{Colors.RED}Compilación interrumpida por el usuario.{Colors.END}")
        return 1
    except Exception as e:
        print(f"\n{Colors.RED}[ERROR INESPERADO]: {e}{Colors.END}")
        return 1

    return 0

if __name__ == "__main__":
    sys.exit(main())
