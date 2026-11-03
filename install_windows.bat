@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul 2>&1
title NSWPORTIOS v1.0.0 - Instalador para Windows

:: ============================================================
::  NSWPORTIOS - Instalador para Windows
::  Nintendo Switch to iOS Porter Toolchain Suite
::  Autor: thebusk2 (https://github.com/thebusk2)
:: ============================================================

color 0B
echo.
echo  ╔══════════════════════════════════════════════════════╗
echo  ║   NSWPORTIOS v1.0.0 - Instalador para Windows       ║
echo  ║   Nintendo Switch ^-^> iOS Porter Toolchain Suite     ║
echo  ║   Autor: thebusk2 ^| github.com/thebusk2             ║
echo  ╚══════════════════════════════════════════════════════╝
echo.

set "INSTALL_DIR=%USERPROFILE%\NSWPORTIOS"
set "VENV_DIR=%INSTALL_DIR%\venv"
set "CORE_DIR=%INSTALL_DIR%\core"
set "DOTNET_DIR=%USERPROFILE%\.dotnet"
set "ERRORS=0"

echo  Instalando en: %INSTALL_DIR%
echo.

:: ── [1/6] Verificar Python ────────────────────────────────────────────────────
echo [1/6] Verificando Python 3.10+...
python --version >nul 2>&1
if %errorlevel% NEQ 0 (
    echo  [ERROR] Python no encontrado.
    echo.
    echo  Descarga e instala Python 3.10 o superior desde:
    echo  https://www.python.org/downloads/
    echo.
    echo  IMPORTANTE: Marca la casilla "Add Python to PATH"
    echo  durante la instalacion, luego vuelve a ejecutar este script.
    echo.
    pause
    exit /b 1
)
for /f "tokens=*" %%v in ('python --version 2^>^&1') do set PYVER=%%v
echo  OK - !PYVER! detectado
echo.

:: ── [2/6] Verificar Git ───────────────────────────────────────────────────────
echo [2/6] Verificando Git...
git --version >nul 2>&1
if %errorlevel% NEQ 0 (
    echo  ADVERTENCIA: Git no encontrado.
    echo  Intentando instalar con winget...
    winget install --id Git.Git -e --silent 2>nul
    git --version >nul 2>&1
    if !errorlevel! NEQ 0 (
        echo  ADVERTENCIA: No se pudo instalar Git automaticamente.
        echo  Descargalo de: https://git-scm.com/download/win
        echo  El motor core no podra descargarse sin Git.
        set "ERRORS=1"
    ) else (
        echo  OK - Git instalado
        :: Refresh PATH for git
        set "PATH=%PATH%;C:\Program Files\Git\cmd"
    )
) else (
    for /f "tokens=*" %%v in ('git --version 2^>^&1') do echo  OK - %%v
)
echo.

:: ── [3/6] Crear carpetas ──────────────────────────────────────────────────────
echo [3/6] Creando estructura de carpetas...
if not exist "%INSTALL_DIR%"       mkdir "%INSTALL_DIR%"
if not exist "%INSTALL_DIR%\input"      mkdir "%INSTALL_DIR%\input"
if not exist "%INSTALL_DIR%\keys"       mkdir "%INSTALL_DIR%\keys"
if not exist "%INSTALL_DIR%\output"     mkdir "%INSTALL_DIR%\output"
if not exist "%INSTALL_DIR%\temp_build" mkdir "%INSTALL_DIR%\temp_build"
echo  OK - Carpetas creadas en %INSTALL_DIR%
echo.

:: ── [4/6] Copiar archivos del proyecto ────────────────────────────────────────
echo [4/6] Copiando archivos del proyecto...
set "SCRIPT_DIR=%~dp0"
:: Remove trailing backslash
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

set "COPIED=0"
for %%f in (switch2ipa.py switch2ipa_gui.py README.md LICENSE installer_windows.py) do (
    if exist "%SCRIPT_DIR%\%%f" (
        copy /y "%SCRIPT_DIR%\%%f" "%INSTALL_DIR%\%%f" >nul 2>&1
        set /a COPIED+=1
    )
)
if !COPIED! GTR 0 (
    echo  OK - !COPIED! archivo(s) copiado(s)
) else (
    echo  ADVERTENCIA: No se encontraron archivos del proyecto junto al instalador.
    echo  Descargalos desde: https://github.com/thebusk2/NSWPORTIOS
    set "ERRORS=1"
)
echo.

:: ── [5/6] Instalar dependencias Python ───────────────────────────────────────
echo [5/6] Configurando entorno Python y dependencias...

:: Create venv
if not exist "%VENV_DIR%\Scripts\python.exe" (
    echo  Creando entorno virtual...
    python -m venv "%VENV_DIR%"
    if !errorlevel! NEQ 0 (
        echo  ERROR: No se pudo crear el entorno virtual
        set "ERRORS=1"
        goto :skip_deps
    )
)

:: Install dependencies
echo  Instalando dependencias (lz4, nsz, pycryptodome, etc.)...
"%VENV_DIR%\Scripts\pip.exe" install --upgrade pip -q
"%VENV_DIR%\Scripts\pip.exe" install lz4 "capstone>=5,<6" fonttools nsz pycryptodome zstandard backports.zstd -q

if !errorlevel! NEQ 0 (
    echo  ADVERTENCIA: Algunas dependencias no se instalaron correctamente.
    set "ERRORS=1"
) else (
    echo  OK - Dependencias instaladas
)

:skip_deps
echo.

:: ── [6/6] Descargar motor nxnative ───────────────────────────────────────────
echo [6/6] Descargando motor nxnative...

if exist "%CORE_DIR%\scripts" (
    echo  OK - Motor core ya presente
) else (
    git --version >nul 2>&1
    if !errorlevel! NEQ 0 (
        echo  OMITIDO: Git no disponible para descargar el motor core.
        echo  Clona manualmente: git clone https://github.com/seedds/nxnative.git "%CORE_DIR%"
        set "ERRORS=1"
    ) else (
        echo  Clonando motor nxnative (puede tardar 1-3 minutos)...
        git clone --depth 1 https://github.com/seedds/nxnative.git "%CORE_DIR%"
        if !errorlevel! NEQ 0 (
            echo  ERROR: No se pudo descargar el motor core.
            set "ERRORS=1"
        ) else (
            echo  OK - Motor core descargado
        )
    )
)
echo.

:: ── Crear lanzador en el Escritorio ──────────────────────────────────────────
set "LAUNCHER=%INSTALL_DIR%\NSWPORTIOS.bat"
(
    echo @echo off
    echo title NSWPORTIOS
    echo color 0B
    echo cd /d "%INSTALL_DIR%"
    echo "%VENV_DIR%\Scripts\python.exe" switch2ipa_gui.py
    echo pause
) > "%LAUNCHER%"

if exist "%USERPROFILE%\Desktop" (
    copy /y "%LAUNCHER%" "%USERPROFILE%\Desktop\NSWPORTIOS.bat" >nul 2>&1
)
if exist "%PUBLIC%\Desktop" (
    copy /y "%LAUNCHER%" "%PUBLIC%\Desktop\NSWPORTIOS.bat" >nul 2>&1
)

:: Crear desinstalador
(
    echo @echo off
    echo echo Desinstalando NSWPORTIOS...
    echo set /p confirm="^¿Confirmas? (S/N): "
    echo if /I "%%confirm%%"=="S" (
    echo   rmdir /s /q "%INSTALL_DIR%"
    echo   del "%%USERPROFILE%%\Desktop\NSWPORTIOS.bat" 2^>nul
    echo   echo Desinstalado correctamente.
    echo ^) else ^( echo Cancelado. ^)
    echo pause
) > "%INSTALL_DIR%\Desinstalar.bat"

:: ── Resumen final ─────────────────────────────────────────────────────────────
echo.
echo  ╔══════════════════════════════════════════════════════╗
if !ERRORS!==0 (
    echo  ║         INSTALACION COMPLETADA CON EXITO             ║
) else (
    echo  ║       INSTALACION PARCIAL - Revisa advertencias       ║
)
echo  ╚══════════════════════════════════════════════════════╝
echo.
echo  Carpeta de instalacion:
echo    %INSTALL_DIR%
echo.
echo  PROXIMOS PASOS:
echo    1. Copia tu prod.keys a:  %INSTALL_DIR%\keys\
echo    2. Copia tus juegos a:    %INSTALL_DIR%\input\
echo    3. Ejecuta NSWPORTIOS.bat desde el Escritorio
echo.
echo  Redes sociales del autor:
echo    GitHub:    https://github.com/thebusk2
echo    Instagram: https://instagram.com/thebusk2
echo    X:         https://x.com/thebusk2
echo.
pause
