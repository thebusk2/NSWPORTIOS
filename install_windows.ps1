# ==============================================================================
# NSWPORTIOS - Windows PowerShell Installer & Launcher
# Autor: thebusk2 (https://github.com/thebusk2)
# ==============================================================================

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "           NSWPORTIOS - Instalador para Windows                 " -ForegroundColor Cyan
Write-Host "      Nintendo Switch to iOS Porter Toolchain Suite             " -ForegroundColor Cyan
Write-Host "                 Autor: thebusk2                                " -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Comprobar Python
try {
    $pyVer = python --version 2>&1
    Write-Host "[1/3] Python detectado: $pyVer" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Python no está instalado en este sistema." -ForegroundColor Red
    Write-Host "Descárgalo de https://www.python.org/ (recuerda marcar 'Add Python to PATH')" -ForegroundColor Yellow
    Pause
    Exit 1
}

# 2. Instalar dependencias
Write-Host ""
Write-Host "[2/3] Instalando dependencias de Python (nsz, pycryptodome, lz4)..." -ForegroundColor Yellow
python -m pip install --upgrade pip -q
python -m pip install nsz pycryptodome lz4 -q
Write-Host "✓ Librerías instaladas." -ForegroundColor Green

# 3. Crear carpetas
Write-Host ""
Write-Host "[3/3] Configurando carpetas locales..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path "input", "keys", "output" | Out-Null
Write-Host "✓ Carpetas 'input', 'keys' y 'output' listas." -ForegroundColor Green

# 4. Crear Acceso Directo en el Escritorio
$desktop = [Environment]::GetFolderPath("Desktop")
$wscript = New-Object -ComObject WScript.Shell
$shortcut = $wscript.CreateShortcut("$desktop\NSWPORTIOS.lnk")
$shortcut.TargetPath = "pythonw.exe"
$shortcut.Arguments = "`"$PSScriptRoot\switch2ipa_gui.py`""
$shortcut.WorkingDirectory = "$PSScriptRoot"
$shortcut.IconLocation = "shell32.dll,24"
$shortcut.Save()

Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host "   ¡Instalación completada! Se ha creado un acceso directo en tu Escritorio." -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""

$ans = Read-Host "¿Deseas abrir la interfaz gráfica de NSWPORTIOS ahora? (S/N)"
if ($ans -eq 'S' -or $ans -eq 's' -or $ans -eq '') {
    python "$PSScriptRoot\switch2ipa_gui.py"
}
