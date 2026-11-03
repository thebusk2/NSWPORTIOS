#!/usr/bin/env python3
# ==============================================================================
# NSWPORTIOS - Windows Installer
# Nintendo Switch to iOS Porter Toolchain Suite
# Author: thebusk2 (https://github.com/thebusk2)
# ==============================================================================

import ctypes
import os
import shutil
import subprocess
import sys
import tempfile
import urllib.request
import zipfile
from pathlib import Path


# ── Enable ANSI colors on Windows 10+ ─────────────────────────────────────────
def _enable_ansi():
    try:
        if sys.platform == "win32":
            kernel32 = ctypes.windll.kernel32
            kernel32.SetConsoleMode(kernel32.GetStdHandle(-11), 7)
    except Exception:
        pass


_enable_ansi()

CYAN  = "\033[96m"
GREEN = "\033[92m"
YELLOW= "\033[93m"
RED   = "\033[91m"
BOLD  = "\033[1m"
RESET = "\033[0m"

INSTALL_DIR = Path.home() / "NSWPORTIOS"
VENV_DIR    = INSTALL_DIR / "venv"
CORE_DIR    = INSTALL_DIR / "core"
DOTNET_DIR  = Path.home() / ".dotnet"


# ── Helpers ────────────────────────────────────────────────────────────────────
def title(msg):
    print(f"\n{CYAN}{'='*62}{RESET}")
    print(f"{CYAN}  {msg}{RESET}")
    print(f"{CYAN}{'='*62}{RESET}")

def step(n, total, msg):
    print(f"\n{CYAN}[{n}/{total}]{RESET} {BOLD}{msg}{RESET}")

def ok(msg):
    print(f"  {GREEN}OK  {RESET} {msg}")

def warn(msg):
    print(f"  {YELLOW}WARN{RESET} {msg}")

def err(msg):
    print(f"  {RED}FAIL{RESET} {msg}")

def pause(msg="Presiona Enter para continuar..."):
    try:
        input(f"\n{YELLOW}{msg}{RESET}")
    except (EOFError, KeyboardInterrupt):
        pass


# ── Installers ─────────────────────────────────────────────────────────────────
def check_python():
    v = sys.version_info
    if v >= (3, 10):
        ok(f"Python {v.major}.{v.minor}.{v.micro} detectado")
        return True
    err(f"Python {v.major}.{v.minor} detectado — se necesita 3.10+")
    print(f"    Descarga Python desde: https://www.python.org/downloads/")
    return False


def check_git():
    try:
        r = subprocess.run(["git", "--version"], capture_output=True, text=True, timeout=10)
        if r.returncode == 0:
            ok(f"Git detectado: {r.stdout.strip()}")
            return True
    except (FileNotFoundError, subprocess.TimeoutExpired):
        pass

    warn("Git no encontrado. Intentando instalar con winget...")
    try:
        r = subprocess.run(
            ["winget", "install", "--id", "Git.Git", "-e", "--silent"],
            timeout=120
        )
        if r.returncode == 0:
            ok("Git instalado correctamente")
            return True
    except Exception:
        pass

    err("No se pudo instalar Git automaticamente")
    print(f"    Descargalo de: https://git-scm.com/download/win")
    print(f"    Instala Git y vuelve a ejecutar este instalador.")
    return False


def check_dotnet():
    # Check system dotnet
    for candidate in ["dotnet", str(DOTNET_DIR / "dotnet.exe")]:
        try:
            r = subprocess.run([candidate, "--version"], capture_output=True, text=True, timeout=10)
            if r.returncode == 0:
                ok(f".NET SDK detectado: {r.stdout.strip()}")
                return True
        except (FileNotFoundError, subprocess.TimeoutExpired):
            continue

    warn(".NET SDK no encontrado. Descargando instalador...")
    script = Path(tempfile.gettempdir()) / "dotnet-install.ps1"
    try:
        urllib.request.urlretrieve("https://dot.net/v1/dotnet-install.ps1", str(script))
        subprocess.run([
            "powershell", "-ExecutionPolicy", "Bypass", "-File", str(script),
            "-InstallDir", str(DOTNET_DIR), "-Channel", "LTS"
        ], timeout=300, check=False)
        dotnet_exe = DOTNET_DIR / "dotnet.exe"
        if dotnet_exe.exists():
            ok(f".NET SDK instalado en {DOTNET_DIR}")
            os.environ["PATH"] = str(DOTNET_DIR) + os.pathsep + os.environ.get("PATH", "")
            os.environ["DOTNET_ROOT"] = str(DOTNET_DIR)
            return True
    except Exception as e:
        pass

    err("No se pudo instalar .NET SDK automaticamente")
    print(f"    Descargalo de: https://dotnet.microsoft.com/download")
    return False


def create_directories():
    for d in ["input", "keys", "output", "temp_build"]:
        (INSTALL_DIR / d).mkdir(parents=True, exist_ok=True)
    ok(f"Carpetas creadas en {INSTALL_DIR}")


def copy_project_files():
    # When running as PyInstaller bundle, files are in sys._MEIPASS
    if getattr(sys, "frozen", False):
        base = Path(sys._MEIPASS)
    else:
        base = Path(__file__).parent

    copied = 0
    for fname in ["switch2ipa.py", "switch2ipa_gui.py", "README.md", "LICENSE"]:
        src = base / fname
        dst = INSTALL_DIR / fname
        if src.exists():
            shutil.copy2(str(src), str(dst))
            copied += 1

    if copied > 0:
        ok(f"{copied} archivo(s) del proyecto copiado(s)")
    else:
        warn("No se encontraron archivos del proyecto para copiar (normal en algunas builds)")


def create_venv():
    python_exe = VENV_DIR / "Scripts" / "python.exe"
    pip_exe    = VENV_DIR / "Scripts" / "pip.exe"

    if not python_exe.exists():
        print("  Creando entorno virtual Python...")
        r = subprocess.run([sys.executable, "-m", "venv", str(VENV_DIR)], timeout=120)
        if r.returncode != 0:
            err("No se pudo crear el entorno virtual")
            return None

    print("  Instalando dependencias Python...")
    deps = ["lz4", "capstone>=5,<6", "fonttools", "nsz", "pycryptodome",
            "zstandard", "backports.zstd"]
    subprocess.run([str(pip_exe), "install", "--upgrade", "pip", "-q"], timeout=120)
    r = subprocess.run([str(pip_exe), "install"] + deps + ["-q"], timeout=300)

    if r.returncode == 0:
        ok("Dependencias Python instaladas")
        return python_exe
    else:
        err("Error instalando dependencias")
        return None


def clone_core():
    if CORE_DIR.exists() and (CORE_DIR / "scripts").exists():
        ok("Motor core ya presente")
        return True

    print("  Clonando motor nxnative (puede tardar 1-2 minutos)...")
    if CORE_DIR.exists():
        shutil.rmtree(str(CORE_DIR))

    try:
        r = subprocess.run([
            "git", "clone", "--depth", "1",
            "https://github.com/seedds/nxnative.git",
            str(CORE_DIR)
        ], timeout=300)
        if r.returncode == 0:
            ok("Motor core descargado")
            return True
    except Exception:
        pass

    err("No se pudo clonar el motor core")
    print(f"    Clona manualmente: git clone https://github.com/seedds/nxnative.git \"{CORE_DIR}\"")
    return False


def create_launcher(python_exe):
    # .bat launcher
    bat = INSTALL_DIR / "NSWPORTIOS.bat"
    bat.write_text(
        f'@echo off\ncd /d "{INSTALL_DIR}"\n'
        f'"{python_exe}" switch2ipa_gui.py\npause\n',
        encoding="utf-8"
    )
    # Desktop shortcut
    desktop = Path.home() / "Desktop"
    if desktop.exists():
        shutil.copy2(str(bat), str(desktop / "NSWPORTIOS.bat"))
        ok("Acceso directo creado en el Escritorio")
    ok(f"Lanzador: {bat}")


def create_uninstaller():
    u = INSTALL_DIR / "Desinstalar.bat"
    u.write_text(
        f'@echo off\necho Desinstalando NSWPORTIOS...\n'
        f'cd /d "%USERPROFILE%"\n'
        f'rmdir /s /q "{INSTALL_DIR}"\n'
        f'del "%USERPROFILE%\\Desktop\\NSWPORTIOS.bat" 2>nul\n'
        f'echo Desinstalado.\npause\n',
        encoding="utf-8"
    )
    ok("Desinstalador creado")


# ── Main ───────────────────────────────────────────────────────────────────────
def main():
    title("NSWPORTIOS v1.0.0 — Instalador para Windows")
    print(f"""
  Nintendo Switch → iOS Porter Toolchain Suite
  Autor: thebusk2 | https://github.com/thebusk2
  Instalando en: {INSTALL_DIR}
""")

    errors = []
    total = 7

    step(1, total, "Verificando Python 3.10+...")
    if not check_python():
        err("Se requiere Python 3.10+. Instalalo y vuelve a ejecutar.")
        pause("Presiona Enter para salir...")
        sys.exit(1)

    step(2, total, "Verificando Git...")
    if not check_git():
        errors.append("Git (opcional pero recomendado)")

    step(3, total, "Verificando .NET SDK...")
    if not check_dotnet():
        errors.append(".NET SDK (opcional, necesario solo en macOS)")

    step(4, total, "Creando estructura de carpetas...")
    INSTALL_DIR.mkdir(parents=True, exist_ok=True)
    create_directories()
    copy_project_files()

    step(5, total, "Configurando entorno Python y dependencias...")
    python_exe = create_venv()
    if python_exe is None:
        errors.append("Entorno Python virtual")

    step(6, total, "Descargando motor nxnative...")
    if not clone_core():
        errors.append("Motor nxnative core (necesario para compilar)")

    step(7, total, "Creando accesos directos...")
    if python_exe:
        create_launcher(python_exe)
    create_uninstaller()

    # Summary
    print(f"\n{CYAN}{'='*62}{RESET}")
    if not errors:
        print(f"""
{GREEN}{BOLD}  INSTALACION COMPLETADA{RESET}

  Carpeta: {INSTALL_DIR}

  PROXIMOS PASOS:
    1. Coloca tu prod.keys en:  {INSTALL_DIR / 'keys'}
    2. Coloca tus juegos en:    {INSTALL_DIR / 'input'}
    3. Ejecuta NSWPORTIOS.bat desde el Escritorio
""")
    else:
        print(f"""
{YELLOW}{BOLD}  INSTALACION PARCIAL{RESET}
  Componentes con advertencias:
""")
        for e in errors:
            print(f"    {RED}*{RESET} {e}")
        print(f"""
  La herramienta esta en: {INSTALL_DIR}
  Instala los componentes faltantes y vuelve a ejecutar.
""")

    print(f"{CYAN}{'='*62}{RESET}")
    pause("Presiona Enter para cerrar...")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print(f"\n{YELLOW}Instalacion cancelada por el usuario.{RESET}")
        pause("Presiona Enter para cerrar...")
    except Exception as exc:
        print(f"\n{RED}ERROR INESPERADO: {exc}{RESET}")
        import traceback
        traceback.print_exc()
        pause("Ocurrio un error. Presiona Enter para cerrar...")
        sys.exit(1)
