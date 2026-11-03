<div align="center">

# 🎮 NSWPORTIOS
### Universal Nintendo Switch to iOS (.IPA) Native Porter & Compiler

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20iPadOS%20%7C%20macOS-lightgrey.svg)](https://apple.com)
[![Architecture](https://img.shields.io/badge/Architecture-ARM64%20(aarch64)-orange.svg)]()
[![Graphics](https://img.shields.io/badge/Graphics-Apple%20Metal-brightgreen.svg)]()

**NSWPORTIOS** es una suite gráfica y de línea de comandos para recompilar y portear juegos de **Nintendo Switch** directamente a **iOS / iPadOS (.IPA)** de forma nativa, sin emulación pesada y sin JIT.

---

### 🌐 Redes Sociales del Desarrollador
Desarrollado y mantenido por **thebusk2**:
- 🐙 **GitHub:** [@thebusk2](https://github.com/thebusk2)
- 📸 **Instagram:** [@thebusk2](https://www.instagram.com/thebusk2/)
- 🐦 **X (Twitter):** [@thebusk2](https://x.com/thebusk2)

---

### 📥 Descargas
| Plataforma | Archivo | Descripción |
| :--- | :--- | :--- |
| 🍏 **macOS** | [**`NSWPORTIOS_macOS.dmg`**](https://github.com/thebusk2/NSWPORTIOS/releases/latest/download/NSWPORTIOS_macOS.dmg) | App nativa para macOS |
| 🪟 **Windows** | [**`NSWPORTIOS_Windows.zip`**](https://github.com/thebusk2/NSWPORTIOS/releases/latest/download/NSWPORTIOS_Windows.zip) | ZIP con instalador automático |

</div>

---

## ✨ Características Principales

- 🚀 **Ejecución Nativa ARM64** — El código del juego se ejecuta directamente en la CPU Apple Silicon / A-series, sin emulación
- 🎨 **Interfaz Visual Nintendo Switch** — Estética Joy-Con azul (#00BDE6) y rojo (#FF3C28)
- 🌍 **5 Idiomas** — Español, English, Français, 日本語, Русский
- 📦 **Formatos compatibles** — `.nsp`, `.xci`, `.nsz`, `.xcz` con detección automática
- 🎮 **Soporte de Mandos iOS** — Pro Controller, Joy-Cons, DualSense, Xbox, MFi
- ⚡ **Shaders AOT** — Compilados antes de jugar para evitar stuttering

---

## 📥 Instalación

### 🍏 En macOS (Instalación Automática)

```bash
# Opción 1: Instalador automático (recomendado)
bash setup.sh

# Opción 2: Abrir la app directamente
open NSWPORTIOS.app
```

El instalador `setup.sh` instala automáticamente:
- ✅ Python 3.12 (via uv)
- ✅ .NET SDK
- ✅ xcodegen, zstd, glslang
- ✅ Dependencias Python (nsz, capstone, lz4, etc.)
- ✅ Motor nxnative

**Requisito previo:** [Xcode](https://apps.apple.com/us/app/xcode/id497799835) desde la Mac App Store (gratis).

---

### 🪟 En Windows (Instalación Automática)

1. Descarga y extrae **`NSWPORTIOS_Windows.zip`**
2. Doble clic en **`install_windows.bat`**

El instalador instala automáticamente:
- ✅ Python 3.12 (via winget o descarga directa)
- ✅ Git (via winget o descarga directa)
- ✅ Dependencias Python (nsz, capstone, lz4, etc.)
- ✅ Motor nxnative

> **Nota:** Si Windows Defender bloquea el .bat, haz clic derecho → "Ejecutar como administrador" o desactiva temporalmente la protección en tiempo real.

---

## 🕹️ Uso

1. Abre **`NSWPORTIOS.app`** (macOS) o ejecuta **`NSWPORTIOS.bat`** (Windows)
2. Haz clic en **"Examinar..."** y selecciona tu juego (`.nsp`, `.xci`, `.nsz`, `.xcz`)
3. Haz clic en **"Cargar Keys"** y selecciona tu archivo `prod.keys`
4. Haz clic en **"🚀 COMPILAR A .IPA"**
5. El archivo `.ipa` se guardará en la carpeta `output/`

---

## 📱 Instalar la IPA en iPhone / iPad

Las IPAs generadas necesitan ser **firmadas** antes de instalarlas. Usa una de estas herramientas:

### Método 1: TrollStore ⭐ (Recomendado — Permanente)
**Sin límite de 7 días, sin cuenta Apple Developer**

| | |
|---|---|
| 🔗 **Descarga** | https://github.com/opa334/TrollStore |
| 📱 **Compatible** | iOS 14.0 – 17.0 (ver tabla de compatibilidad) |
| ✅ **Ventaja** | Instalación permanente, sin revocaciones |
| ❌ **Limitación** | No disponible en iOS 17.4+ (por ahora) |

**Pasos:**
1. Instala TrollStore en tu dispositivo (sigue la guía en su GitHub)
2. Transfiere el `.ipa` a tu iPhone (AirDrop, cable, Files)
3. Abre el `.ipa` con TrollStore → "Install"

---

### Método 2: AltStore (Gratuito — 7 días)
**Requiere PC/Mac conectado para renovar cada 7 días**

| | |
|---|---|
| 🔗 **Descarga** | https://altstore.io/ |
| 💻 **Plataforma PC** | Windows y macOS |
| 📱 **Compatible** | Todas las versiones de iOS |
| ✅ **Ventaja** | Gratis con cuenta Apple ID normal |
| ❌ **Limitación** | Caduca cada 7 días, máximo 3 apps |

**Pasos:**
1. Instala AltServer en tu PC/Mac desde https://altstore.io/
2. Conecta tu iPhone por USB
3. Instala AltStore en el iPhone desde AltServer
4. Abre AltStore → "+" → selecciona el `.ipa`

---

### Método 3: SideStore (Gratuito — Sin PC)
**Alternativa inalámbrica a AltStore**

| | |
|---|---|
| 🔗 **Descarga** | https://sidestore.io/ |
| 📱 **Compatible** | iOS 14.0+ |
| ✅ **Ventaja** | No necesita PC conectado para renovar |
| ❌ **Limitación** | Caduca cada 7 días (se autorrenueva via Wi-Fi) |

**Pasos:**
1. Instala SideStore siguiendo su guía en https://sidestore.io/
2. Importa el `.ipa` desde Files o AirDrop
3. SideStore firma e instala automáticamente

---

### Método 4: Sideloadly (Gratuito — Windows/Mac)
**Interfaz gráfica fácil de usar**

| | |
|---|---|
| 🔗 **Descarga** | https://sideloadly.io/ |
| 💻 **Plataforma PC** | Windows 7+ y macOS 10.12+ |
| 📱 **Compatible** | Todas las versiones de iOS |
| ✅ **Ventaja** | Muy fácil de usar, interfaz visual |
| ❌ **Limitación** | Caduca cada 7 días, requiere iTunes |

**Pasos:**
1. Descarga e instala Sideloadly desde https://sideloadly.io/
2. Conecta tu iPhone por USB
3. Arrastra el `.ipa` a Sideloadly
4. Ingresa tu Apple ID → "Start"

---

### Comparativa Rápida

| Herramienta | Costo | Permanente | Requiere PC | iOS máx |
|-------------|-------|------------|-------------|---------|
| **TrollStore** | Gratis | ✅ Sí | ❌ No | ~17.0 |
| **AltStore** | Gratis | ❌ 7 días | ✅ Sí | Todas |
| **SideStore** | Gratis | ❌ 7 días | ❌ No | 14.0+ |
| **Sideloadly** | Gratis | ❌ 7 días | ✅ Sí | Todas |

> **Recomendación:** Si tu dispositivo es compatible, usa **TrollStore**. De lo contrario, usa **Sideloadly** (más simple) o **SideStore** (sin PC).

---

## 🏗️ Arquitectura del Pipeline

```
Juego Switch (.nsp/.xci/.nsz/.xcz)
        ↓
[1] Extracción y desencriptado (LibHac + prod.keys)
        ↓
[2] Reescritura NSO → ARM64 nativo (parcheo x18, SVCs)
        ↓
[3] Transpilación Shaders (Maxwell NVN → Metal MSL)
        ↓
[4] Compilación Xcode (target: arm64-apple-ios)
        ↓
[5] Empaquetado .IPA
        ↓
    📦 TheGame.ipa → Instalar con TrollStore/AltStore
```

---

## ❤️ Créditos y Referencias

| Proyecto | Descripción |
|----------|-------------|
| [seedds/nxnative](https://github.com/seedds/nxnative) | Motor NSO rewriter, HLE Horizon, backend NVN→Metal |
| [Thealexbarney/LibHac](https://github.com/Thealexbarney/LibHac) | Librería C# para NSP, XCI, NCAs |
| [jhaizhou-ops/d2r-mobile](https://github.com/jhaizhou-ops/d2r-mobile) | Proyecto pionero ejecución nativa en mobile |
| [nicoboss/nsz](https://github.com/nicoboss/nsz) | Compresión/descompresión NSZ y XCZ |
| [switchbrew/switch-tools](https://github.com/switchbrew/switch-tools) | Herramientas para binarios Nintendo Switch |
| [opa334/TrollStore](https://github.com/opa334/TrollStore) | Instalador permanente de IPA en iOS |
| [AltStore](https://altstore.io/) | Sideloading con Apple ID |
| [SideStore](https://sidestore.io/) | Sideloading inalámbrico |
| [Sideloadly](https://sideloadly.io/) | Interfaz gráfica para sideloading |

---

## ⚖️ Licencia

Distribuido bajo la Licencia **MIT**. Ver [LICENSE](LICENSE) para más información.
