#!/usr/bin/env python3
# ==============================================================================
# NSWPORTIOS - Windows Installer
# Nintendo Switch to iOS Porter Toolchain Suite
# Author: thebusk2 (https://github.com/thebusk2)
# ==============================================================================
"""
Self-contained Windows installer for NSWPORTIOS.
Compiled to .exe via PyInstaller in GitHub Actions.
"""

import ctypes
import os
import platform
import shutil
import subprocess
import sys
import tempfile
import time
import urllib.request
import zipfile
from pathlib import Path

# ── Colors for Windows console ────────────────────────────────────────────────
CYAN = "\033[96m"
GREEN = "\033[92m"
YELLOW = "\033[93m"
RED = "\033[91m"
BOLD = "\033[1m"
RESET = "\033[0m"

BANNER = f"""
{CYAN}╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║     {RED}█▀█{CYAN}  {BOLD}NSWPORTIOS{RESET}{CYAN}  {RED}█▀█{CYAN}                                      ║
║     {RED}█▄█{CYAN}  Nintendo Switch → iOS Porter  {RED}█▄█{CYAN}                       ║
║                                                              ║
║     Instalador para Windows                                  ║
║     Autor: thebusk2                                          ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝{RESET}
"""

INSTALL_DIR = Path.home() / "NSWPORTIOS"
VENV_DIR = INSTALL_DIR / "venv"
CORE_DIR = INSTALL_DIR / "core"
DOTNET_DIR = Path.home() / ".dotnet"


def enable_ansi():
    """Enable ANSI escape sequences on Windows 10+."""
    if sys.platform == "win32":
        kernel32 = ctypes.windll.kernel32
        kernel32.SetConsoleMode(kernel32.GetStdHandle(-11), 7)


def print_step(step: int, total: int, msg: str):
    print(f"\n{CYAN}[{step}/{total}]{RESET} {BOLD}{msg}{RESET}")


def print_ok(msg: str):
    print(f"  {GREEN}✓ {msg}{RESET}")


def print_warn(msg: str):
    print(f"  {YELLOW}⚠ {msg}{RESET}")


def print_err(msg: str):
    print(f"  {RED}✗ {msg}{RESET}")


def download(url: str, dest: Path, label: str = ""):
    """Download a file with progress indication."""
    label = label or dest.name
    print(f"  Descargando {label}...")
    try:
        urllib.request.urlretrieve(url, str(dest))
        print_ok(f"{label} descargado ({dest.stat().st_size // (1024*1024)} MB)")
    except Exception as e:
        print_err(f"Error descargando {label}: {e}")
        raise


def run(cmd, check=True, shell=False, **kw):
    """Run a command and return the result."""
    result = subprocess.run(
        cmd, capture_output=True, text=True, shell=shell, **kw
    )
    if check and result.returncode != 0:
        print_err(f"Comando fallido: {' '.join(cmd) if isinstance(cmd, list) else cmd}")
        if result.stderr:
            print(f"    {result.stderr.strip()[:200]}")
    return result


def check_python() -> bool:
    """Check if Python 3.10+ is available."""
    ver = sys.version_info
    if ver >= (3, 10):
        print_ok(f"Python {ver.major}.{ver.minor}.{ver.micro} detectado")
        return True
    print_err(f"Python {ver.major}.{ver.minor} detectado — se necesita 3.10+")
    return False


def install_git() -> bool:
    """Check if git is available, offer to install."""
    r = run(["git", "--version"], check=False)
    if r.returncode == 0:
        print_ok(f"Git detectado: {r.stdout.strip()}")
        return True
    
    print_warn("Git no encontrado. Intentando instalar con winget...")
    r = run(["winget", "install", "--id", "Git.Git", "-e", "--silent"], check=False)
    if r.returncode == 0:
        print_ok("Git instalado. Puede necesitar reiniciar la terminal.")
        return True
    
    print_err("No se pudo instalar Git automáticamente.")
    print(f"    {YELLOW}Descárgalo de: https://git-scm.com/download/win{RESET}")
    return False


def install_dotnet() -> bool:
    """Install .NET SDK if not present."""
    # Check existing
    for dotnet_path in [shutil.which("dotnet"), str(DOTNET_DIR / "dotnet.exe")]:
        if dotnet_path and Path(dotnet_path).exists():
            r = run([dotnet_path, "--version"], check=False)
            if r.returncode == 0:
                print_ok(f".NET SDK detectado: {r.stdout.strip()}")
                return True
    
    print_warn(".NET SDK no encontrado. Instalando...")
    script_url = "https://dot.net/v1/dotnet-install.ps1"
    script_path = Path(tempfile.gettempdir()) / "dotnet-install.ps1"
    download(script_url, script_path, ".NET install script")
    
    r = run([
        "powershell", "-ExecutionPolicy", "Bypass", "-File", str(script_path),
        "-InstallDir", str(DOTNET_DIR), "-Channel", "LTS"
    ], check=False)
    
    if (DOTNET_DIR / "dotnet.exe").exists():
        print_ok(f".NET SDK instalado en {DOTNET_DIR}")
        os.environ["PATH"] = str(DOTNET_DIR) + ";" + os.environ.get("PATH", "")
        os.environ["DOTNET_ROOT"] = str(DOTNET_DIR)
        return True
    
    print_err("No se pudo instalar .NET SDK")
    return False


def create_venv() -> Path:
    """Create Python venv and install dependencies."""
    python_exe = VENV_DIR / "Scripts" / "python.exe"
    
    if not python_exe.exists():
        print(f"  Creando entorno virtual en {VENV_DIR}...")
        run([sys.executable, "-m", "venv", str(VENV_DIR)])
    
    pip_exe = str(VENV_DIR / "Scripts" / "pip.exe")
    
    print("  Instalando dependencias Python...")
    deps = [
        "lz4", "capstone>=5,<6", "fonttools", "nsz", "pycryptodome",
        "zstandard", "backports.zstd"
    ]
    run([pip_exe, "install", "--upgrade", "pip", "-q"])
    run([pip_exe, "install"] + deps + ["-q"])
    
    print_ok("Dependencias Python instaladas")
    return python_exe


def clone_core():
    """Clone the nxnative core engine."""
    if CORE_DIR.exists() and (CORE_DIR / "scripts").exists():
        print_ok("Motor core ya está presente")
        return
    
    print("  Clonando motor nxnative...")
    if CORE_DIR.exists():
        shutil.rmtree(CORE_DIR)
    
    r = run(["git", "clone", "--depth", "1",
             "https://github.com/seedds/nxnative.git", str(CORE_DIR)], check=False)
    
    if r.returncode == 0:
        print_ok("Motor core clonado correctamente")
    else:
        print_err("Error clonando el motor core")
        print(f"    {YELLOW}Clona manualmente: git clone https://github.com/seedds/nxnative.git \"{CORE_DIR}\"{RESET}")


def create_directories():
    """Create working directories."""
    for d in ["input", "keys", "output", "temp_build"]:
        (INSTALL_DIR / d).mkdir(parents=True, exist_ok=True)
    print_ok("Directorios creados: input/, keys/, output/")


def copy_project_files():
    """Copy project files to the install directory."""
    # If running from within the project, copy files
    src = Path(__file__).parent if not getattr(sys, 'frozen', False) else Path(sys._MEIPASS)
    
    files_to_copy = [
        "switch2ipa.py", "switch2ipa_gui.py", "README.md", "LICENSE"
    ]
    
    for f in files_to_copy:
        src_file = src / f
        if src_file.exists():
            dest_file = INSTALL_DIR / f
            if not dest_file.exists() or src_file.stat().st_mtime > dest_file.stat().st_mtime:
                shutil.copy2(src_file, dest_file)
    
    print_ok("Archivos del proyecto copiados")


def create_shortcuts():
    """Create desktop shortcut and Start Menu entry."""
    desktop = Path.home() / "Desktop"
    
    # Create a .bat launcher
    launcher = INSTALL_DIR / "NSWPORTIOS.bat"
    launcher.write_text(f"""@echo off
TITLE NSWPORTIOS
COLOR 0B
cd /d "{INSTALL_DIR}"
"{VENV_DIR / 'Scripts' / 'python.exe'}" switch2ipa_gui.py
""", encoding="utf-8")
    
    # Copy to desktop
    if desktop.exists():
        shutil.copy2(launcher, desktop / "NSWPORTIOS.bat")
        print_ok("Acceso directo creado en el Escritorio")
    
    print_ok(f"Lanzador creado: {launcher}")


def create_uninstaller():
    """Create an uninstaller script."""
    uninstaller = INSTALL_DIR / "Desinstalar_NSWPORTIOS.bat"
    uninstaller.write_text(f"""@echo off
TITLE Desinstalar NSWPORTIOS
echo.
echo ¿Seguro que deseas desinstalar NSWPORTIOS?
echo Se eliminará la carpeta: {INSTALL_DIR}
echo.
set /p confirm="Escribe SI para confirmar: "
if /I "%confirm%"=="SI" (
    cd /d "%USERPROFILE%"
    rmdir /s /q "{INSTALL_DIR}"
    del "%USERPROFILE%\\Desktop\\NSWPORTIOS.bat" 2>nul
    echo NSWPORTIOS desinstalado correctamente.
) else (
    echo Desinstalación cancelada.
)
pause
""", encoding="utf-8")
    print_ok("Desinstalador creado")


def main():
    enable_ansi()
    print(BANNER)
    
    total_steps = 7
    errors = []
    
    # Step 1: Check Python
    print_step(1, total_steps, "Verificando Python...")
    if not check_python():
        print_err("Se necesita Python 3.10 o superior.")
        print(f"    {YELLOW}Descárgalo de: https://www.python.org/downloads/{RESET}")
        input("\nPresiona Enter para salir...")
        sys.exit(1)
    
    # Step 2: Check/Install Git
    print_step(2, total_steps, "Verificando Git...")
    if not install_git():
        errors.append("Git")
    
    # Step 3: Install .NET SDK
    print_step(3, total_steps, "Verificando .NET SDK...")
    if not install_dotnet():
        errors.append(".NET SDK")
    
    # Step 4: Create install directory and copy files
    print_step(4, total_steps, "Creando estructura de carpetas...")
    INSTALL_DIR.mkdir(parents=True, exist_ok=True)
    create_directories()
    copy_project_files()
    
    # Step 5: Python venv and dependencies
    print_step(5, total_steps, "Configurando entorno Python y dependencias...")
    try:
        python_exe = create_venv()
    except Exception as e:
        print_err(f"Error creando entorno virtual: {e}")
        errors.append("Python venv")
    
    # Step 6: Clone core engine
    print_step(6, total_steps, "Descargando motor nxnative...")
    try:
        clone_core()
    except Exception as e:
        print_err(f"Error: {e}")
        errors.append("nxnative core")
    
    # Step 7: Create shortcuts
    print_step(7, total_steps, "Creando accesos directos...")
    create_shortcuts()
    create_uninstaller()
    
    # Summary
    print(f"\n{CYAN}{'═' * 62}{RESET}")
    if not errors:
        print(f"""
{GREEN}{BOLD}  ¡Instalación completada con éxito!{RESET}

  {BOLD}Ubicación:{RESET}      {INSTALL_DIR}
  {BOLD}Lanzador:{RESET}       {INSTALL_DIR / 'NSWPORTIOS.bat'}
  
  {BOLD}Próximos pasos:{RESET}
    1. Coloca tu archivo {YELLOW}prod.keys{RESET} en: {INSTALL_DIR / 'keys'}
    2. Coloca tus juegos (.nsp/.xci/.nsz/.xcz) en: {INSTALL_DIR / 'input'}
    3. Ejecuta {CYAN}NSWPORTIOS.bat{RESET} desde el Escritorio o la carpeta
""")
    else:
        print(f"""
{YELLOW}{BOLD}  Instalación parcial — algunos componentes fallaron:{RESET}
  {RED}{'  '.join(errors)}{RESET}
  
  La herramienta está instalada en: {INSTALL_DIR}
  Revisa los errores arriba e instala los componentes faltantes manualmente.
""")
    print(f"{CYAN}{'═' * 62}{RESET}")
    
    input("\nPresiona Enter para salir...")


if __name__ == "__main__":
    main()
