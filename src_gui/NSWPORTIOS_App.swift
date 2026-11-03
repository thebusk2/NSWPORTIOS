import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - Localización (5 Idiomas: ES, EN, FR, JA, RU)
enum AppLanguage: String, CaseIterable, Identifiable {
    case es = "es"
    case en = "en"
    case fr = "fr"
    case ja = "ja"
    case ru = "ru"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .es: return "🇪🇸 Español"
        case .en: return "🇺🇸 English"
        case .fr: return "🇫🇷 Français"
        case .ja: return "🇯🇵 日本語"
        case .ru: return "🇷🇺 Русский"
        }
    }
}

struct I18n {
    static func get(_ key: String, lang: AppLanguage) -> String {
        let dict: [String: [AppLanguage: String]] = [
            "subtitle": [
                .es: "Porteador Nativo de Switch a iOS • Metal 3.0 & ARM64",
                .en: "Switch to iOS Native Porter • Metal 3.0 & ARM64",
                .fr: "Porteur Natif Switch vers iOS • Metal 3.0 & ARM64",
                .ja: "Switch から iOS へのネイティブ移植 • Metal 3.0 & ARM64",
                .ru: "Нативный порт Switch на iOS • Metal 3.0 & ARM64"
            ],
            "open_input": [
                .es: "Abrir Input", .en: "Open Input", .fr: "Ouvrir Input", .ja: "Input を開く", .ru: "Открыть Input"
            ],
            "open_output": [
                .es: "Abrir Output", .en: "Open Output", .fr: "Ouvrir Output", .ja: "Output を開く", .ru: "Открыть Output"
            ],
            "credits_btn": [
                .es: "Créditos", .en: "Credits", .fr: "Crédits", .ja: "クレジット", .ru: "Создатели"
            ],
            "card_game_title": [
                .es: "JUEGO DE NINTENDO SWITCH", .en: "NINTENDO SWITCH GAME", .fr: "JEU NINTENDO SWITCH",
                .ja: "NINTENDO SWITCH ゲーム", .ru: "ИГРА NINTENDO SWITCH"
            ],
            "no_game_selected": [
                .es: "Ningún juego seleccionado", .en: "No game selected", .fr: "Aucun jeu sélectionné",
                .ja: "ゲームが選択されていません", .ru: "Игра не выбрана"
            ],
            "formats_hint": [
                .es: "Formatos admitidos: .nsp, .xci, .nsz, .xcz",
                .en: "Supported formats: .nsp, .xci, .nsz, .xcz",
                .fr: "Formats pris en charge : .nsp, .xci, .nsz, .xcz",
                .ja: "対応フォーマット: .nsp, .xci, .nsz, .xcz",
                .ru: "Поддерживаемые форматы: .nsp, .xci, .nsz, .xcz"
            ],
            "browse": [
                .es: "Examinar...", .en: "Browse...", .fr: "Parcourir...", .ja: "参照...", .ru: "Обзор..."
            ],
            "card_keys_title": [
                .es: "LLAVES DE DESENCRIPTADO (PROD.KEYS)", .en: "DECRYPTION KEYS (PROD.KEYS)",
                .fr: "CLÉS DE DÉCHIFFREMENT (PROD.KEYS)", .ja: "復号キー (PROD.KEYS)", .ru: "КЛЮЧИ ДЕШИФРОВАНИЯ (PROD.KEYS)"
            ],
            "keys_detected": [
                .es: "Detectadas", .en: "Detected", .fr: "Détectées", .ja: "検出済み", .ru: "Обнаружены"
            ],
            "keys_missing": [
                .es: "No encontrada", .en: "Missing", .fr: "Introuvable", .ja: "未検出", .ru: "Не найдены"
            ],
            "keys_hint": [
                .es: "Copia 'prod.keys' en la carpeta keys/ o selecciona el archivo",
                .en: "Copy 'prod.keys' into keys/ folder or select the file",
                .fr: "Copiez 'prod.keys' dans le dossier keys/ ou sélectionnez le fichier",
                .ja: "'prod.keys' を keys/ フォルダにコピーするか、ファイルを選択してください",
                .ru: "Скопируйте 'prod.keys' в папку keys/ или выберите файл"
            ],
            "load_keys": [
                .es: "Cargar Keys", .en: "Load Keys", .fr: "Charger clés", .ja: "キー読み込み", .ru: "Загрузить ключи"
            ],
            "card_settings_title": [
                .es: "AJUSTES DE COMPILACIÓN", .en: "BUILD SETTINGS", .fr: "PARAMÈTRES DE COMPILATION",
                .ja: "ビルド設定", .ru: "ПАРАМЕТРЫ СБОРКИ"
            ],
            "lbl_game_lang": [
                .es: "Idioma del juego:", .en: "Game Language:", .fr: "Langue du jeu :",
                .ja: "ゲーム言語:", .ru: "Язык игры:"
            ],
            "lbl_platform": [
                .es: "Destino:", .en: "Target:", .fr: "Cible :", .ja: "ターゲット:", .ru: "Назначение:"
            ],
            "lbl_romfs": [
                .es: "RomFS Assets:", .en: "RomFS Assets:", .fr: "Fichiers RomFS :", .ja: "RomFS アセット:", .ru: "Ресурсы RomFS:"
            ],
            "romfs_bundle": [
                .es: "📦 Integrado en IPA", .en: "📦 Bundled in IPA", .fr: "📦 Intégré dans l'IPA",
                .ja: "📦 IPA 内に同梱", .ru: "📦 Встроен в IPA"
            ],
            "romfs_separate": [
                .es: "🔌 Separado (>15GB)", .en: "🔌 Separate (>15GB)", .fr: "🔌 Séparé (>15 Go)",
                .ja: "🔌 分割 (>15GB)", .ru: "🔌 Отдельно (>15 ГБ)"
            ],
            "fps_toggle": [
                .es: "Mostrar contador de FPS en pantalla", .en: "Show on-screen FPS counter",
                .fr: "Afficher le compteur de FPS à l'écran", .ja: "画面上に FPS カウンターを表示",
                .ru: "Показывать счетчик FPS на экране"
            ],
            "console_title": [
                .es: "CONSOLA DE PROGRESO", .en: "PROGRESS CONSOLE", .fr: "CONSOLE DE PROGRESSION",
                .ja: "進行状況コンソール", .ru: "КОНСОЛЬ ВЫПОЛНЕНИЯ"
            ],
            "ready_to_compile": [
                .es: "Listo para compilar", .en: "Ready to build", .fr: "Prêt pour la compilation",
                .ja: "ビルド準備完了", .ru: "Готов к сборке"
            ],
            "waiting_command": [
                .es: "Esperando orden de compilación...", .en: "Waiting for build command...",
                .fr: "En attente de la commande de compilation...", .ja: "ビルドコマンド待機中...",
                .ru: "Ожидание команды сборки..."
            ],
            "btn_compile": [
                .es: "COMPILAR A .IPA DE iOS", .en: "BUILD iOS .IPA", .fr: "COMPILER EN .IPA iOS",
                .ja: "iOS .IPA をビルド", .ru: "СОБРАТЬ iOS .IPA"
            ],
            "btn_cancel": [
                .es: "CANCELAR", .en: "CANCEL", .fr: "ANNULER", .ja: "キャンセル", .ru: "ОТМЕНА"
            ]
        ]
        return dict[key]?[lang] ?? dict[key]?[.es] ?? key
    }
}

// MARK: - Paleta de Colores Nintendo Switch
struct SwitchTheme {
    static let joyConBlue = Color(red: 0.0, green: 0.74, blue: 0.95) // #00BDE6
    static let joyConRed = Color(red: 1.0, green: 0.24, blue: 0.20)  // #FF3C28
    static let bgDark = Color(red: 0.12, green: 0.12, blue: 0.13)    // #1F1F21
    static let cardBg = Color(red: 0.18, green: 0.18, blue: 0.20)    // #2E2E33
    static let cardBorder = Color(red: 0.26, green: 0.26, blue: 0.28)// #424247
    static let textMain = Color.white
    static let textDim = Color(white: 0.65)
    static let successGreen = Color(red: 0.20, green: 0.82, blue: 0.38)
}

// MARK: - Modelo de Estado Principal
class AppState: ObservableObject {
    @Published var appLanguage: AppLanguage = .es
    
    @Published var selectedGamePath: String = ""
    @Published var selectedGameName: String = "Ningún juego seleccionado"
    @Published var selectedGameSize: String = ""
    @Published var selectedGameFormat: String = ""
    
    @Published var keysPath: String = ""
    @Published var isKeysValid: Bool = false
    
    @Published var gameLanguage: String = "es"
    @Published var showFps: Bool = true
    @Published var platform: String = "ios"
    @Published var romfsMode: String = "bundle"
    
    @Published var isCompiling: Bool = false
    @Published var progressMessage: String = "Listo para compilar"
    @Published var logs: String = ""
    @Published var showCreditsModal: Bool = false
    
    private var process: Process?
    let baseDir: URL
    
    init() {
        let appBundleURL = Bundle.main.bundleURL
        let possibleBase = appBundleURL.deletingLastPathComponent()
        if FileManager.default.fileExists(atPath: possibleBase.appendingPathComponent("core").path) {
            self.baseDir = possibleBase
        } else if FileManager.default.fileExists(atPath: "/Volumes/Untitled/NSWPORTIOS/core") {
            self.baseDir = URL(fileURLWithPath: "/Volumes/Untitled/NSWPORTIOS")
        } else {
            self.baseDir = possibleBase
        }
        
        detectKeys()
        detectGameInInput()
    }
    
    func tr(_ key: String) -> String {
        return I18n.get(key, lang: appLanguage)
    }
    
    func detectKeys() {
        let candidates = [
            baseDir.appendingPathComponent("keys/prod.keys").path,
            baseDir.appendingPathComponent("keys/keys.txt").path,
            NSHomeDirectory() + "/.switch/prod.keys",
            NSHomeDirectory() + "/.config/yuzu/keys/prod.keys",
            NSHomeDirectory() + "/.config/Ryujinx/system/prod.keys",
            NSHomeDirectory() + "/Library/Application Support/Ryujinx/system/prod.keys"
        ]
        
        for cand in candidates {
            if FileManager.default.fileExists(atPath: cand) {
                self.keysPath = cand
                self.isKeysValid = true
                return
            }
        }
        
        let keysDir = baseDir.appendingPathComponent("keys")
        if let files = try? FileManager.default.contentsOfDirectory(atPath: keysDir.path) {
            for f in files where f.hasSuffix(".keys") && !f.hasPrefix("._") {
                self.keysPath = keysDir.appendingPathComponent(f).path
                self.isKeysValid = true
                return
            }
        }
        
        self.keysPath = ""
        self.isKeysValid = false
    }
    
    func detectGameInInput() {
        let inputDir = baseDir.appendingPathComponent("input")
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: inputDir.path) else { return }
        
        let validExts = [".nsp", ".xci", ".nsz", ".xcz"]
        for f in files where !f.hasPrefix("._") {
            let lower = f.lowercased()
            if validExts.contains(where: { lower.hasSuffix($0) }) {
                let fullPath = inputDir.appendingPathComponent(f).path
                selectGame(path: fullPath)
                return
            }
        }
    }
    
    func selectGame(path: String) {
        let url = URL(fileURLWithPath: path)
        self.selectedGamePath = path
        self.selectedGameName = url.lastPathComponent
        self.selectedGameFormat = url.pathExtension.uppercased()
        
        if let attrs = try? FileManager.default.attributesOfItem(atPath: path),
           let size = attrs[.size] as? Int64 {
            let mb = Double(size) / (1024 * 1024)
            if mb > 1024 {
                self.selectedGameSize = String(format: "%.2f GB", mb / 1024)
            } else {
                self.selectedGameSize = String(format: "%.1f MB", mb)
            }
        } else {
            self.selectedGameSize = ""
        }
    }
    
    func pickGameFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        let exts = ["nsp", "xci", "nsz", "xcz"]
        panel.allowedContentTypes = exts.compactMap { UTType(filenameExtension: $0) }
        panel.message = tr("card_game_title")
        panel.prompt = tr("browse")
        
        if panel.runModal() == .OK, let url = panel.url {
            selectGame(path: url.path)
        }
    }
    
    func pickKeysFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        let keyExts = ["keys", "txt"]
        panel.allowedContentTypes = keyExts.compactMap { UTType(filenameExtension: $0) }
        panel.message = tr("card_keys_title")
        panel.prompt = tr("load_keys")
        
        if panel.runModal() == .OK, let url = panel.url {
            self.keysPath = url.path
            self.isKeysValid = true
        }
    }
    
    func openFolder(url: URL) {
        NSWorkspace.shared.open(url)
    }
    
    func openURL(_ str: String) {
        if let url = URL(string: str) {
            NSWorkspace.shared.open(url)
        }
    }
    
    func startCompilation() {
        guard !selectedGamePath.isEmpty else {
            logs += "[!] " + tr("no_game_selected") + "\n"
            return
        }
        guard isKeysValid && !keysPath.isEmpty else {
            logs += "[!] " + tr("keys_hint") + "\n"
            return
        }
        
        isCompiling = true
        progressMessage = "Preparando pipeline de compilación..."
        logs = "=== INICIANDO NSWPORTIOS COMPILER ===\n"
        logs += "Juego: \(selectedGameName)\n"
        logs += "Formato: \(selectedGameFormat) | Tamaño: \(selectedGameSize)\n"
        logs += "Keys: \(keysPath)\n"
        logs += "Plataforma: \(platform.uppercased()) | Idioma: \(gameLanguage)\n"
        logs += "RomFS: \(romfsMode) | FPS Overlay: \(showFps ? "Activado" : "Desactivado")\n"
        logs += "--------------------------------------------------------\n"
        
        let pyScript = baseDir.appendingPathComponent("switch2ipa.py").path
        let inputArg = selectedGamePath
        
        var args = [pyScript, "-i", inputArg, "-k", keysPath, "-l", gameLanguage, "--platform", platform, "--romfs", romfsMode]
        if showFps { args.append("--fps") } else { args.append("--no-fps") }
        
        let proc = Process()
        let venvPy = NSHomeDirectory() + "/.nswportios_venv/bin/python3"
        if FileManager.default.fileExists(atPath: venvPy) {
            proc.executableURL = URL(fileURLWithPath: venvPy)
        } else {
            proc.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        }
        proc.arguments = args
        proc.currentDirectoryURL = baseDir
        
        var env = ProcessInfo.processInfo.environment
        let extraPaths = [NSHomeDirectory() + "/.local/bin", NSHomeDirectory() + "/.dotnet", "/opt/homebrew/bin", "/usr/local/bin"]
        env["PATH"] = extraPaths.joined(separator: ":") + ":" + (env["PATH"] ?? "")
        env["DOTNET_ROOT"] = NSHomeDirectory() + "/.dotnet"
        proc.environment = env
        
        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = pipe
        self.process = proc
        
        let outHandle = pipe.fileHandleForReading
        outHandle.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if !data.isEmpty, let str = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self?.logs += str
                    if str.contains("build ID lookup") || str.contains("survey") {
                        self?.progressMessage = "Analizando juego y generando perfil..."
                    } else if str.contains("extract") || str.contains("Extracting") {
                        self?.progressMessage = "Extrayendo contenido del juego..."
                    } else if str.contains("rewrite") || str.contains("patch_nso") || str.contains("Rebuilding") {
                        self?.progressMessage = "Reescribiendo binarios ARM64 (x18 & SVC)..."
                    } else if str.contains("heap_check") || str.contains("region_check") {
                        self?.progressMessage = "Verificando memoria y regiones..."
                    } else if str.contains("shader_split") || str.contains("shader split") {
                        self?.progressMessage = "Dividiendo y analizando shaders..."
                    } else if str.contains("translating shaders") || str.contains("Metal") || str.contains("build_shaders") {
                        self?.progressMessage = "Transpilando shaders Maxwell a Metal 3.0..."
                    } else if str.contains("xcodebuild") || str.contains("Compiling") || str.contains("build_ipa") {
                        self?.progressMessage = "Compilando Host HLE para iOS..."
                    } else if str.contains("Packing") || str.contains("IPA") || str.contains("pack_ipa") {
                        self?.progressMessage = "Empaquetando archivo .IPA..."
                    } else if str.contains("[RED]") || str.contains("ERROR") {
                        self?.progressMessage = "⚠️ Problema detectado..."
                    }
                }
            }
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                try proc.run()
                proc.waitUntilExit()
                
                DispatchQueue.main.async {
                    self?.isCompiling = false
                    if proc.terminationStatus == 0 {
                        self?.progressMessage = "¡Compilación exitosa! .IPA generado en output."
                        self?.logs += "\n[✓] PROCESO TERMINADO CON ÉXITO.\n"
                    } else {
                        self?.progressMessage = "La compilación finalizó con errores (\(proc.terminationStatus))."
                        self?.logs += "\n[!] ERROR EN LA COMPILACIÓN.\n"
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self?.isCompiling = false
                    self?.progressMessage = "Error: \(error.localizedDescription)"
                    self?.logs += "\n[!] Error: \(error.localizedDescription)\n"
                }
            }
        }
    }
    
    func cancelCompilation() {
        process?.terminate()
        isCompiling = false
        progressMessage = "Compilación cancelada por el usuario."
        logs += "\n[!] Compilación cancelada.\n"
    }
}

// MARK: - Modal de Créditos y Redes Sociales
struct CreditsView: View {
    @ObservedObject var state: AppState
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 18) {
            // Cabecera modal
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(SwitchTheme.joyConRed)
                    Text("CRÉDITOS Y FUENTES")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundColor(SwitchTheme.textMain)
                }
                Spacer()
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(SwitchTheme.textDim)
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 6)
            
            Divider().background(SwitchTheme.cardBorder)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Creador & Redes Sociales
                    VStack(alignment: .leading, spacing: 10) {
                        Text("DESARROLLADOR / AUTOR")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(SwitchTheme.joyConBlue)
                        
                        Text("thebusk2")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(SwitchTheme.textMain)
                        
                        Text("Sígueme y apoya el proyecto en mis redes sociales:")
                            .font(.system(size: 12))
                            .foregroundColor(SwitchTheme.textDim)
                        
                        HStack(spacing: 12) {
                            Button(action: { state.openURL("https://github.com/thebusk2") }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                                    Text("GitHub")
                                }
                            }
                            .buttonStyle(SocialButtonStyle(bg: Color(red: 0.15, green: 0.15, blue: 0.17)))
                            
                            Button(action: { state.openURL("https://www.instagram.com/thebusk2/") }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "camera.fill")
                                    Text("Instagram")
                                }
                            }
                            .buttonStyle(SocialButtonStyle(bg: Color(red: 0.75, green: 0.15, blue: 0.45)))
                            
                            Button(action: { state.openURL("https://x.com/thebusk2") }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "bubble.left.fill")
                                    Text("X (Twitter)")
                                }
                            }
                            .buttonStyle(SocialButtonStyle(bg: Color(red: 0.10, green: 0.10, blue: 0.12)))
                        }
                    }
                    .padding(14)
                    .background(SwitchTheme.cardBg)
                    .cornerRadius(10)
                    
                    // Fuentes y Proyectos de Referencia
                    VStack(alignment: .leading, spacing: 10) {
                        Text("FUENTES Y AGRADECIMIENTOS TÉCNICOS")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(SwitchTheme.joyConRed)
                        
                        CreditRow(title: "seedds / nxnative", desc: "NSO rewriter, Horizon HLE host y pipeline NVN-a-Metal", url: "https://github.com/seedds/nxnative", state: state)
                        CreditRow(title: "Thealexbarney / LibHac", desc: "Biblioteca maestra de desencriptación y sistemas de archivos NSP, XCI y RomFS", url: "https://github.com/Thealexbarney/LibHac", state: state)
                        CreditRow(title: "jhaizhou-ops / d2r-mobile", desc: "Pionero en la ejecución nativa de juegos de Switch en iOS vía Metal/Vulkan", url: "https://github.com/jhaizhou-ops/d2r-mobile", state: state)
                        CreditRow(title: "Ryujinx Team", desc: "Transpilador de shaders NVIDIA Maxwell a SPIR-V", url: "https://github.com/Ryujinx/Ryujinx", state: state)
                        CreditRow(title: "Atmosphère-NX", desc: "Kernel Mesosphère, sincronización y semántica del SO Horizon", url: "https://github.com/Atmosphere-NX/Atmosphere", state: state)
                        CreditRow(title: "switchbrew / switch-tools", desc: "Herramientas de ingeniería inversa para binarios NSO y metadatos NPDM", url: "https://github.com/switchbrew/switch-tools", state: state)
                        CreditRow(title: "Nico Bosshard / nsz", desc: "Algoritmo de descompresión de contenedores NSZ y XCZ", url: "https://github.com/nicoboss/nsz", state: state)
                    }
                    .padding(14)
                    .background(SwitchTheme.cardBg)
                    .cornerRadius(10)
                }
            }
        }
        .padding(22)
        .frame(width: 580, height: 520)
        .background(SwitchTheme.bgDark)
    }
}

struct CreditRow: View {
    let title: String
    let desc: String
    let url: String
    let state: AppState
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(SwitchTheme.textMain)
                Text(desc)
                    .font(.system(size: 11))
                    .foregroundColor(SwitchTheme.textDim)
            }
            Spacer()
            Button(action: { state.openURL(url) }) {
                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 14))
                    .foregroundColor(SwitchTheme.joyConBlue)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 3)
    }
}

struct SocialButtonStyle: ButtonStyle {
    var bg: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 6).fill(bg))
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
    }
}

// MARK: - Vista Principal
struct ContentView: View {
    @StateObject var state = AppState()
    
    var body: some View {
        HStack(spacing: 0) {
            // JOY-CON IZQUIERDO (Banda Azul Neón)
            VStack(spacing: 20) {
                Circle()
                    .fill(Color.black.opacity(0.4))
                    .frame(width: 48, height: 48)
                    .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 2))
                    .shadow(radius: 2)
                    .padding(.top, 25)
                
                VStack(spacing: 8) {
                    Circle().fill(Color.black.opacity(0.5)).frame(width: 22, height: 22)
                        .overlay(Image(systemName: "arrowtriangle.up.fill").font(.system(size: 9)).foregroundColor(.white))
                    HStack(spacing: 12) {
                        Circle().fill(Color.black.opacity(0.5)).frame(width: 22, height: 22)
                            .overlay(Image(systemName: "arrowtriangle.left.fill").font(.system(size: 9)).foregroundColor(.white))
                        Circle().fill(Color.black.opacity(0.5)).frame(width: 22, height: 22)
                            .overlay(Image(systemName: "arrowtriangle.right.fill").font(.system(size: 9)).foregroundColor(.white))
                    }
                    Circle().fill(Color.black.opacity(0.5)).frame(width: 22, height: 22)
                        .overlay(Image(systemName: "arrowtriangle.down.fill").font(.system(size: 9)).foregroundColor(.white))
                }
                
                Spacer()
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.black.opacity(0.4))
                    .frame(width: 24, height: 24)
                    .overlay(Circle().fill(Color.white.opacity(0.4)).frame(width: 12, height: 12))
                    .padding(.bottom, 25)
            }
            .frame(width: 60)
            .background(SwitchTheme.joyConBlue)
            
            // PANTALLA CENTRAL DE LA CONSOLA
            VStack(spacing: 0) {
                // Header
                HStack {
                    HStack(spacing: 12) {
                        Image(systemName: "gamecontroller.fill")
                            .font(.system(size: 26))
                            .foregroundColor(SwitchTheme.joyConBlue)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("NSWPORTIOS")
                                .font(.system(size: 20, weight: .black, design: .rounded))
                                .foregroundColor(SwitchTheme.textMain)
                            Text(state.tr("subtitle"))
                                .font(.system(size: 11))
                                .foregroundColor(SwitchTheme.textDim)
                        }
                    }
                    
                    Spacer()
                    
                    // Selector de Idioma de la App + Botones
                    HStack(spacing: 8) {
                        Picker("", selection: $state.appLanguage) {
                            ForEach(AppLanguage.allCases) { lang in
                                Text(lang.displayName).tag(lang)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 130)
                        
                        Button(action: { state.openFolder(url: state.baseDir.appendingPathComponent("input")) }) {
                            Label(state.tr("open_input"), systemImage: "tray.and.arrow.down.fill")
                        }
                        .buttonStyle(SwitchSecondaryButtonStyle())
                        
                        Button(action: { state.openFolder(url: state.baseDir.appendingPathComponent("output")) }) {
                            Label(state.tr("open_output"), systemImage: "folder.fill")
                        }
                        .buttonStyle(SwitchSecondaryButtonStyle())
                        
                        Button(action: { state.showCreditsModal = true }) {
                            HStack(spacing: 4) {
                                Image(systemName: "heart.fill").foregroundColor(SwitchTheme.joyConRed)
                                Text(state.tr("credits_btn"))
                            }
                        }
                        .buttonStyle(SwitchSecondaryButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(SwitchTheme.cardBg)
                
                Divider().background(SwitchTheme.cardBorder)
                
                // Contenido
                ScrollView {
                    VStack(spacing: 16) {
                        
                        // Panel 1: Juego Seleccionado
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Label(state.tr("card_game_title"), systemImage: "opticaldisc.fill")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(SwitchTheme.joyConBlue)
                                Spacer()
                                if !state.selectedGameFormat.isEmpty {
                                    Text(state.selectedGameFormat)
                                        .font(.system(size: 11, weight: .bold))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(SwitchTheme.joyConBlue.opacity(0.2))
                                        .foregroundColor(SwitchTheme.joyConBlue)
                                        .cornerRadius(6)
                                }
                            }
                            
                            HStack(spacing: 14) {
                                Image(systemName: "gamecontroller")
                                    .font(.system(size: 32))
                                    .foregroundColor(state.selectedGamePath.isEmpty ? SwitchTheme.textDim : SwitchTheme.joyConBlue)
                                    .frame(width: 50, height: 50)
                                    .background(Color.black.opacity(0.3))
                                    .cornerRadius(8)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(state.selectedGamePath.isEmpty ? state.tr("no_game_selected") : state.selectedGameName)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(SwitchTheme.textMain)
                                        .lineLimit(1)
                                    
                                    if !state.selectedGamePath.isEmpty {
                                        Text("\(state.selectedGameSize) • \(state.selectedGamePath)")
                                            .font(.system(size: 11))
                                            .foregroundColor(SwitchTheme.textDim)
                                            .lineLimit(1)
                                    } else {
                                        Text(state.tr("formats_hint"))
                                            .font(.system(size: 11))
                                            .foregroundColor(SwitchTheme.textDim)
                                    }
                                }
                                
                                Spacer()
                                
                                Button(action: { state.pickGameFile() }) {
                                    Label(state.tr("browse"), systemImage: "magnifyingglass")
                                }
                                .buttonStyle(SwitchPrimaryButtonStyle(color: SwitchTheme.joyConBlue))
                            }
                        }
                        .padding(14)
                        .background(SwitchTheme.cardBg)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(SwitchTheme.cardBorder, lineWidth: 1))
                        
                        // Panel 2: Llaves prod.keys
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Label(state.tr("card_keys_title"), systemImage: "key.fill")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(SwitchTheme.joyConRed)
                                Spacer()
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(state.isKeysValid ? SwitchTheme.successGreen : SwitchTheme.joyConRed)
                                        .frame(width: 8, height: 8)
                                    Text(state.isKeysValid ? state.tr("keys_detected") : state.tr("keys_missing"))
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(state.isKeysValid ? SwitchTheme.successGreen : SwitchTheme.joyConRed)
                                }
                            }
                            
                            HStack {
                                Text(state.isKeysValid ? state.keysPath : state.tr("keys_hint"))
                                    .font(.system(size: 11))
                                    .foregroundColor(state.isKeysValid ? SwitchTheme.textMain : SwitchTheme.textDim)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Button(action: { state.pickKeysFile() }) {
                                    Text(state.tr("load_keys"))
                                }
                                .buttonStyle(SwitchSecondaryButtonStyle())
                            }
                        }
                        .padding(14)
                        .background(SwitchTheme.cardBg)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(SwitchTheme.cardBorder, lineWidth: 1))
                        
                        // Panel 3: Opciones y Ajustes
                        VStack(alignment: .leading, spacing: 14) {
                            Label(state.tr("card_settings_title"), systemImage: "slider.horizontal.3")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(SwitchTheme.textMain)
                            
                            Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 14) {
                                GridRow {
                                    Text(state.tr("lbl_game_lang"))
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(SwitchTheme.textDim)
                                    
                                    Picker("", selection: $state.gameLanguage) {
                                        Text("Español (es)").tag("es")
                                        Text("Español Latino (es-419)").tag("es-419")
                                        Text("English (en)").tag("en")
                                        Text("Français (fr)").tag("fr")
                                        Text("Deutsch (de)").tag("de")
                                        Text("日本語 (ja)").tag("ja")
                                        Text("Русский (ru)").tag("ru")
                                    }
                                    .pickerStyle(.menu)
                                    .frame(width: 200)
                                }
                                
                                GridRow {
                                    Text(state.tr("lbl_platform"))
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(SwitchTheme.textDim)
                                    
                                    Picker("", selection: $state.platform) {
                                        Text("📱 iPhone / iPad (.IPA)").tag("ios")
                                        Text("💻 Mac Nativo (.app)").tag("mac-app")
                                    }
                                    .pickerStyle(.segmented)
                                    .frame(width: 250)
                                }
                                
                                GridRow {
                                    Text(state.tr("lbl_romfs"))
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(SwitchTheme.textDim)
                                    
                                    Picker("", selection: $state.romfsMode) {
                                        Text(state.tr("romfs_bundle")).tag("bundle")
                                        Text(state.tr("romfs_separate")).tag("separate")
                                    }
                                    .pickerStyle(.segmented)
                                    .frame(width: 250)
                                }
                                
                                GridRow {
                                    Text("FPS Overlay:")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(SwitchTheme.textDim)
                                    
                                    Toggle(isOn: $state.showFps) {
                                        Text(state.tr("fps_toggle"))
                                            .font(.system(size: 12))
                                            .foregroundColor(SwitchTheme.textMain)
                                    }
                                    .toggleStyle(.checkbox)
                                }
                            }
                        }
                        .padding(14)
                        .background(SwitchTheme.cardBg)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(SwitchTheme.cardBorder, lineWidth: 1))
                        
                        // Panel 4: Consola de Salida
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label(state.tr("console_title"), systemImage: "terminal.fill")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(SwitchTheme.textDim)
                                Spacer()
                                Text(state.progressMessage)
                                    .font(.system(size: 11))
                                    .foregroundColor(SwitchTheme.joyConBlue)
                            }
                            
                            ScrollViewReader { proxy in
                                ScrollView {
                                    Text(state.logs.isEmpty ? state.tr("waiting_command") : state.logs)
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(Color.green.opacity(0.85))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .id("logBottom")
                                }
                                .frame(height: 140)
                                .padding(10)
                                .background(Color.black.opacity(0.75))
                                .cornerRadius(8)
                                .onChange(of: state.logs) { _, _ in
                                    proxy.scrollTo("logBottom", anchor: .bottom)
                                }
                            }
                        }
                        .padding(14)
                        .background(SwitchTheme.cardBg)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(SwitchTheme.cardBorder, lineWidth: 1))
                        
                        // BOTÓN DE ACCIÓN PRINCIPAL (Compilar)
                        HStack(spacing: 16) {
                            if state.isCompiling {
                                Button(action: { state.cancelCompilation() }) {
                                    Label(state.tr("btn_cancel"), systemImage: "xmark.circle.fill")
                                        .font(.system(size: 14, weight: .bold))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                }
                                .buttonStyle(SwitchPrimaryButtonStyle(color: Color.gray))
                            } else {
                                Button(action: { state.startCompilation() }) {
                                    HStack {
                                        Image(systemName: "play.circle.fill")
                                            .font(.system(size: 20))
                                        Text(state.tr("btn_compile"))
                                            .font(.system(size: 15, weight: .black, design: .rounded))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                }
                                .buttonStyle(SwitchPrimaryButtonStyle(color: SwitchTheme.joyConRed))
                                .disabled(state.selectedGamePath.isEmpty || !state.isKeysValid)
                            }
                        }
                        .padding(.top, 4)
                        .padding(.bottom, 20)
                    }
                    .padding(20)
                }
            }
            .background(SwitchTheme.bgDark)
            
            // JOY-CON DERECHO (Banda Roja Neón)
            VStack(spacing: 20) {
                Text("+")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color.black.opacity(0.4))
                    .padding(.top, 16)
                
                VStack(spacing: 8) {
                    Circle().fill(Color.black.opacity(0.5)).frame(width: 22, height: 22)
                        .overlay(Text("X").font(.system(size: 10, weight: .bold)).foregroundColor(.white))
                    HStack(spacing: 12) {
                        Circle().fill(Color.black.opacity(0.5)).frame(width: 22, height: 22)
                            .overlay(Text("Y").font(.system(size: 10, weight: .bold)).foregroundColor(.white))
                        Circle().fill(Color.black.opacity(0.5)).frame(width: 22, height: 22)
                            .overlay(Text("A").font(.system(size: 10, weight: .bold)).foregroundColor(.white))
                    }
                    Circle().fill(Color.black.opacity(0.5)).frame(width: 22, height: 22)
                        .overlay(Text("B").font(.system(size: 10, weight: .bold)).foregroundColor(.white))
                }
                
                Spacer()
                
                Circle()
                    .fill(Color.black.opacity(0.4))
                    .frame(width: 48, height: 48)
                    .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 2))
                    .shadow(radius: 2)
                
                Circle()
                    .fill(Color.black.opacity(0.4))
                    .frame(width: 24, height: 24)
                    .overlay(Image(systemName: "house.fill").font(.system(size: 10)).foregroundColor(.white.opacity(0.7)))
                    .padding(.bottom, 25)
            }
            .frame(width: 60)
            .background(SwitchTheme.joyConRed)
        }
        .frame(minWidth: 880, minHeight: 700)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $state.showCreditsModal) {
            CreditsView(state: state)
        }
    }
}

// MARK: - Estilos de Botones Personalizados Switch
struct SwitchPrimaryButtonStyle: ButtonStyle {
    var color: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(configuration.isPressed ? 0.8 : 1.0))
            )
            .shadow(color: color.opacity(0.4), radius: configuration.isPressed ? 1 : 4, y: 2)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

struct SwitchSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(SwitchTheme.textMain)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(SwitchTheme.cardBorder.opacity(configuration.isPressed ? 0.5 : 1.0))
            )
    }
}

// MARK: - Punto de Entrada de la App
@main
struct NSWPORTIOS_App: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 900, height: 720)
    }
}
