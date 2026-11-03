@echo off
setlocal enabledelayedexpansion
title NSWPORTIOS v1.0.0 - Instalador Automatico Windows

echo.
echo ================================================================
echo   NSWPORTIOS v1.0.0 - Instalador para Windows
echo   Nintendo Switch to iOS Porter - by thebusk2
echo   github.com/thebusk2
echo ================================================================
echo.

set "INSTALL_DIR=%USERPROFILE%\NSWPORTIOS"
set "VENV_DIR=%INSTALL_DIR%\venv"
set "CORE_DIR=%INSTALL_DIR%\core"
set "ERRORS=0"
set "PYTHON_EXE="
set "PY_INSTALLER=%TEMP%\python312setup.exe"
set "PY_URL=https://www.python.org/ftp/python/3.12.7/python-3.12.7-amd64.exe"

echo Instalando en: %INSTALL_DIR%
echo.

:: ================================================================
:: [1/7] VERIFICAR E INSTALAR PYTHON
:: ================================================================
echo [1/7] Verificando Python 3.10+ ...

:: Busqueda directa
for %%P in (python.exe py.exe) do (
    if "!PYTHON_EXE!"=="" (
        %%P --version >nul 2>&1
        if !errorlevel! EQU 0 set "PYTHON_EXE=%%~$PATH:P"
    )
)

:: Busqueda en rutas conocidas
if "!PYTHON_EXE!"=="" (
    for %%D in (
        "%LOCALAPPDATA%\Programs\Python\Python313"
        "%LOCALAPPDATA%\Programs\Python\Python312"
        "%LOCALAPPDATA%\Programs\Python\Python311"
        "%LOCALAPPDATA%\Programs\Python\Python310"
        "C:\Python313"
        "C:\Python312"
        "C:\Python311"
        "C:\Python310"
        "%ProgramFiles%\Python313"
        "%ProgramFiles%\Python312"
        "%ProgramFiles%\Python311"
    ) do (
        if "!PYTHON_EXE!"=="" (
            if exist "%%~D\python.exe" set "PYTHON_EXE=%%~D\python.exe"
        )
    )
)

:: Busqueda con where
if "!PYTHON_EXE!"=="" (
    for /f "tokens=* delims=" %%W in ('where python 2^>nul') do (
        if "!PYTHON_EXE!"=="" set "PYTHON_EXE=%%W"
    )
)

if not "!PYTHON_EXE!"=="" (
    echo   OK - Python encontrado en: !PYTHON_EXE!
    goto :python_ready
)

:: ---------- INSTALAR PYTHON ----------
echo   Python no encontrado. Instalando automaticamente...
echo.

:: Metodo 1: winget
echo   Intentando via winget ...
winget install --id Python.Python.3.12 -e --silent --accept-package-agreements --accept-source-agreements >nul 2>&1
if !errorlevel! EQU 0 (
    set "PATH=%PATH%;%LOCALAPPDATA%\Programs\Python\Python312;%LOCALAPPDATA%\Programs\Python\Python312\Scripts"
    for %%D in (
        "%LOCALAPPDATA%\Programs\Python\Python312"
        "%LOCALAPPDATA%\Programs\Python\Python313"
    ) do (
        if "!PYTHON_EXE!"=="" (
            if exist "%%~D\python.exe" set "PYTHON_EXE=%%~D\python.exe"
        )
    )
    if not "!PYTHON_EXE!"=="" (
        echo   OK - Python instalado via winget.
        goto :python_ready
    )
)

:: Metodo 2: PowerShell descarga directa
echo   Descargando Python 3.12.7 desde python.org ...
echo   (Puede tardar 2-5 minutos segun tu conexion a Internet)
echo.

:: Eliminar descarga previa si existe
if exist "%PY_INSTALLER%" del /f /q "%PY_INSTALLER%" >nul 2>&1

:: Descargar con PowerShell
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -Uri '%PY_URL%' -OutFile '%PY_INSTALLER%' -UseBasicParsing" >nul 2>&1

if not exist "%PY_INSTALLER%" (
    :: Segundo intento con WebClient
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "$wc = New-Object System.Net.WebClient; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $wc.DownloadFile('%PY_URL%', '%PY_INSTALLER%')" >nul 2>&1
)

if not exist "%PY_INSTALLER%" (
    echo.
    echo   ERROR: No se pudo descargar Python.
    echo   Por favor descarga e instala Python manualmente:
    echo   https://www.python.org/ftp/python/3.12.7/python-3.12.7-amd64.exe
    echo   IMPORTANTE: Marca "Add Python to PATH" durante la instalacion.
    echo   Luego vuelve a ejecutar este script.
    echo.
    pause
    exit /b 1
)

echo   Instalando Python 3.12.7 de forma silenciosa ...
"%PY_INSTALLER%" /quiet InstallAllUsers=0 PrependPath=1 Include_launcher=0 Include_test=0 Include_pip=1 Include_tcltk=0

:: Esperar a que termine
echo   Esperando que finalice la instalacion ...
timeout /t 8 /nobreak >nul

:: Limpiar
del /f /q "%PY_INSTALLER%" >nul 2>&1

:: Actualizar PATH con todas las rutas posibles
set "PATH=%PATH%;%LOCALAPPDATA%\Programs\Python\Python312;%LOCALAPPDATA%\Programs\Python\Python312\Scripts"
set "PATH=%PATH%;%LOCALAPPDATA%\Programs\Python\Python313;%LOCALAPPDATA%\Programs\Python\Python313\Scripts"
set "PATH=%PATH%;%APPDATA%\Python\Python312;C:\Python312;C:\Python312\Scripts"

:: Buscar Python instalado
for %%D in (
    "%LOCALAPPDATA%\Programs\Python\Python312"
    "%LOCALAPPDATA%\Programs\Python\Python313"
    "%LOCALAPPDATA%\Programs\Python\Python311"
    "C:\Python312"
    "C:\Python313"
    "%ProgramFiles%\Python312"
) do (
    if "!PYTHON_EXE!"=="" (
        if exist "%%~D\python.exe" set "PYTHON_EXE=%%~D\python.exe"
    )
)

:: Ultimo intento con where
if "!PYTHON_EXE!"=="" (
    for /f "tokens=* delims=" %%W in ('where python 2^>nul') do (
        if "!PYTHON_EXE!"=="" set "PYTHON_EXE=%%W"
    )
)

:: Ultimo intento con PowerShell
if "!PYTHON_EXE!"=="" (
    for /f "tokens=* delims=" %%F in ('powershell -NoProfile -Command "Get-ChildItem -Path @($env:LOCALAPPDATA+'\Programs'),'C:\' -Recurse -Filter python.exe -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName" 2^>nul') do (
        if "!PYTHON_EXE!"=="" set "PYTHON_EXE=%%F"
    )
)

if not "!PYTHON_EXE!"=="" (
    echo   OK - Python instalado correctamente: !PYTHON_EXE!
    goto :python_ready
)

echo.
echo   ERROR: Python no pudo ser instalado automaticamente.
echo   Descarga e instala Python manualmente desde:
echo   https://www.python.org/ftp/python/3.12.7/python-3.12.7-amd64.exe
echo   Marca "Add Python to PATH" y vuelve a ejecutar este script.
echo.
pause
exit /b 1

:python_ready
echo.

:: ================================================================
:: [2/7] VERIFICAR GIT
:: ================================================================
echo [2/7] Verificando Git ...

git --version >nul 2>&1
if %errorlevel% EQU 0 (
    echo   OK - Git disponible.
    set "GIT_OK=1"
) else (
    echo   AVISO: Git no encontrado. Se omitira la descarga del motor core.
    echo   Descarga Git desde: https://git-scm.com/download/win
    set "GIT_OK=0"
    set "ERRORS=1"
)
echo.

:: ================================================================
:: [3/7] CREAR CARPETAS
:: ================================================================
echo [3/7] Creando carpetas de trabajo ...

if not exist "%INSTALL_DIR%"            mkdir "%INSTALL_DIR%"
if not exist "%INSTALL_DIR%\input"      mkdir "%INSTALL_DIR%\input"
if not exist "%INSTALL_DIR%\keys"       mkdir "%INSTALL_DIR%\keys"
if not exist "%INSTALL_DIR%\output"     mkdir "%INSTALL_DIR%\output"
if not exist "%INSTALL_DIR%\temp_build" mkdir "%INSTALL_DIR%\temp_build"

echo   OK - Carpetas creadas en %INSTALL_DIR%
echo.

:: ================================================================
:: [4/7] COPIAR ARCHIVOS DEL PROYECTO
:: ================================================================
echo [4/7] Copiando archivos del proyecto ...

set "SRC=%~dp0"
if "%SRC:~-1%"=="\" set "SRC=%SRC:~0,-1%"
set "COPIED=0"

for %%F in (switch2ipa.py switch2ipa_gui.py README.md) do (
    if exist "%SRC%\%%F" (
        copy /y "%SRC%\%%F" "%INSTALL_DIR%\%%F" >nul 2>&1
        set /a COPIED+=1
    )
)

if exist "%SRC%\src_gui\icon.ico" (
    if not exist "%INSTALL_DIR%\src_gui" mkdir "%INSTALL_DIR%\src_gui"
    copy /y "%SRC%\src_gui\icon.ico" "%INSTALL_DIR%\src_gui\icon.ico" >nul 2>&1
)

if !COPIED! EQU 0 (
    echo   AVISO: Extrae TODOS los archivos del ZIP antes de ejecutar.
    echo   Archivos necesarios: switch2ipa.py, switch2ipa_gui.py
    set "ERRORS=1"
) else (
    echo   OK - !COPIED! archivos copiados.
)
echo.

:: ================================================================
:: [5/7] ENTORNO VIRTUAL Y DEPENDENCIAS PYTHON
:: ================================================================
echo [5/7] Configurando entorno Python y dependencias ...

if not exist "%VENV_DIR%\Scripts\python.exe" (
    echo   Creando entorno virtual ...
    "!PYTHON_EXE!" -m venv "%VENV_DIR%"
    if !errorlevel! NEQ 0 (
        echo   AVISO: No se pudo crear entorno virtual. Usando Python global.
        set "VENV_PYTHON=!PYTHON_EXE!"
        set "VENV_PIP=!PYTHON_EXE! -m pip"
        goto :install_deps
    )
)

set "VENV_PYTHON=%VENV_DIR%\Scripts\python.exe"
set "VENV_PIP=%VENV_DIR%\Scripts\pip.exe"
echo   OK - Entorno virtual listo.

:install_deps
echo   Instalando dependencias (puede tardar 2-3 minutos) ...

"!VENV_PYTHON!" -m pip install --upgrade pip --quiet >nul 2>&1
"!VENV_PYTHON!" -m pip install lz4 "capstone>=5,<6" fonttools nsz pycryptodome zstandard backports.zstd --quiet

if !errorlevel! EQU 0 (
    echo   OK - Dependencias instaladas correctamente.
) else (
    echo   AVISO: Algunas dependencias pueden tener problemas.
    set "ERRORS=1"
)
echo.

:: ================================================================
:: [6/7] MOTOR NXNATIVE
:: ================================================================
echo [6/7] Descargando motor nxnative ...

if exist "%CORE_DIR%\scripts\build_ipa_from_nsp.py" (
    echo   OK - Motor core ya presente.
    goto :core_ready
)

if "%GIT_OK%"=="0" (
    echo   OMITIDO: Git no disponible. Instala Git y vuelve a ejecutar.
    goto :core_ready
)

echo   Clonando motor (1-3 minutos segun velocidad de Internet) ...
if exist "%CORE_DIR%" rmdir /s /q "%CORE_DIR%"
git clone --depth 1 https://github.com/seedds/nxnative.git "%CORE_DIR%"

if !errorlevel! EQU 0 (
    echo   OK - Motor nxnative descargado.
) else (
    echo   ERROR: No se pudo clonar el motor.
    set "ERRORS=1"
)

:core_ready
echo.

:: ================================================================
:: [7/7] CREAR ACCESO DIRECTO EN ESCRITORIO
:: ================================================================
echo [7/7] Creando acceso directo ...

(
echo @echo off
echo title NSWPORTIOS
echo cd /d "%INSTALL_DIR%"
echo "%VENV_DIR%\Scripts\python.exe" switch2ipa_gui.py
echo if %%errorlevel%% NEQ 0 pause
) > "%INSTALL_DIR%\NSWPORTIOS.bat"

if exist "%USERPROFILE%\Desktop" (
    copy /y "%INSTALL_DIR%\NSWPORTIOS.bat" "%USERPROFILE%\Desktop\NSWPORTIOS.bat" >nul 2>&1
    echo   OK - Acceso directo en Escritorio: NSWPORTIOS.bat
) else (
    echo   OK - Launcher creado en: %INSTALL_DIR%\NSWPORTIOS.bat
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
echo   Carpeta de instalacion: %INSTALL_DIR%
echo.
echo   PROXIMOS PASOS:
echo     1. Coloca prod.keys en:  %INSTALL_DIR%\keys\
echo     2. Coloca juegos NSP/XCI en: %INSTALL_DIR%\input\
echo     3. Haz doble clic en NSWPORTIOS.bat del Escritorio
echo.
echo   NOTA: La compilacion real de IPA requiere macOS con Xcode.
echo   En Windows puedes preparar archivos y ver la herramienta.
echo.
echo   Herramientas para firmar e instalar IPA en iPhone/iPad:
echo     TrollStore:  https://github.com/opa334/TrollStore
echo     AltStore:    https://altstore.io/
echo     SideStore:   https://sidestore.io/
echo     Sideloadly:  https://sideloadly.io/
echo.
echo   Creditos:
echo     GitHub:    https://github.com/thebusk2
echo     Instagram: https://instagram.com/thebusk2
echo     X/Twitter: https://x.com/thebusk2
echo ================================================================
echo.
pause
