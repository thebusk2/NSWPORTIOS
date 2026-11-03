@echo off
setlocal enabledelayedexpansion
title NSWPORTIOS v1.0.0 - Instalador Automatico Windows

echo.
echo ================================================================
echo   NSWPORTIOS v1.0.0 - Instalador Automatico para Windows
echo   Nintendo Switch to iOS Porter - by thebusk2
echo   github.com/thebusk2
echo ================================================================
echo.

set "INSTALL_DIR=%USERPROFILE%\NSWPORTIOS"
set "VENV_DIR=%INSTALL_DIR%\venv"
set "CORE_DIR=%INSTALL_DIR%\core"
set "ERRORS=0"
set "PYTHON_INSTALLED=0"

echo Instalando en: %INSTALL_DIR%
echo.

:: ================================================================
:: [1/7] INSTALAR PYTHON AUTOMATICAMENTE
:: ================================================================
echo [1/7] Verificando Python 3.12...

python --version >nul 2>&1
if %errorlevel% EQU 0 (
    for /f "tokens=2" %%v in ('python --version 2^>^&1') do set PYVER=%%v
    echo  OK - Python !PYVER! encontrado.
    set "PYTHON_INSTALLED=1"
    goto :python_ok
)

echo  Python no encontrado. Instalando automaticamente...
echo  Descargando Python 3.12.7 (puede tardar unos minutos)...

:: Try winget first (fastest)
winget install --id Python.Python.3.12 -e --silent --accept-package-agreements --accept-source-agreements >nul 2>&1
if %errorlevel% EQU 0 (
    :: Refresh PATH
    set "PATH=%PATH%;%LOCALAPPDATA%\Programs\Python\Python312;%LOCALAPPDATA%\Programs\Python\Python312\Scripts"
    set "PATH=%PATH%;%APPDATA%\Python\Python312\Scripts"
    python --version >nul 2>&1
    if !errorlevel! EQU 0 (
        echo  OK - Python instalado via winget.
        set "PYTHON_INSTALLED=1"
        goto :python_ok
    )
)

:: Fallback: download installer from python.org
echo  Descargando instalador de python.org...
curl -L --progress-bar "https://www.python.org/ftp/python/3.12.7/python-3.12.7-amd64.exe" -o "%TEMP%\python_installer.exe"
if %errorlevel% NEQ 0 (
    echo  ERROR: No se pudo descargar Python. Verifica tu conexion a Internet.
    set "ERRORS=1"
    goto :python_failed
)

echo  Instalando Python 3.12.7...
"%TEMP%\python_installer.exe" /quiet InstallAllUsers=0 PrependPath=1 Include_launcher=0 Include_test=0
del /f /q "%TEMP%\python_installer.exe" >nul 2>&1

:: Refresh PATH after installation
set "PATH=%PATH%;%LOCALAPPDATA%\Programs\Python\Python312;%LOCALAPPDATA%\Programs\Python\Python312\Scripts"
set "PATH=%PATH%;%APPDATA%\Python\Python312\Scripts"

python --version >nul 2>&1
if %errorlevel% EQU 0 (
    echo  OK - Python instalado desde python.org.
    set "PYTHON_INSTALLED=1"
    goto :python_ok
)

:python_failed
echo  ERROR CRITICO: No se pudo instalar Python automaticamente.
echo  Descargalo manualmente de: https://www.python.org/downloads/
echo  (Marca "Add Python to PATH" durante la instalacion)
pause
exit /b 1

:python_ok
echo.

:: ================================================================
:: [2/7] INSTALAR GIT AUTOMATICAMENTE
:: ================================================================
echo [2/7] Verificando Git...

git --version >nul 2>&1
if %errorlevel% EQU 0 (
    for /f "tokens=1,2,3" %%a in ('git --version 2^>^&1') do echo  OK - git version %%c encontrado.
    goto :git_ok
)

echo  Git no encontrado. Instalando automaticamente...

:: Try winget
winget install --id Git.Git -e --silent --accept-package-agreements --accept-source-agreements >nul 2>&1
set "PATH=%PATH%;C:\Program Files\Git\cmd;C:\Program Files\Git\bin"

git --version >nul 2>&1
if %errorlevel% EQU 0 (
    echo  OK - Git instalado via winget.
    goto :git_ok
)

:: Fallback: download git installer
echo  Descargando Git desde github.com...
curl -L --progress-bar "https://github.com/git-for-windows/git/releases/download/v2.47.0.windows.2/Git-2.47.0.2-64-bit.exe" -o "%TEMP%\git_installer.exe"
if %errorlevel% EQU 0 (
    echo  Instalando Git...
    "%TEMP%\git_installer.exe" /VERYSILENT /NORESTART /NOCANCEL /SP- /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS /COMPONENTS="icons,ext\reg\shellhere,assoc,assoc_sh"
    del /f /q "%TEMP%\git_installer.exe" >nul 2>&1
    set "PATH=%PATH%;C:\Program Files\Git\cmd;C:\Program Files\Git\bin"
    git --version >nul 2>&1
    if !errorlevel! EQU 0 (
        echo  OK - Git instalado.
        goto :git_ok
    )
)

echo  AVISO: Git no pudo instalarse. El motor core no se descargara.
set "ERRORS=1"

:git_ok
echo.

:: ================================================================
:: [3/7] CREAR CARPETAS
:: ================================================================
echo [3/7] Creando estructura de carpetas...

if not exist "%INSTALL_DIR%"            mkdir "%INSTALL_DIR%"
if not exist "%INSTALL_DIR%\input"      mkdir "%INSTALL_DIR%\input"
if not exist "%INSTALL_DIR%\keys"       mkdir "%INSTALL_DIR%\keys"
if not exist "%INSTALL_DIR%\output"     mkdir "%INSTALL_DIR%\output"
if not exist "%INSTALL_DIR%\temp_build" mkdir "%INSTALL_DIR%\temp_build"

echo  OK - Carpetas creadas en %INSTALL_DIR%
echo.

:: ================================================================
:: [4/7] COPIAR ARCHIVOS DEL PROYECTO
:: ================================================================
echo [4/7] Copiando archivos del proyecto...

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
    echo  AVISO: Extrae todos los archivos del ZIP primero.
    set "ERRORS=1"
) else (
    echo  OK - !COPIED! archivos copiados.
)
echo.

:: ================================================================
:: [5/7] ENTORNO PYTHON Y DEPENDENCIAS
:: ================================================================
echo [5/7] Configurando entorno Python y dependencias...

if not exist "%VENV_DIR%\Scripts\python.exe" (
    echo  Creando entorno virtual...
    python -m venv "%VENV_DIR%"
    if !errorlevel! NEQ 0 (
        echo  ERROR: No se pudo crear el entorno virtual.
        set "ERRORS=1"
        goto :skip_pip
    )
    echo  OK - Entorno virtual creado.
)

echo  Actualizando pip...
"%VENV_DIR%\Scripts\pip.exe" install --upgrade pip -q

echo  Instalando dependencias (lz4, nsz, pycryptodome, etc.)...
"%VENV_DIR%\Scripts\pip.exe" install lz4 "capstone>=5,<6" fonttools nsz pycryptodome zstandard backports.zstd -q

if !errorlevel! EQU 0 (
    echo  OK - Dependencias instaladas correctamente.
) else (
    echo  AVISO: Algunas dependencias pueden tener problemas.
    set "ERRORS=1"
)

:skip_pip
echo.

:: ================================================================
:: [6/7] DESCARGAR MOTOR NXNATIVE
:: ================================================================
echo [6/7] Descargando motor nxnative...

if exist "%CORE_DIR%\scripts\build_ipa_from_nsp.py" (
    echo  OK - Motor core ya presente.
    goto :core_ok
)

git --version >nul 2>&1
if %errorlevel% NEQ 0 (
    echo  OMITIDO: Git no disponible.
    echo  Clona manualmente: git clone https://github.com/seedds/nxnative "%CORE_DIR%"
    set "ERRORS=1"
    goto :core_ok
)

if exist "%CORE_DIR%" rmdir /s /q "%CORE_DIR%"

echo  Descargando motor (1-3 minutos segun conexion)...
git clone --depth 1 https://github.com/seedds/nxnative.git "%CORE_DIR%"
if %errorlevel% EQU 0 (
    echo  OK - Motor descargado.
) else (
    echo  ERROR al descargar el motor core.
    set "ERRORS=1"
)

:core_ok
echo.

:: ================================================================
:: [7/7] LANZADOR Y ACCESO DIRECTO
:: ================================================================
echo [7/7] Creando accesos directos...

(
echo @echo off
echo title NSWPORTIOS
echo cd /d "%INSTALL_DIR%"
echo "%VENV_DIR%\Scripts\python.exe" switch2ipa_gui.py
echo if %%errorlevel%% NEQ 0 (
echo     echo Error al iniciar. Asegurate de haber instalado todo correctamente.
echo     pause
echo )
) > "%INSTALL_DIR%\NSWPORTIOS.bat"

if exist "%USERPROFILE%\Desktop" (
    copy /y "%INSTALL_DIR%\NSWPORTIOS.bat" "%USERPROFILE%\Desktop\NSWPORTIOS.bat" >nul 2>&1
    echo  OK - Acceso directo creado en el Escritorio.
)

(
echo @echo off
echo set /p c=Desinstalar NSWPORTIOS? ^(S/N^): 
echo if /i "%%c%%"=="S" (
echo   rmdir /s /q "%INSTALL_DIR%"
echo   del "%%USERPROFILE%%\Desktop\NSWPORTIOS.bat" 2^>nul
echo   echo Desinstalado.
echo )
echo pause
) > "%INSTALL_DIR%\Desinstalar.bat"

echo  OK - Lanzador creado.
echo.

:: ================================================================
:: RESULTADO FINAL
:: ================================================================
echo.
echo ================================================================
if !ERRORS! EQU 0 (
    echo    INSTALACION COMPLETADA CON EXITO
) else (
    echo    INSTALACION CON ADVERTENCIAS
    echo    Revisa los mensajes AVISO/ERROR arriba.
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
echo  Herramientas para firmar IPA e instalar en iPhone/iPad:
echo    - AltStore:   https://altstore.io/
echo    - SideStore:  https://sidestore.io/
echo    - TrollStore: https://github.com/opa334/TrollStore
echo    - Sideloadly: https://sideloadly.io/
echo.
echo  Creditos:
echo    GitHub:    https://github.com/thebusk2
echo    Instagram: https://instagram.com/thebusk2
echo    X:         https://x.com/thebusk2
echo.
echo ================================================================
echo.
pause
