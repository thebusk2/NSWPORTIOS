@echo off
TITLE NSWPORTIOS - Instalador para Windows
COLOR 0B

echo ================================================================
echo             NSWPORTIOS - Instalador para Windows
echo      Nintendo Switch to iOS Porter Toolchain Suite
echo                   Autor: thebusk2
echo ================================================================
echo.

:: 1. Comprobar Python
python --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Python no esta instalado o no esta en el PATH.
    echo Por favor descarga e instala Python 3.10 o superior desde:
    echo https://www.python.org/downloads/
    echo (Asegurate de marcar la casilla "Add Python to PATH" durante la instalacion)
    echo.
    pause
    exit /b 1
)

echo [1/3] Python detectado correctamente.
echo.

:: 2. Instalar dependencias Python
echo [2/3] Instalando librerias necesarias (nsz, pycryptodome, lz4)...
python -m pip install --upgrade pip
python -m pip install nsz pycryptodome lz4

echo.
echo [3/3] Creando estructura de carpetas de trabajo...
if not exist "input" mkdir input
if not exist "keys" mkdir keys
if not exist "output" mkdir output

echo.
echo ================================================================
echo           Instalacion completada con exito en Windows!
echo ================================================================
echo.
echo Puedes iniciar la interfaz visual ejecutando:
echo   python switch2ipa_gui.py
echo.
echo O presiona cualquier tecla para abrir la interfaz ahora...
pause >nul
python switch2ipa_gui.py
