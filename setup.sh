#!/usr/bin/env bash
# ==============================================================================
# NSWPORTIOS v1.0.0 - Instalador Automatico para macOS
# Nintendo Switch to iOS Porter Toolchain Suite
# Autor: thebusk2 (https://github.com/thebusk2)
# ==============================================================================
# Uso: bash setup.sh
# Instala automaticamente: Xcode CLI Tools, Python 3.12, .NET SDK,
#   xcodegen, zstd, glslang, uv, dependencias Python, motor nxnative
# ==============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ok()   { echo -e "${GREEN}  OK${NC}  $1"; }
warn() { echo -e "${YELLOW}  WARN${NC} $1"; }
err()  { echo -e "${RED}  FAIL${NC} $1"; }
step() { echo -e "\n${CYAN}[$1/$2]${NC} ${BOLD}$3${NC}"; }

echo ""
echo "================================================================"
echo "  NSWPORTIOS v1.0.0 - Instalador Automatico para macOS"
echo "  Nintendo Switch to iOS Porter - by thebusk2"
echo "  github.com/thebusk2"
echo "================================================================"
echo ""

ERRORS=0
TOTAL_STEPS=8

# ── [1/8] Xcode Command Line Tools ────────────────────────────────────────────
step 1 $TOTAL_STEPS "Verificando Xcode y Command Line Tools..."

if ! xcode-select -p &>/dev/null; then
    echo "  Xcode CLI Tools no encontrado. Instalando automaticamente..."
    # Non-interactive install
    touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
    PROD=$(softwareupdate -l 2>/dev/null | grep -B1 "Command Line" | awk -F"*" '/\*/ {print $2}' | sed 's/^ *//' | head -1)
    if [ -n "$PROD" ]; then
        softwareupdate -i "$PROD" --verbose 2>&1 | tail -5
        rm -f /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
    else
        rm -f /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
        echo "  Instalando via xcode-select --install..."
        xcode-select --install 2>/dev/null || true
        echo "  Sigue el dialogo de instalacion de Xcode CLI Tools."
        echo "  Luego vuelve a ejecutar este script."
        exit 1
    fi
fi

XCODE_PATH=$(xcode-select -p 2>/dev/null)
ok "Xcode CLI Tools: $XCODE_PATH"

# Verificar si Xcode.app completo esta instalado (necesario para iOS SDK)
if ! xcodebuild -version &>/dev/null; then
    warn "Xcode.app completo no encontrado."
    echo ""
    echo "  IMPORTANTE: Para compilar IPAs para iOS necesitas Xcode completo."
    echo "  Instala desde la Mac App Store:"
    echo "  https://apps.apple.com/us/app/xcode/id497799835"
    echo ""
    echo "  Continuando con la instalacion del resto de herramientas..."
    sleep 3
else
    XCODE_VER=$(xcodebuild -version 2>/dev/null | head -1)
    ok "$XCODE_VER"
fi

# ── [2/8] Metal Toolchain ─────────────────────────────────────────────────────
step 2 $TOTAL_STEPS "Verificando Metal Toolchain..."

if xcodebuild -version &>/dev/null; then
    echo "  Descargando Metal Toolchain (necesario para shaders iOS)..."
    xcodebuild -downloadComponent MetalToolchain 2>/dev/null || true
    ok "Metal Toolchain verificado."
else
    warn "Metal Toolchain omitido (requiere Xcode.app)"
fi

# ── [3/8] Instalar uv y Python 3.12 ──────────────────────────────────────────
step 3 $TOTAL_STEPS "Instalando Python 3.12 via uv..."

export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

if ! command -v uv &>/dev/null && [ ! -x "$HOME/.local/bin/uv" ]; then
    echo "  Instalando uv (gestor de Python ultrarapido)..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
fi

UV_BIN="$(command -v uv 2>/dev/null || echo "$HOME/.local/bin/uv")"
ok "uv encontrado: $UV_BIN"

# Crear venv con Python 3.12
VENV_DIR="$HOME/.nswportios_venv"
if [ ! -d "$VENV_DIR" ]; then
    echo "  Creando entorno Python 3.12..."
    "$UV_BIN" venv "$VENV_DIR" --python 3.12 2>/dev/null || \
    "$UV_BIN" venv "$VENV_DIR" --python 3.11 2>/dev/null || \
    "$UV_BIN" venv "$VENV_DIR"
fi
PYTHON_BIN="$VENV_DIR/bin/python3"
PY_VER=$("$PYTHON_BIN" --version 2>&1)
ok "Python venv: $PY_VER"

# ── [4/8] Dependencias Python ─────────────────────────────────────────────────
step 4 $TOTAL_STEPS "Instalando dependencias Python..."

echo "  Instalando lz4, capstone, fonttools, nsz, pycryptodome, zstandard, backports.zstd..."
"$UV_BIN" pip install \
    --python "$PYTHON_BIN" \
    lz4 "capstone>=5,<6" fonttools nsz pycryptodome zstandard "backports.zstd" -q

ok "Dependencias Python instaladas."

# ── [5/8] .NET SDK ────────────────────────────────────────────────────────────
step 5 $TOTAL_STEPS "Instalando .NET SDK..."

if command -v dotnet &>/dev/null; then
    ok ".NET SDK: $(dotnet --version)"
elif [ -x "$HOME/.dotnet/dotnet" ]; then
    ok ".NET SDK (local): $($HOME/.dotnet/dotnet --version)"
    export PATH="$HOME/.dotnet:$PATH"
    export DOTNET_ROOT="$HOME/.dotnet"
else
    echo "  Descargando .NET SDK..."
    curl -sSL https://dot.net/v1/dotnet-install.sh | bash /dev/stdin \
        --install-dir "$HOME/.dotnet" --channel LTS 2>&1 | tail -3
    export PATH="$HOME/.dotnet:$PATH"
    export DOTNET_ROOT="$HOME/.dotnet"
    if [ -x "$HOME/.dotnet/dotnet" ]; then
        ok ".NET SDK instalado: $($HOME/.dotnet/dotnet --version)"
    else
        warn ".NET SDK no instalado. Algunos juegos pueden necesitarlo."
        ERRORS=1
    fi
fi

# ── [6/8] Herramientas CLI (xcodegen, zstd, glslang) ─────────────────────────
step 6 $TOTAL_STEPS "Instalando herramientas CLI..."

mkdir -p "$HOME/.local/bin"

# xcodegen
if ! command -v xcodegen &>/dev/null && [ ! -x "$HOME/.local/bin/xcodegen" ]; then
    echo "  Instalando xcodegen..."
    XCG_URL=$(curl -sL https://api.github.com/repos/yonaskolb/XcodeGen/releases/latest \
        | grep browser_download_url | grep "xcodegen.zip" | head -1 | cut -d'"' -f4)
    if [ -n "$XCG_URL" ]; then
        curl -sL "$XCG_URL" -o /tmp/xcodegen.zip
        unzip -qo /tmp/xcodegen.zip -d /tmp/xcodegen_dir 2>/dev/null || true
        find /tmp/xcodegen_dir -name "xcodegen" -type f -exec cp {} "$HOME/.local/bin/xcodegen" \; 2>/dev/null || true
        rm -rf /tmp/xcodegen.zip /tmp/xcodegen_dir
    fi
fi
[ -x "$HOME/.local/bin/xcodegen" ] && ok "xcodegen instalado" || warn "xcodegen no disponible"

# zstd
if ! command -v zstd &>/dev/null && [ ! -x "$HOME/.local/bin/zstd" ]; then
    echo "  Instalando zstd..."
    ZSTD_URL=$(curl -sL https://api.github.com/repos/facebook/zstd/releases/latest \
        | grep browser_download_url | grep "mac" | grep ".tar.gz" | head -1 | cut -d'"' -f4)
    if [ -n "$ZSTD_URL" ]; then
        curl -sL "$ZSTD_URL" -o /tmp/zstd.tar.gz
        tar -xzf /tmp/zstd.tar.gz -C /tmp/ 2>/dev/null || true
        find /tmp -maxdepth 3 -name "zstd" -type f -exec cp {} "$HOME/.local/bin/zstd" \; 2>/dev/null || true
        rm -f /tmp/zstd.tar.gz
    else
        # Build from source
        cd /tmp && git clone --depth 1 https://github.com/facebook/zstd.git zstd_src 2>/dev/null \
            && cd zstd_src && make -j$(sysctl -n hw.logicalcpu) 2>/dev/null \
            && cp programs/zstd "$HOME/.local/bin/" && cd - >/dev/null \
            && rm -rf /tmp/zstd_src
    fi
fi
[ -x "$HOME/.local/bin/zstd" ] || command -v zstd &>/dev/null && ok "zstd instalado" || warn "zstd no disponible"

# glslang
if ! command -v glslang &>/dev/null && [ ! -x "$HOME/.local/bin/glslang" ]; then
    echo "  Instalando glslang..."
    GLSL_URL=$(curl -sL https://api.github.com/repos/KhronosGroup/glslang/releases/latest \
        | grep browser_download_url | grep -i "osx\|macos\|mac" | grep ".zip" | head -1 | cut -d'"' -f4)
    if [ -n "$GLSL_URL" ]; then
        curl -sL "$GLSL_URL" -o /tmp/glslang.zip
        unzip -qo /tmp/glslang.zip -d /tmp/glslang_dir 2>/dev/null || true
        find /tmp/glslang_dir -name "glslang" -type f -exec cp {} "$HOME/.local/bin/glslang" \; 2>/dev/null || true
        rm -rf /tmp/glslang.zip /tmp/glslang_dir
    fi
fi
[ -x "$HOME/.local/bin/glslang" ] && ok "glslang instalado" || warn "glslang no disponible (opcional)"

export PATH="$HOME/.local/bin:$HOME/.dotnet:$PATH"
export DOTNET_ROOT="$HOME/.dotnet"

# ── [7/8] Motor nxnative ──────────────────────────────────────────────────────
step 7 $TOTAL_STEPS "Descargando motor nxnative..."

CORE_DIR="$HOME/.nxnative"
CORE_LINK="$DIR/core"

if [ -d "$CORE_DIR" ] && [ -f "$CORE_DIR/scripts/build_ipa_from_nsp.py" ]; then
    ok "Motor core ya presente: $CORE_DIR"
else
    echo "  Clonando motor nxnative (1-3 minutos)..."
    rm -rf "$CORE_DIR"
    git clone --depth 1 https://github.com/seedds/nxnative.git "$CORE_DIR" \
        && ok "Motor descargado: $CORE_DIR" \
        || { warn "No se pudo descargar el motor core"; ERRORS=1; }
fi

# Symlink en el proyecto
[ -L "$CORE_LINK" ] || ln -sf "$CORE_DIR" "$CORE_LINK" 2>/dev/null || true

# ── [8/8] Carpetas y configuracion final ──────────────────────────────────────
step 8 $TOTAL_STEPS "Creando carpetas y configuracion final..."

mkdir -p "$DIR/input" "$DIR/keys" "$DIR/output" "$DIR/temp_build"
ok "Carpetas: input/ keys/ output/ temp_build/"

# Crear perfil de entorno para que switch2ipa.py encuentre todo
cat > "$DIR/.nswportios_env" << ENVEOF
export PATH="\$HOME/.local/bin:\$HOME/.dotnet:\$PATH"
export DOTNET_ROOT="\$HOME/.dotnet"
export NSWPORTIOS_PYTHON="$PYTHON_BIN"
export NSWPORTIOS_CORE="$CORE_DIR"
ENVEOF
ok "Perfil de entorno guardado en .nswportios_env"

# ── Resumen ───────────────────────────────────────────────────────────────────
echo ""
echo "================================================================"
if [ $ERRORS -eq 0 ]; then
    echo "  INSTALACION COMPLETADA CON EXITO"
else
    echo "  INSTALACION CON ADVERTENCIAS - Revisa mensajes WARN arriba"
fi
echo "================================================================"
echo ""
echo "  Carpeta del proyecto: $DIR"
echo "  Python:               $PYTHON_BIN"
echo "  Motor nxnative:       $CORE_DIR"
echo ""
echo "  PROXIMOS PASOS:"
echo "    1. Coloca prod.keys en:  $DIR/keys/"
echo "    2. Coloca juegos en:     $DIR/input/"
echo "    3. Ejecuta:              python switch2ipa_gui.py"
echo "       O abre:               NSWPORTIOS.app"
echo ""
echo "  HERRAMIENTAS PARA FIRMAR E INSTALAR IPAs:"
echo "    TrollStore: https://github.com/opa334/TrollStore"
echo "    AltStore:   https://altstore.io/"
echo "    SideStore:  https://sidestore.io/"
echo "    Sideloadly: https://sideloadly.io/"
echo ""
echo "  Creditos:"
echo "    GitHub:    https://github.com/thebusk2"
echo "    Instagram: https://instagram.com/thebusk2"
echo "    X:         https://x.com/thebusk2"
echo "================================================================"
echo ""
