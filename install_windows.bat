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
set "PYTHON_EXE="

echo Instalando en: %INSTALL_DIR%
echo.

:: ================================================================
:: Funcion: buscar Python en todas las rutas conocidas
:: ================================================================
:find_python
set "PYTHON_EXE="
for %%P in (
    python.exe
    "%LOCALAPPDATA%\Programs\Python\Python312\python.exe"
    "%LOCALAPPDATA%\Programs\Python\Python311\python.exe"
    "%LOCALAPPDATA%\Programs\Python\Python310\python.exe"
    "%APPDATA%\Python\Python312\python.exe"
    "C:\Python312\python.exe"
    "C:\Python311\python.exe"
    "C:\Python310\python.exe"
    "C:\Program Files\Python312\python.exe"
    "C:\Program Files\Python311\python.exe"
    "C:\Program Files (x86)\Python312\python.exe"
) do (
    if "!PYTHON_EXE!"=="" (
        %%P --version >nul 2>&1
        if !errorlevel! EQU 0 (
            set "PYTHON_EXE=%%~P"
        )
    )
)
:: Also check where python
if "!PYTHON_EXE!"=="" (
    for /f "delims=" %%W in ('where python 2^>nul') do (
        if "!PYTHON_EXE!"=="" set "PYTHON_EXE=%%W"
    )
)
goto :eof

:: ================================================================
:: [1/7] INSTALAR PYTHON
:: ================================================================
echo [1/7] Verificando Python 3.10+...

call :find_python

if not "!PYTHON_EXE!"=="" (
    for /f "tokens=2" %%V in ('"!PYTHON_EXE!" --version 2>&1') do (
        echo  OK - Python %%V encontrado en: !PYTHON_EXE!
    )
    goto :python_ready
)

echo  Python no encontrado. Instalando automaticamente...
echo.

:: Metodo 1: winget (Windows 10+)
echo  Intentando instalar via winget...
winget install --id Python.Python.3.12 -e --silent --accept-package-agreements --accept-source-agreements 2>nul
if %errorlevel% EQU 0 (
    echo  winget ejecutado. Buscando Python instalado...
    :: Update PATH with common python locations
    set "PATH=%PATH%;%LOCALAPPDATA%\Programs\Python\Python312;%LOCALAPPDATA%\Programs\Python\Python312\Scripts"
    call :find_python
    if not "!PYTHON_EXE!"=="" (
        echo  OK - Python instalado via winget.
        goto :python_ready
    )
)

:: Metodo 2: PowerShell descarga directa (SIEMPRE disponible en Windows 7+)
echo  Descargando Python 3.12.7 con PowerShell...
echo  (Esto puede tardar 2-5 minutos segun tu conexion)
echo.

set "PY_INSTALLER=%TEMP%\python_312_installer.exe"
set "PY_URL=https://www.python.org/ftp/python/3.12.7/python-3.12.7-amd64.exe"

powershell -NoProfile -NonInteractive -Command ^
    "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; ^
    $wc = New-Object System.Net.WebClient; ^
    Write-Host '  Descargando...'; ^
    $wc.DownloadFile('%PY_URL%', '%PY_INSTALLER%'); ^
    Write-Host '  Descarga completa.'"

if not exist "%PY_INSTALLER%" (
    echo  ERROR: No se pudo descargar Python.
    echo  Verifica tu conexion a Internet.
    echo.
    echo  Descarga manual desde: https://www.python.org/downloads/
    echo  (Marca "Add Python to PATH" al instalar y vuelve a ejecutar este script)
    pause
    exit /b 1
)

echo  Instalando Python 3.12.7 (puede tardar 1-2 minutos)...
"%PY_INSTALLER%" /quiet InstallAllUsers=0 PrependPath=1 Include_launcher=0 Include_test=0 Include_pip=1

:: Esperar a que la instalacion termine
timeout /t 5 /nobreak >nul

:: Limpiar instalador
del /f /q "%PY_INSTALLER%" >nul 2>&1

:: Actualizar PATH
set "PATH=%PATH%;%LOCALAPPDATA%\Programs\Python\Python312;%LOCALAPPDATA%\Programs\Python\Python312\Scripts"
set "PATH=%PATH%;%APPDATA%\Python\Python312;%APPDATA%\Python\Python312\Scripts"

:: Buscar Python instalado
call :find_python

if not "!PYTHON_EXE!"=="" (
    echo  OK - Python instalado correctamente.
    goto :python_ready
)

:: Si aun no se encuentra, buscar con PowerShell
echo  Buscando Python en el sistema...
for /f "delims=" %%P in ('powershell -NoProfile -Command ^
    "Get-ChildItem 'C:\','%LOCALAPPDATA%\Programs' -Recurse -Filter python.exe -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName 2>$null"') do (
    set "PYTHON_EXE=%%P"
)

if not "!PYTHON_EXE!"=="" (
    echo  OK - Python encontrado en: !PYTHON_EXE!
    goto :python_ready
)

echo.
echo  ERROR CRITICO: La instalacion de Python no se completo.
echo  Por favor instala Python manualmente:
echo.
echo    1. Ve a: https://www.python.org/downloads/
echo    2. Descarga Python 3.12 (boton amarillo grande)
echo    3. Ejecuta el instalador
echo    4. IMPORTANTE: Marca la casilla "Add Python to PATH"
echo    5. Completa la instalacion
echo    6. Cierra esta ventana y vuelve a ejecutar install_windows.bat
echo.
pause
exit /b 1

:python_ready
echo.

:: ================================================================
:: [2/7] INSTALAR GIT
:: ================================================================
echo [2/7] Verificando Git...

git --version >nul 2>&1
if %errorlevel% EQU 0 (
    for /f "tokens=3" %%V in ('git --version 2^>^&1') do echo  OK - Git %%V encontrado.
    goto :git_ready
)

echo  Git no encontrado. Instalando automaticamente...

:: Metodo 1: winget
winget install --id Git.Git -e --silent --accept-package-agreements --accept-source-agreements 2>nul
set "PATH=%PATH%;C:\Program Files\Git\cmd;C:\Program Files\Git\bin"
git --version >nul 2>&1
if %errorlevel% EQU 0 (
    echo  OK - Git instalado via winget.
    goto :git_ready
)

:: Metodo 2: PowerShell descarga
echo  Descargando Git con PowerShell...
set "GIT_INSTALLER=%TEMP%\git_installer.exe"
set "GIT_URL=https://github.com/git-for-windows/git/releases/download/v2.47.0.windows.2/Git-2.47.0.2-64-bit.exe"

powershell -NoProfile -NonInteractive -Command ^
    "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; ^
    $wc = New-Object System.Net.WebClient; ^
    $wc.DownloadFile('%GIT_URL%', '%GIT_INSTALLER%')"

if exist "%GIT_INSTALLER%" (
    echo  Instalando Git...
    "%GIT_INSTALLER%" /VERYSILENT /NORESTART /NOCANCEL /SP- /CLOSEAPPLICATIONS /COMPONENTS="icons,ext\reg\shellhere,assoc,assoc_sh"
    del /f /q "%GIT_INSTALLER%" >nul 2>&1
    timeout /t 3 /nobreak >nul
    set "PATH=%PATH%;C:\Program Files\Git\cmd;C:\Program Files\Git\bin"
    git --version >nul 2>&1
    if !errorlevel! EQU 0 (
        echo  OK - Git instalado.
        goto :git_ready
    )
)

echo  AVISO: No se pudo instalar Git. El motor core no se descargara automaticamente.
echo  Instala Git desde: https://git-scm.com/download/win
set "ERRORS=1"

:git_ready
echo.

:: ================================================================
:: [3/7] CARPETAS
:: ================================================================
echo [3/7] Creando carpetas de trabajo...
if not exist "%INSTALL_DIR%"            mkdir "%INSTALL_DIR%"
if not exist "%INSTALL_DIR%\input"      mkdir "%INSTALL_DIR%\input"
if not exist "%INSTALL_DIR%\keys"       mkdir "%INSTALL_DIR%\keys"
if not exist "%INSTALL_DIR%\output"     mkdir "%INSTALL_DIR%\output"
if not exist "%INSTALL_DIR%\temp_build" mkdir "%INSTALL_DIR%\temp_build"
echo  OK - Carpetas creadas.
echo.

:: ================================================================
:: [4/7] COPIAR ARCHIVOS
:: ================================================================
echo [4/7] Copiando archivos del proyecto...
set "SRC=%~dp0"
if "%SRC:~-1%"=="\" set "SRC=%SRC:~0,-1%"
set "COPIED=0"
for %%F in (switch2ipa.py switch2ipa_gui.py README.md LICENSE) do (
    if exist "%SRC%\%%F" (
        copy /y "%SRC%\%%F" "%INSTALL_DIR%\%%F" >nul 2>&1
        set /a COPIED+=1
    )
)
if !COPIED! EQU 0 (
    echo  AVISO: Extrae TODOS los archivos del ZIP antes de ejecutar.
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
    echo  Creando entorno virtual en %VENV_DIR%...
    "!PYTHON_EXE!" -m venv "%VENV_DIR%"
    if !errorlevel! NEQ 0 (
        echo  ERROR creando entorno virtual. Usando Python del sistema.
        set "VENV_PYTHON=!PYTHON_EXE!"
        set "VENV_PIP=pip"
        set "ERRORS=1"
        goto :install_deps
    )
)

set "VENV_PYTHON=%VENV_DIR%\Scripts\python.exe"
set "VENV_PIP=%VENV_DIR%\Scripts\pip.exe"
echo  OK - Entorno virtual listo.

:install_deps
echo  Instalando dependencias (puede tardar 2-3 minutos)...
"!VENV_PIP!" install --upgrade pip -q 2>nul
"!VENV_PIP!" install lz4 "capstone>=5,<6" fonttools nsz pycryptodome zstandard backports.zstd -q

if !errorlevel! EQU 0 (
    echo  OK - Dependencias instaladas.
) else (
    echo  AVISO: Algunas dependencias pueden tener problemas.
    set "ERRORS=1"
)
echo.

:: ================================================================
:: [6/7] MOTOR NXNATIVE
:: ================================================================
echo [6/7] Descargando motor nxnative...

if exist "%CORE_DIR%\scripts\build_ipa_from_nsp.py" (
    echo  OK - Motor core ya presente.
    goto :core_ready
)

git --version >nul 2>&1
if %errorlevel% NEQ 0 (
    echo  OMITIDO: Git no disponible.
    set "ERRORS=1"
    goto :core_ready
)

echo  Clonando (1-3 minutos segun conexion)...
if exist "%CORE_DIR%" rmdir /s /q "%CORE_DIR%"
git clone --depth 1 https://github.com/seedds/nxnative.git "%CORE_DIR%"
if %errorlevel% EQU 0 (
    echo  OK - Motor descargado.
) else (
    echo  ERROR descargando el motor.
    set "ERRORS=1"
)

:core_ready
echo.

:: ================================================================
:: [7/7] ACCESO DIRECTO
:: ================================================================
echo [7/7] Creando acceso directo...

(
echo @echo off
echo title NSWPORTIOS
echo cd /d "%INSTALL_DIR%"
echo "%VENV_DIR%\Scripts\python.exe" switch2ipa_gui.py
echo if %%errorlevel%% NEQ 0 pause
) > "%INSTALL_DIR%\NSWPORTIOS.bat"

if exist "%USERPROFILE%\Desktop" (
    copy /y "%INSTALL_DIR%\NSWPORTIOS.bat" "%USERPROFILE%\Desktop\NSWPORTIOS.bat" >nul 2>&1
    echo  OK - Acceso directo creado en el Escritorio.
)
echo.

:: ================================================================
:: RESULTADO FINAL
:: ================================================================
echo ================================================================
if !ERRORS! EQU 0 (
    echo   INSTALACION COMPLETADA CON EXITO
) else (
    echo   INSTALACION CON ADVERTENCIAS - Revisa los mensajes AVISO
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
echo  Herramientas para firmar e instalar IPAs:
echo    TrollStore: https://github.com/opa334/TrollStore
echo    AltStore:   https://altstore.io/
echo    SideStore:  https://sidestore.io/
echo    Sideloadly: https://sideloadly.io/
echo.
echo  Creditos:
echo    GitHub:    https://github.com/thebusk2
echo    Instagram: https://instagram.com/thebusk2
echo    X:         https://x.com/thebusk2
echo ================================================================
echo.
pause
