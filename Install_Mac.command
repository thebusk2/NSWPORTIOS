#!/usr/bin/env bash
# ==============================================================================
# NSWPORTIOS - Instalador de un solo clic para macOS
# Doble clic para ejecutar
# ==============================================================================

DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR"

echo "================================================================"
echo "          NSWPORTIOS - Instalador Automático macOS             "
echo "================================================================"
echo ""

# Ejecutar el setup de dependencias
bash "$DIR/setup.sh"

echo ""
echo "Instalando NSWPORTIOS en /Applications..."
if [ -d "$DIR/NSWPORTIOS.app" ]; then
    cp -R "$DIR/NSWPORTIOS.app" /Applications/ 2>/dev/null || sudo cp -R "$DIR/NSWPORTIOS.app" /Applications/
    echo "✓ NSWPORTIOS.app instalado en /Applications"
fi

echo ""
echo "================================================================"
echo "          ¡Instalación completada con éxito!                   "
echo "   Puedes abrir NSWPORTIOS desde Launchpad o /Applications     "
echo "================================================================"
echo ""
read -p "Presiona ENTER para abrir la aplicación..."
open /Applications/NSWPORTIOS.app 2>/dev/null || open "$DIR/NSWPORTIOS.app"
