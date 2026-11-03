@echo off
setlocal enabledelayedexpansion
title NSWPORTIOS v1.0.0 - Instalador Windows

set "INSTALL_DIR=%USERPROFILE%\NSWPORTIOS"
set "VENV_DIR=%INSTALL_DIR%\venv"
set "CORE_DIR=%INSTALL_DIR%\core"
set "ERRORS=0"

echo.
echo ================================================================
echo    NSWPORTIOS v1.0.0 - Instalador para Windows
echo    Nintendo Switch to iOS Porter - by thebusk2
echo    github.com/thebusk2
echo ================================================================
echo.
echo Instalando en: %INSTALL_DIR%
echo.

:: - [1/6] Python -
echo [1/6] Verificando Python 3.10+...
python --version >nul 2>&1
if %errorlevel% NEQ 0 (
    echo.
    echo  ERROR: Python no encontrado en el sistema.
    echo.
    echo  Pasos para instalar Python:
    echo    1. Ve a: https://www.python.org/downloads/
    echo    2. Descarga Python 3.12 o superior
    echo    3. IMPORTANTE: marca "Add Python to PATH"
    echo    4. Finaliza la instalacion
    echo    5. Vuelve a ejecutar este script
    echo.
    pause
    exit /b 1
)
python --version
echo  OK - Python encontrado.
echo.

:: - [2/6] Git -
echo [2/6] Verificando Git...
git --version >nul 2>&1
if %errorlevel% NEQ 0 (
    echo  Git no encontrado. Intentando instalar...
    winget install --id Git.Git -e --silent --accept-package-agreements --accept-source-agreements >nul 2>&1
    :: Refresh PATH
    set "PATH=%PATH%;C:\Program Files\Git\cmd;C:\Program Files\Git\bin"
    git --version >nul 2>&1
    if !errorlevel! NEQ 0 (
        echo  AVISO: Git no disponible. Instala desde https://git-scm.com
        set "ERRORS=1"
    ) else (
        echo  OK - Git instalado correctamente.
    )
) else (
    git --version
    echo  OK - Git encontrado.
)
echo.

:: - [3/6] Carpetas -
echo [3/6] Creando carpetas de trabajo...
if not exist "%INSTALL_DIR%"            mkdir "%INSTALL_DIR%"
if not exist "%INSTALL_DIR%\input"      mkdir "%INSTALL_DIR%\input"
if not exist "%INSTALL_DIR%\keys"       mkdir "%INSTALL_DIR%\keys"
if not exist "%INSTALL_DIR%\output"     mkdir "%INSTALL_DIR%\output"
if not exist "%INSTALL_DIR%\temp_build" mkdir "%INSTALL_DIR%\temp_build"
echo  OK - Carpetas creadas en %INSTALL_DIR%
echo.

:: - [4/6] Copiar archivos -
echo [4/6] Copiando archivos del proyecto...
set "SRC=%~dp0"
if "%SRC:~-1%"=="\" set "SRC=%SRC:~0,-1%"

set "COPIED=0"
for %%F in (switch2ipa.py switch2ipa_gui.py README.md LICENSE) do (
    if exist "%SRC%\%%F" (
        copy /y "%SRC%\%%F" "%INSTALL_DIR%\%%F" >nul 2>&1
        set /a COPIED+=1
        echo  Copiado: %%F
    )
)
if !COPIED! EQU 0 (
    echo  AVISO: Archivos no encontrados junto al instalador.
    echo  Asegurate de extraer TODOS los archivos del ZIP antes de ejecutar.
    set "ERRORS=1"
) else (
    echo  OK - !COPIED! archivos copiados.
)
echo.

:: - [5/6] Entorno Python y dependencias -
echo [5/6] Configurando entorno Python y dependencias...

if not exist "%VENV_DIR%\Scripts\python.exe" (
    echo  Creando entorno virtual Python...
    python -m venv "%VENV_DIR%"
    if !errorlevel! NEQ 0 (
        echo  ERROR: No se pudo crear el entorno virtual.
        set "ERRORS=1"
        goto :skip_pip
    )
    echo  OK - Entorno virtual creado.
) else (
    echo  OK - Entorno virtual ya existe.
)

echo  Instalando dependencias (puede tardar 1-2 minutos)...
"%VENV_DIR%\Scripts\pip.exe" install --upgrade pip -q 2>nul
"%VENV_DIR%\Scripts\pip.exe" install lz4 "capstone>=5,<6" fonttools nsz pycryptodome zstandard backports.zstd -q
if !errorlevel! NEQ 0 (
    echo  AVISO: Algunas dependencias pueden no haberse instalado.
    set "ERRORS=1"
) else (
    echo  OK - Dependencias instaladas.
)

:skip_pip
echo.

:: - [6/6] Motor nxnative -
echo [6/6] Descargando motor nxnative...

if exist "%CORE_DIR%\scripts\build_ipa_from_nsp.py" (
    echo  OK - Motor core ya presente.
) else (
    git --version >nul 2>&1
    if !errorlevel! NEQ 0 (
        echo  OMITIDO: Git no disponible.
        echo  Clona manualmente: git clone https://github.com/seedds/nxnative "%CORE_DIR%"
        set "ERRORS=1"
    ) else (
        echo  Descargando motor (1-3 minutos segun conexion)...
        git clone --depth 1 https://github.com/seedds/nxnative.git "%CORE_DIR%"
        if !errorlevel! NEQ 0 (
            echo  ERROR al descargar el motor core.
            set "ERRORS=1"
        ) else (
            echo  OK - Motor descargado.
        )
    )
)
echo.

:: - Lanzador y acceso directo -
echo Creando acceso directo en el Escritorio...

(
echo @echo off
echo title NSWPORTIOS
echo cd /d "%INSTALL_DIR%"
echo "%VENV_DIR%\Scripts\python.exe" switch2ipa_gui.py
echo if %%errorlevel%% NEQ 0 pause
) > "%INSTALL_DIR%\NSWPORTIOS.bat"

if exist "%USERPROFILE%\Desktop" (
    copy /y "%INSTALL_DIR%\NSWPORTIOS.bat" "%USERPROFILE%\Desktop\NSWPORTIOS.bat" >nul 2>&1
    echo  OK - Acceso directo en el Escritorio creado.
)

(
echo @echo off
echo echo Desinstalando NSWPORTIOS...
echo set /p c=Escribi S y Enter para confirmar: 
echo if /i "%%c%%"=="S" rmdir /s /q "%INSTALL_DIR%"
echo del "%%USERPROFILE%%\Desktop\NSWPORTIOS.bat" 2^>nul
echo echo Listo.
echo pause
) > "%INSTALL_DIR%\Desinstalar.bat"

:: - Resultado -
echo.
echo ================================================================
if !ERRORS! EQU 0 (
    echo    INSTALACION COMPLETADA CON EXITO
) else (
    echo    INSTALACION CON ADVERTENCIAS - Revisa los mensajes arriba
)
echo ================================================================
echo.
echo  Carpeta: %INSTALL_DIR%
echo.
echo  PROXIMOS PASOS:
echo    1. Coloca prod.keys en:  %INSTALL_DIR%\keys\
echo    2. Coloca juegos en:     %INSTALL_DIR%\input\
echo    3. Ejecuta NSWPORTIOS.bat desde el Escritorio
echo.
echo  Creditos:
echo    GitHub:    https://github.com/thebusk2
echo    Instagram: https://instagram.com/thebusk2
echo    X:         https://x.com/thebusk2
echo.
echo ================================================================
echo.
pause
