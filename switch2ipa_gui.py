#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
NSWPORTIOS GUI (Python / Tkinter Edition)
Interfaz gráfica con estética Nintendo Switch para portear juegos a iOS.
Autor: thebusk2 (https://github.com/thebusk2)
"""

import os
import sys
import threading
import subprocess
import webbrowser
from pathlib import Path
import tkinter as tk
from tkinter import ttk, filedialog, messagebox

# Colores Nintendo Switch
COLOR_JOYCON_BLUE = "#00BDE6"
COLOR_JOYCON_RED = "#FF3C28"
COLOR_BG_DARK = "#1F1F21"
COLOR_CARD_BG = "#2E2E33"
COLOR_CARD_BORDER = "#424247"
COLOR_TEXT_MAIN = "#FFFFFF"
COLOR_TEXT_DIM = "#A0A0A5"
COLOR_SUCCESS = "#34C759"

# Diccionario de Internacionalización (5 idiomas: ES, EN, FR, JA, RU)
I18N = {
    "es": {
        "title": "NSWPORTIOS",
        "subtitle": "Porteador Nativo de Switch a iOS • Metal 3.0 & ARM64",
        "open_in": "📂 Abrir Input", "open_out": "📦 Abrir Output", "credits": "❤️ Créditos",
        "card_game": " 🎮 JUEGO DE NINTENDO SWITCH ", "no_game": "Ningún juego seleccionado",
        "formats_hint": "Formatos admitidos: .nsp, .xci, .nsz, .xcz", "browse": "Examinar...",
        "card_keys": " 🔑 LLAVES DE DESENCRIPTADO (PROD.KEYS) ",
        "keys_ok": "✓ Detectado:", "keys_err": "⚠️ 'prod.keys' no encontrado. Copia el archivo en 'keys/'",
        "load_keys": "Cargar Keys", "card_opts": " ⚙️ AJUSTES DE COMPILACIÓN ",
        "lbl_lang": "Idioma Juego:", "lbl_target": "Destino:", "lbl_romfs": "RomFS:",
        "romfs_bundle": "Integrado en IPA", "romfs_sep": "Separado (>15GB)",
        "fps_chk": "Mostrar FPS en pantalla", "card_log": " 📟 CONSOLA DE PROGRESO ",
        "status_ready": "Listo para compilar", "btn_compile": "🚀 COMPILAR A .IPA DE iOS",
        "btn_cancel": "CANCELAR", "credits_title": "Créditos y Fuentes",
        "author_label": "DESARROLLADOR / AUTOR:", "socials_hint": "Redes sociales de thebusk2:",
        "sources_label": "FUENTES Y AGRADECIMIENTOS TÉCNICOS:"
    },
    "en": {
        "title": "NSWPORTIOS",
        "subtitle": "Switch to iOS Native Porter • Metal 3.0 & ARM64",
        "open_in": "📂 Open Input", "open_out": "📦 Open Output", "credits": "❤️ Credits",
        "card_game": " 🎮 NINTENDO SWITCH GAME ", "no_game": "No game selected",
        "formats_hint": "Supported formats: .nsp, .xci, .nsz, .xcz", "browse": "Browse...",
        "card_keys": " 🔑 DECRYPTION KEYS (PROD.KEYS) ",
        "keys_ok": "✓ Detected:", "keys_err": "⚠️ 'prod.keys' not found. Copy it into 'keys/'",
        "load_keys": "Load Keys", "card_opts": " ⚙️ BUILD SETTINGS ",
        "lbl_lang": "Game Language:", "lbl_target": "Target:", "lbl_romfs": "RomFS:",
        "romfs_bundle": "Bundled in IPA", "romfs_sep": "Separate (>15GB)",
        "fps_chk": "Show on-screen FPS", "card_log": " 📟 PROGRESS CONSOLE ",
        "status_ready": "Ready to build", "btn_compile": "🚀 BUILD iOS .IPA",
        "btn_cancel": "CANCEL", "credits_title": "Credits & Sources",
        "author_label": "DEVELOPER / AUTHOR:", "socials_hint": "thebusk2 social links:",
        "sources_label": "TECHNICAL SOURCES & CREDITS:"
    },
    "fr": {
        "title": "NSWPORTIOS",
        "subtitle": "Porteur Natif Switch vers iOS • Metal 3.0 & ARM64",
        "open_in": "📂 Ouvrir Input", "open_out": "📦 Ouvrir Output", "credits": "❤️ Crédits",
        "card_game": " 🎮 JEU NINTENDO SWITCH ", "no_game": "Aucun jeu sélectionné",
        "formats_hint": "Formats pris en charge : .nsp, .xci, .nsz, .xcz", "browse": "Parcourir...",
        "card_keys": " 🔑 CLÉS DE DÉCHIFFREMENT (PROD.KEYS) ",
        "keys_ok": "✓ Détecté :", "keys_err": "⚠️ 'prod.keys' introuvable. Copiez-le dans 'keys/'",
        "load_keys": "Charger clés", "card_opts": " ⚙️ PARAMÈTRES DE COMPILATION ",
        "lbl_lang": "Langue du jeu :", "lbl_target": "Cible :", "lbl_romfs": "RomFS :",
        "romfs_bundle": "Intégré dans l'IPA", "romfs_sep": "Séparé (>15 Go)",
        "fps_chk": "Afficher FPS à l'écran", "card_log": " 📟 CONSOLE DE PROGRESSION ",
        "status_ready": "Prêt pour la compilation", "btn_compile": "🚀 COMPILER EN .IPA iOS",
        "btn_cancel": "ANNULER", "credits_title": "Crédits et Sources",
        "author_label": "DÉVELOPPEUR / AUTEUR :", "socials_hint": "Réseaux sociaux de thebusk2 :",
        "sources_label": "SOURCES TECHNIQUES ET REMERCIEMENTS :"
    },
    "ja": {
        "title": "NSWPORTIOS",
        "subtitle": "Switch から iOS へのネイティブ移植 • Metal 3.0 & ARM64",
        "open_in": "📂 Input を開く", "open_out": "📦 Output を開く", "credits": "❤️ クレジット",
        "card_game": " 🎮 NINTENDO SWITCH ゲーム ", "no_game": "ゲームが選択されていません",
        "formats_hint": "対応フォーマット: .nsp, .xci, .nsz, .xcz", "browse": "参照...",
        "card_keys": " 🔑 復号キー (PROD.KEYS) ",
        "keys_ok": "✓ 検出済み:", "keys_err": "⚠️ 'prod.keys' が見つかりません。'keys/' に配置してください",
        "load_keys": "キー読み込み", "card_opts": " ⚙️ ビルド設定 ",
        "lbl_lang": "ゲーム言語:", "lbl_target": "ターゲット:", "lbl_romfs": "RomFS:",
        "romfs_bundle": "IPA に同梱", "romfs_sep": "分割 (>15GB)",
        "fps_chk": "画面に FPS を表示", "card_log": " 📟 進行状況コンソール ",
        "status_ready": "ビルド準備完了", "btn_compile": "🚀 iOS .IPA をビルド",
        "btn_cancel": "キャンセル", "credits_title": "クレジットとソース",
        "author_label": "開発者 / 作者:", "socials_hint": "thebusk2 の SNS リンク:",
        "sources_label": "技術ソースと謝辞:"
    },
    "ru": {
        "title": "NSWPORTIOS",
        "subtitle": "Нативный порт Switch на iOS • Metal 3.0 & ARM64",
        "open_in": "📂 Открыть Input", "open_out": "📦 Открыть Output", "credits": "❤️ Создатели",
        "card_game": " 🎮 ИГРА NINTENDO SWITCH ", "no_game": "Игра не выбрана",
        "formats_hint": "Поддерживаемые форматы: .nsp, .xci, .nsz, .xcz", "browse": "Обзор...",
        "card_keys": " 🔑 КЛЮЧИ ДЕШИФРОВАНИЯ (PROD.KEYS) ",
        "keys_ok": "✓ Обнаружено:", "keys_err": "⚠️ 'prod.keys' не найден. Скопируйте в 'keys/'",
        "load_keys": "Загрузить ключи", "card_opts": " ⚙️ ПАРАМЕТРЫ СБОРКИ ",
        "lbl_lang": "Язык игры:", "lbl_target": "Назначение:", "lbl_romfs": "RomFS:",
        "romfs_bundle": "Встроен в IPA", "romfs_sep": "Отдельно (>15 ГБ)",
        "fps_chk": "Показывать FPS", "card_log": " 📟 КОНСОЛЬ ВЫПОЛНЕНИЯ ",
        "status_ready": "Готов к сборке", "btn_compile": "🚀 СОБРАТЬ iOS .IPA",
        "btn_cancel": "ОТМЕНА", "credits_title": "Создатели и Источники",
        "author_label": "РАЗРАБОТЧИК / АВТОР:", "socials_hint": "Соцсети thebusk2:",
        "sources_label": "ТЕХНИЧЕСКИЕ ИСТОЧНИКИ И БЛАГОДАРНОСТИ:"
    }
}

class NSWPortIOSGUI(tk.Tk):
    def __init__(self):
        super().__init__()
        
        self.title("NSWPORTIOS - Nintendo Switch to iOS Porter")
        self.geometry("900x740")
        self.minsize(840, 700)
        self.configure(bg=COLOR_BG_DARK)
        
        self.base_dir = Path(__file__).resolve().parent
        self.process = None
        
        # Idioma de la interfaz
        self.cur_lang = "es"
        
        # Variables de estado
        self.var_app_lang = tk.StringVar(value="Español (es)")
        self.var_game_path = tk.StringVar(value="")
        self.var_game_info = tk.StringVar(value="Ningún juego seleccionado")
        self.var_keys_path = tk.StringVar(value="")
        self.var_keys_status = tk.StringVar(value="Buscando...")
        
        self.var_game_lang = tk.StringVar(value="es")
        self.var_fps = tk.BooleanVar(value=True)
        self.var_platform = tk.StringVar(value="ios")
        self.var_romfs = tk.StringVar(value="bundle")
        self.var_status_msg = tk.StringVar(value="Listo para compilar")
        
        self.setup_ui()
        self.detect_keys()
        self.detect_game_in_input()
        self.update_texts()
        
    def t(self, key):
        return I18N.get(self.cur_lang, I18N["es"]).get(key, key)
        
    def setup_ui(self):
        container = tk.Frame(self, bg=COLOR_BG_DARK)
        container.pack(fill=tk.BOTH, expand=True)
        
        # 1. Joy-Con Izquierdo (Azul)
        left_joycon = tk.Frame(container, bg=COLOR_JOYCON_BLUE, width=54)
        left_joycon.pack(side=tk.LEFT, fill=tk.Y)
        left_joycon.pack_propagate(False)
        
        stick_l = tk.Canvas(left_joycon, width=40, height=40, bg=COLOR_JOYCON_BLUE, highlightthickness=0)
        stick_l.pack(pady=25)
        stick_l.create_oval(4, 4, 36, 36, fill="#111111", outline="#555555", width=2)
        
        tk.Label(left_joycon, text="—", font=("Arial", 16, "bold"), fg="#111111", bg=COLOR_JOYCON_BLUE).pack(pady=5)
        
        dpad = tk.Canvas(left_joycon, width=44, height=44, bg=COLOR_JOYCON_BLUE, highlightthickness=0)
        dpad.pack(pady=10)
        dpad.create_oval(14, 2, 30, 18, fill="#111111", outline="")
        dpad.create_oval(2, 14, 18, 30, fill="#111111", outline="")
        dpad.create_oval(26, 14, 42, 30, fill="#111111", outline="")
        dpad.create_oval(14, 26, 30, 42, fill="#111111", outline="")
        
        # 2. Joy-Con Derecho (Rojo)
        right_joycon = tk.Frame(container, bg=COLOR_JOYCON_RED, width=54)
        right_joycon.pack(side=tk.RIGHT, fill=tk.Y)
        right_joycon.pack_propagate(False)
        
        tk.Label(right_joycon, text="+", font=("Arial", 18, "bold"), fg="#111111", bg=COLOR_JOYCON_RED).pack(pady=20)
        
        abxy = tk.Canvas(right_joycon, width=44, height=44, bg=COLOR_JOYCON_RED, highlightthickness=0)
        abxy.pack(pady=5)
        abxy.create_oval(14, 2, 30, 18, fill="#111111", outline="")
        abxy.create_text(22, 10, text="X", fill="white", font=("Arial", 7, "bold"))
        abxy.create_oval(2, 14, 18, 30, fill="#111111", outline="")
        abxy.create_text(10, 22, text="Y", fill="white", font=("Arial", 7, "bold"))
        abxy.create_oval(26, 14, 42, 30, fill="#111111", outline="")
        abxy.create_text(34, 22, text="A", fill="white", font=("Arial", 7, "bold"))
        abxy.create_oval(14, 26, 30, 42, fill="#111111", outline="")
        abxy.create_text(22, 34, text="B", fill="white", font=("Arial", 7, "bold"))
        
        stick_r = tk.Canvas(right_joycon, width=40, height=40, bg=COLOR_JOYCON_RED, highlightthickness=0)
        stick_r.pack(side=tk.BOTTOM, pady=25)
        stick_r.create_oval(4, 4, 36, 36, fill="#111111", outline="#555555", width=2)
        
        # 3. Pantalla Central
        center_frame = tk.Frame(container, bg=COLOR_BG_DARK)
        center_frame.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        
        # Header Switch
        header = tk.Frame(center_frame, bg=COLOR_CARD_BG, height=65, padx=20)
        header.pack(fill=tk.X)
        
        title_box = tk.Frame(header, bg=COLOR_CARD_BG)
        title_box.pack(side=tk.LEFT, pady=10)
        
        self.lbl_title = tk.Label(title_box, text="NSWPORTIOS", font=("Helvetica", 18, "bold"), fg=COLOR_TEXT_MAIN, bg=COLOR_CARD_BG)
        self.lbl_title.pack(anchor="w")
        self.lbl_sub = tk.Label(title_box, text=self.t("subtitle"), font=("Helvetica", 9), fg=COLOR_TEXT_DIM, bg=COLOR_CARD_BG)
        self.lbl_sub.pack(anchor="w")
        
        btn_box = tk.Frame(header, bg=COLOR_CARD_BG)
        btn_box.pack(side=tk.RIGHT, pady=12)
        
        # Selector de Idioma de la Interfaz
        self.combo_app_lang = ttk.Combobox(btn_box, textvariable=self.var_app_lang,
                                            values=["🇪🇸 Español", "🇺🇸 English", "🇫🇷 Français", "🇯🇵 日本語", "🇷🇺 Русский"],
                                            width=12, state="readonly")
        self.combo_app_lang.pack(side=tk.LEFT, padx=5)
        self.combo_app_lang.bind("<<ComboboxSelected>>", self.on_change_app_lang)
        
        self.btn_in = tk.Button(btn_box, text=self.t("open_in"), font=("Helvetica", 9), fg=COLOR_TEXT_MAIN, bg=COLOR_CARD_BORDER,
                                relief=tk.FLAT, padx=8, pady=4, cursor="pointinghand",
                                command=lambda: webbrowser.open(f"file://{self.base_dir / 'input'}"))
        self.btn_in.pack(side=tk.LEFT, padx=4)
        
        self.btn_out = tk.Button(btn_box, text=self.t("open_out"), font=("Helvetica", 9), fg=COLOR_TEXT_MAIN, bg=COLOR_CARD_BORDER,
                                 relief=tk.FLAT, padx=8, pady=4, cursor="pointinghand",
                                 command=lambda: webbrowser.open(f"file://{self.base_dir / 'output'}"))
        self.btn_out.pack(side=tk.LEFT, padx=4)
        
        self.btn_credits = tk.Button(btn_box, text=self.t("credits"), font=("Helvetica", 9, "bold"), fg=COLOR_TEXT_MAIN,
                                     bg=COLOR_CARD_BORDER, relief=tk.FLAT, padx=8, pady=4, cursor="pointinghand",
                                     command=self.show_credits_window)
        self.btn_credits.pack(side=tk.LEFT, padx=4)
        
        # Contenido
        content = tk.Frame(center_frame, bg=COLOR_BG_DARK, padx=20, pady=15)
        content.pack(fill=tk.BOTH, expand=True)
        
        # Tarjeta 1: Juego
        self.card_game = tk.LabelFrame(content, text=self.t("card_game"), font=("Helvetica", 10, "bold"),
                                       fg=COLOR_JOYCON_BLUE, bg=COLOR_CARD_BG, bd=1, relief=tk.SOLID, padx=12, pady=10)
        self.card_game.pack(fill=tk.X, pady=(0, 10))
        
        row_game = tk.Frame(self.card_game, bg=COLOR_CARD_BG)
        row_game.pack(fill=tk.X)
        
        lbl_game_info = tk.Label(row_game, textvariable=self.var_game_info, font=("Helvetica", 11, "bold"),
                                 fg=COLOR_TEXT_MAIN, bg=COLOR_CARD_BG, anchor="w", wraplength=550)
        lbl_game_info.pack(side=tk.LEFT, fill=tk.X, expand=True)
        
        self.btn_pick_game = tk.Button(row_game, text=self.t("browse"), font=("Helvetica", 10, "bold"),
                                       fg=COLOR_TEXT_MAIN, bg=COLOR_JOYCON_BLUE, activebackground="#0090B0",
                                       relief=tk.FLAT, padx=14, pady=6, cursor="pointinghand", command=self.pick_game)
        self.btn_pick_game.pack(side=tk.RIGHT)
        
        # Tarjeta 2: prod.keys
        self.card_keys = tk.LabelFrame(content, text=self.t("card_keys"), font=("Helvetica", 10, "bold"),
                                       fg=COLOR_JOYCON_RED, bg=COLOR_CARD_BG, bd=1, relief=tk.SOLID, padx=12, pady=10)
        self.card_keys.pack(fill=tk.X, pady=(0, 10))
        
        row_keys = tk.Frame(self.card_keys, bg=COLOR_CARD_BG)
        row_keys.pack(fill=tk.X)
        
        lbl_keys = tk.Label(row_keys, textvariable=self.var_keys_status, font=("Helvetica", 10),
                            fg=COLOR_TEXT_DIM, bg=COLOR_CARD_BG, anchor="w")
        lbl_keys.pack(side=tk.LEFT, fill=tk.X, expand=True)
        
        self.btn_pick_keys = tk.Button(row_keys, text=self.t("load_keys"), font=("Helvetica", 9),
                                       fg=COLOR_TEXT_MAIN, bg=COLOR_CARD_BORDER, relief=tk.FLAT,
                                       padx=10, pady=4, cursor="pointinghand", command=self.pick_keys)
        self.btn_pick_keys.pack(side=tk.RIGHT)
        
        # Tarjeta 3: Opciones y Ajustes
        self.card_opts = tk.LabelFrame(content, text=self.t("card_opts"), font=("Helvetica", 10, "bold"),
                                       fg=COLOR_TEXT_MAIN, bg=COLOR_CARD_BG, bd=1, relief=tk.SOLID, padx=12, pady=10)
        self.card_opts.pack(fill=tk.X, pady=(0, 10))
        
        grid_opts = tk.Frame(self.card_opts, bg=COLOR_CARD_BG)
        grid_opts.pack(fill=tk.X)
        
        self.lbl_glang = tk.Label(grid_opts, text=self.t("lbl_lang"), font=("Helvetica", 9), fg=COLOR_TEXT_DIM, bg=COLOR_CARD_BG)
        self.lbl_glang.grid(row=0, column=0, sticky="w", pady=4)
        lang_combo = ttk.Combobox(grid_opts, textvariable=self.var_game_lang, values=["es", "es-419", "en", "ja", "fr", "de", "ru"], width=10, state="readonly")
        lang_combo.grid(row=0, column=1, sticky="w", padx=10, pady=4)
        
        self.lbl_tgt = tk.Label(grid_opts, text=self.t("lbl_target"), font=("Helvetica", 9), fg=COLOR_TEXT_DIM, bg=COLOR_CARD_BG)
        self.lbl_tgt.grid(row=0, column=2, sticky="w", padx=(20, 0), pady=4)
        rb_ios = tk.Radiobutton(grid_opts, text="iPhone/iPad (.IPA)", variable=self.var_platform, value="ios",
                                fg=COLOR_TEXT_MAIN, bg=COLOR_CARD_BG, selectcolor="#111111", activebackground=COLOR_CARD_BG)
        rb_ios.grid(row=0, column=3, sticky="w", pady=4)
        rb_mac = tk.Radiobutton(grid_opts, text="Mac (.app)", variable=self.var_platform, value="mac-app",
                                fg=COLOR_TEXT_MAIN, bg=COLOR_CARD_BG, selectcolor="#111111", activebackground=COLOR_CARD_BG)
        rb_mac.grid(row=0, column=4, sticky="w", padx=10, pady=4)
        
        self.lbl_rfs = tk.Label(grid_opts, text=self.t("lbl_romfs"), font=("Helvetica", 9), fg=COLOR_TEXT_DIM, bg=COLOR_CARD_BG)
        self.lbl_rfs.grid(row=1, column=0, sticky="w", pady=4)
        self.rb_bundle = tk.Radiobutton(grid_opts, text=self.t("romfs_bundle"), variable=self.var_romfs, value="bundle",
                                        fg=COLOR_TEXT_MAIN, bg=COLOR_CARD_BG, selectcolor="#111111", activebackground=COLOR_CARD_BG)
        self.rb_bundle.grid(row=1, column=1, sticky="w", pady=4)
        
        self.chk_fps = tk.Checkbutton(grid_opts, text=self.t("fps_chk"), variable=self.var_fps,
                                      fg=COLOR_TEXT_MAIN, bg=COLOR_CARD_BG, selectcolor="#111111", activebackground=COLOR_CARD_BG)
        self.chk_fps.grid(row=1, column=2, columnspan=2, sticky="w", padx=(20, 0), pady=4)
        
        # Tarjeta 4: Consola de Salida
        self.card_log = tk.LabelFrame(content, text=self.t("card_log"), font=("Helvetica", 9, "bold"),
                                      fg=COLOR_TEXT_DIM, bg=COLOR_CARD_BG, bd=1, relief=tk.SOLID, padx=8, pady=8)
        self.card_log.pack(fill=tk.BOTH, expand=True, pady=(0, 10))
        
        self.txt_log = tk.Text(self.card_log, bg="#0C0C0E", fg="#34C759", font=("Courier", 9),
                               relief=tk.FLAT, height=8, wrap=tk.WORD)
        self.txt_log.pack(fill=tk.BOTH, expand=True)
        
        # Barra inferior y Botón de Compilación
        bottom_bar = tk.Frame(content, bg=COLOR_BG_DARK)
        bottom_bar.pack(fill=tk.X)
        
        self.lbl_status = tk.Label(bottom_bar, textvariable=self.var_status_msg, font=("Helvetica", 10),
                                   fg=COLOR_JOYCON_BLUE, bg=COLOR_BG_DARK)
        self.lbl_status.pack(side=tk.LEFT, pady=8)
        
        self.btn_compile = tk.Button(bottom_bar, text=self.t("btn_compile"), font=("Helvetica", 13, "bold"),
                                     fg=COLOR_TEXT_MAIN, bg=COLOR_JOYCON_RED, activebackground="#D02010",
                                     relief=tk.FLAT, padx=25, pady=10, cursor="pointinghand", command=self.start_compilation)
        self.btn_compile.pack(side=tk.RIGHT)
        
    def on_change_app_lang(self, event=None):
        val = self.var_app_lang.get()
        if "English" in val: self.cur_lang = "en"
        elif "Français" in val: self.cur_lang = "fr"
        elif "日本語" in val: self.cur_lang = "ja"
        elif "Русский" in val: self.cur_lang = "ru"
        else: self.cur_lang = "es"
        self.update_texts()
        
    def update_texts(self):
        self.lbl_sub.config(text=self.t("subtitle"))
        self.btn_in.config(text=self.t("open_in"))
        self.btn_out.config(text=self.t("open_out"))
        self.btn_credits.config(text=self.t("credits"))
        self.card_game.config(text=self.t("card_game"))
        self.btn_pick_game.config(text=self.t("browse"))
        self.card_keys.config(text=self.t("card_keys"))
        self.btn_pick_keys.config(text=self.t("load_keys"))
        self.card_opts.config(text=self.t("card_opts"))
        self.lbl_glang.config(text=self.t("lbl_lang"))
        self.lbl_tgt.config(text=self.t("lbl_target"))
        self.lbl_rfs.config(text=self.t("lbl_romfs"))
        self.rb_bundle.config(text=self.t("romfs_bundle"))
        self.chk_fps.config(text=self.t("fps_chk"))
        self.card_log.config(text=self.t("card_log"))
        self.btn_compile.config(text=self.t("btn_compile"))
        if not self.var_game_path.get():
            self.var_game_info.set(self.t("no_game"))
            
    def log(self, text):
        self.txt_log.insert(tk.END, text)
        self.txt_log.see(tk.END)
        
    def detect_keys(self):
        sys.path.insert(0, str(self.base_dir))
        from switch2ipa import find_prod_keys
        k = find_prod_keys(self.base_dir)
        if k:
            self.var_keys_path.set(str(k))
            self.var_keys_status.set(f"{self.t('keys_ok')} {k.name} ({k.parent})")
        else:
            self.var_keys_status.set(self.t("keys_err"))
            
    def detect_game_in_input(self):
        input_dir = self.base_dir / "input"
        if not input_dir.exists(): return
        valid_exts = {".nsp", ".xci", ".nsz", ".xcz"}
        for f in input_dir.iterdir():
            if f.is_file() and not f.name.startswith("._") and f.suffix.lower() in valid_exts:
                self.select_game(f)
                break
                
    def select_game(self, path):
        path = Path(path)
        self.var_game_path.set(str(path))
        size_mb = path.stat().st_size / (1024 * 1024)
        size_str = f"{size_mb / 1024:.2f} GB" if size_mb > 1024 else f"{size_mb:.1f} MB"
        self.var_game_info.set(f"{path.name}  [{path.suffix.upper()[1:]} • {size_str}]")
        
    def pick_game(self):
        f = filedialog.askopenfilename(
            title=self.t("card_game"),
            filetypes=[("Nintendo Switch Games", "*.nsp *.xci *.nsz *.xcz *.NSP *.XCI *.NSZ *.XCZ")]
        )
        if f: self.select_game(f)
        
    def pick_keys(self):
        f = filedialog.askopenfilename(
            title=self.t("card_keys"),
            filetypes=[("Switch Keys", "*.keys *.txt")]
        )
        if f:
            self.var_keys_path.set(f)
            self.var_keys_status.set(f"{self.t('keys_ok')} {Path(f).name}")
            
    def show_credits_window(self):
        cw = tk.Toplevel(self)
        cw.title(self.t("credits_title"))
        cw.geometry("580x520")
        cw.configure(bg=COLOR_BG_DARK)
        cw.transient(self)
        cw.grab_set()
        
        pad = tk.Frame(cw, bg=COLOR_BG_DARK, padx=20, pady=15)
        pad.pack(fill=tk.BOTH, expand=True)
        
        tk.Label(pad, text="❤️ " + self.t("credits_title").upper(), font=("Helvetica", 14, "bold"),
                 fg=COLOR_TEXT_MAIN, bg=COLOR_BG_DARK).pack(anchor="w", pady=(0, 10))
        
        # Tarjeta Autor & Redes
        card_dev = tk.LabelFrame(pad, text=" " + self.t("author_label") + " ", font=("Helvetica", 10, "bold"),
                                 fg=COLOR_JOYCON_BLUE, bg=COLOR_CARD_BG, bd=1, relief=tk.SOLID, padx=12, pady=10)
        card_dev.pack(fill=tk.X, pady=(0, 12))
        
        tk.Label(card_dev, text="thebusk2", font=("Helvetica", 14, "bold"), fg=COLOR_TEXT_MAIN, bg=COLOR_CARD_BG).pack(anchor="w")
        tk.Label(card_dev, text=self.t("socials_hint"), font=("Helvetica", 9), fg=COLOR_TEXT_DIM, bg=COLOR_CARD_BG).pack(anchor="w", pady=(2, 8))
        
        btn_row = tk.Frame(card_dev, bg=COLOR_CARD_BG)
        btn_row.pack(anchor="w")
        
        def link_btn(parent, txt, url, bg_col):
            b = tk.Button(parent, text=txt, font=("Helvetica", 9, "bold"), fg="white", bg=bg_col,
                          activebackground="#444444", relief=tk.FLAT, padx=10, pady=5, cursor="pointinghand",
                          command=lambda: webbrowser.open(url))
            b.pack(side=tk.LEFT, padx=4)
            return b
            
        link_btn(btn_row, "🐙 GitHub (@thebusk2)", "https://github.com/thebusk2", "#24292E")
        link_btn(btn_row, "📸 Instagram (@thebusk2)", "https://www.instagram.com/thebusk2/", "#C13584")
        link_btn(btn_row, "🐦 X (@thebusk2)", "https://x.com/thebusk2", "#1DA1F2")
        
        # Tarjeta Fuentes Técnicas
        card_src = tk.LabelFrame(pad, text=" " + self.t("sources_label") + " ", font=("Helvetica", 10, "bold"),
                                 fg=COLOR_JOYCON_RED, bg=COLOR_CARD_BG, bd=1, relief=tk.SOLID, padx=12, pady=10)
        card_src.pack(fill=tk.BOTH, expand=True)
        
        sources = [
            ("seedds/nxnative", "NSO rewriter, Horizon HLE host y traducción NVN a Metal", "https://github.com/seedds/nxnative"),
            ("Thealexbarney/LibHac", "Parsing y desencriptación de NSP, XCI, RomFS y NCAs", "https://github.com/Thealexbarney/LibHac"),
            ("jhaizhou-ops/d2r-mobile", "Pionero en compatibilidad nativa de NSW en iOS vía Metal", "https://github.com/jhaizhou-ops/d2r-mobile"),
            ("Ryujinx Team", "Transpilador de shaders NVIDIA Maxwell a SPIR-V", "https://github.com/Ryujinx/Ryujinx"),
            ("Atmosphère-NX", "Mesosphère: semántica de sincronización y kernel Horizon", "https://github.com/Atmosphere-NX/Atmosphere"),
            ("switchbrew/switch-tools", "Herramientas de bajo nivel para binarios NSO y NPDM", "https://github.com/switchbrew/switch-tools"),
            ("Nico Bosshard (nsz)", "Descompresión y gestión de contenedores NSZ / XCZ", "https://github.com/nicoboss/nsz")
        ]
        
        for name, desc, url in sources:
            rf = tk.Frame(card_src, bg=COLOR_CARD_BG)
            rf.pack(fill=tk.X, pady=3)
            
            tf = tk.Frame(rf, bg=COLOR_CARD_BG)
            tf.pack(side=tk.LEFT, fill=tk.X, expand=True)
            tk.Label(tf, text=name, font=("Helvetica", 9, "bold"), fg=COLOR_TEXT_MAIN, bg=COLOR_CARD_BG, anchor="w").pack(fill=tk.X)
            tk.Label(tf, text=desc, font=("Helvetica", 8), fg=COLOR_TEXT_DIM, bg=COLOR_CARD_BG, anchor="w").pack(fill=tk.X)
            
            tk.Button(rf, text="🔗", font=("Helvetica", 8), fg="white", bg=COLOR_CARD_BORDER, relief=tk.FLAT,
                      padx=4, pady=1, cursor="pointinghand", command=lambda u=url: webbrowser.open(u)).pack(side=tk.RIGHT)
                      
    def start_compilation(self):
        game = self.var_game_path.get()
        keys = self.var_keys_path.get()
        
        if not game:
            messagebox.showwarning("Atención", self.t("no_game"))
            return
        if not keys:
            messagebox.showwarning("Atención", self.t("keys_err"))
            return
            
        self.btn_compile.config(state=tk.DISABLED, bg="#555555")
        self.var_status_msg.set("Compilando... Revisa la consola abajo.")
        self.txt_log.delete("1.0", tk.END)
        self.log(f"=== INICIANDO NSWPORTIOS ===\nJuego: {game}\nKeys: {keys}\n")
        
        threading.Thread(target=self._run_process, daemon=True).start()
        
    def _run_process(self):
        script = self.base_dir / "switch2ipa.py"
        
        # Usar Python del venv si existe
        venv_py = Path.home() / ".nswportios_venv" / "bin" / "python3"
        py_exec = str(venv_py) if venv_py.exists() else sys.executable
        
        cmd = [
            py_exec, str(script),
            "-i", self.var_game_path.get(),
            "-k", self.var_keys_path.get(),
            "-l", self.var_game_lang.get(),
            "--platform", self.var_platform.get(),
            "--romfs", self.var_romfs.get(),
        ]
        if self.var_fps.get(): cmd.append("--fps")
        else: cmd.append("--no-fps")
        
        env = os.environ.copy()
        extra_paths = [
            str(Path.home() / ".local" / "bin"),
            str(Path.home() / ".dotnet"),
            "/opt/homebrew/bin",
            "/usr/local/bin"
        ]
        env["PATH"] = ":".join(extra_paths) + ":" + env.get("PATH", "")
        env["DOTNET_ROOT"] = str(Path.home() / ".dotnet")
        
        proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, env=env)
        self.process = proc
        
        for line in proc.stdout:
            self.log(line)
            
        proc.wait()
        
        def finish():
            self.btn_compile.config(state=tk.NORMAL, bg=COLOR_JOYCON_RED)
            if proc.returncode == 0:
                self.var_status_msg.set("¡Compilación finalizada con éxito!")
                messagebox.showinfo("Éxito", "¡Juego compilado con éxito a archivo .IPA!\nRevisa la carpeta 'output/'.")
            else:
                self.var_status_msg.set(f"Error en la compilación (código {proc.returncode})")
                messagebox.showerror("Error", f"La compilación falló con código {proc.returncode}.\nRevisa la consola.")
                
        self.after(0, finish)

if __name__ == "__main__":
    app = NSWPortIOSGUI()
    app.mainloop()
