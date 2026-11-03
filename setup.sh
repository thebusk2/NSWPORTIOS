#!/usr/bin/env bash
# ==============================================================================
# NSWPORTIOS - Instalador de Dependencias y Preparador de Entorno
# ==============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$DIR/tools/venv"

echo -e "${CYAN}================================================================${NC}"
echo -e "${CYAN}   NSWPORTIOS - Configuración de Dependencias para Porteo iOS   ${NC}"
echo -e "${CYAN}================================================================${NC}"

# 1. Comprobar Xcode
echo -e "\n${BLUE}[1/5] Verificando Xcode y Developer Tools...${NC}"
if ! command -v xcodebuild &>/dev/null; then
    echo -e "${RED}[ERROR] Xcode no está instalado o no está seleccionado en el sistema.${NC}"
    echo -e "Instala Xcode desde la Mac App Store o https://developer.apple.com/"
    echo -e "Y luego ejecuta: sudo xcode-select -s /Applications/Xcode.app"
    exit 1
fi

XCODE_VER=$(xcodebuild -version | head -n 1)
echo -e "${GREEN}✓ Xcode detectado: $XCODE_VER${NC}"

# 2. Descargar / Verificar Metal Toolchain
echo -e "\n${BLUE}[2/5] Verificando Metal Toolchain de Xcode...${NC}"
echo "Comprobando componentes de Metal..."
xcodebuild -downloadComponent MetalToolchain 2>/dev/null || true
echo -e "${GREEN}✓ Metal Toolchain verificado.${NC}"

# 3. Comprobar Homebrew y herramientas de compilación
echo -e "\n${BLUE}[3/5] Verificando Homebrew y herramientas CLI (xcodegen, zstd, glslang, dotnet)...${NC}"
if ! command -v brew &>/dev/null; then
    # Revisar rutas estándar
    if [ -x "/opt/homebrew/bin/brew" ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -x "/usr/local/bin/brew" ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    else
        echo -e "${YELLOW}[AVISO] Homebrew no está en PATH.${NC}"
        echo -e "Para instalar Homebrew ejecuta:"
        echo -e '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
        echo -e "Luego vuelve a ejecutar este script."
    fi
fi

if command -v brew &>/dev/null; then
    echo -e "${GREEN}✓ Homebrew disponible. Instalando/Verificando paquetes requeridos...${NC}"
    for pkg in xcodegen zstd glslang; do
        if ! command -v $pkg &>/dev/null; then
            echo -e "Instalando $pkg..."
            brew install $pkg || true
        else
            echo -e "${GREEN}✓ $pkg ya está instalado.${NC}"
        fi
    done

    if ! command -v dotnet &>/dev/null; then
        echo -e "Instalando .NET SDK (necesario para LibHac y extracción de NCAs)..."
        brew install --cask dotnet-sdk || true
    else
        echo -e "${GREEN}✓ dotnet SDK ya está instalado: $(dotnet --version)${NC}"
    fi
fi

# 4. Entorno Virtual de Python y Paquetes de Recompilación
echo -e "\n${BLUE}[4/5] Configurando Entorno Virtual Python y Librerías...${NC}"
PYTHON_BIN=""
for py in python3.12 python3.11 python3.10 python3; do
    if command -v $py &>/dev/null; then
        PYTHON_BIN=$(command -v $py)
        break
    fi
done

echo -e "Usando Python base: $PYTHON_BIN ($($PYTHON_BIN --version))"

if [ ! -d "$VENV_DIR" ]; then
    echo -e "Creando entorno virtual en $VENV_DIR..."
    $PYTHON_BIN -m venv "$VENV_DIR"
fi

source "$VENV_DIR/bin/activate"
echo -e "Actualizando pip..."
pip install --upgrade pip setuptools wheel -q

echo -e "Instalando dependencias requeridas (capstone, lz4, fonttools, nsz, etc.)..."
pip install lz4 "capstone>=5,<6" fonttools nsz zbic pycryptodome -q
pip install "backports.zstd" 2>/dev/null || true

echo -e "${GREEN}✓ Entorno Python configurado con éxito.${NC}"

# 5. Crear carpetas de trabajo y verificar motor core
echo -e "\n${BLUE}[5/5] Preparando motor y carpetas de trabajo...${NC}"
mkdir -p "$DIR/input" "$DIR/keys" "$DIR/output" "$DIR/temp_build"

if [ ! -d "$DIR/core" ]; then
    echo -e "Descargando motor nativo core (seedds/nxnative)..."
    git clone --depth 1 https://github.com/seedds/nxnative.git "$DIR/core"
    echo -e "${GREEN}✓ Motor core descargado con éxito.${NC}"
else
    echo -e "${GREEN}✓ Motor core ya está presente.${NC}"
fi

echo -e "${GREEN}✓ Directorios listos:${NC}"
echo -e "   - input/     -> Coloca aquí tus juegos (.nsp, .xci, .nsz, .xcz)"
echo -e "   - keys/      -> Coloca aquí tu archivo prod.keys"
echo -e "   - output/    -> Aquí se guardarán tus archivos .ipa compilados"

echo -e "\n${GREEN}================================================================${NC}"
echo -e "${GREEN}      ¡Configuración completada con éxito!                       ${NC}"
echo -e "${GREEN}      Usa './switch2ipa' para comenzar a compilar.               ${NC}"
echo -e "${GREEN}================================================================${NC}\n"
