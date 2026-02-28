import Foundation

// MARK: - English Strings
// To add a new language, copy this file as Strings_xx.swift,
// translate every value, and call register() in initializeLocalization().

enum Strings_en {

    static let strings: [String: String] = [

        // ── Menu (StatusBarController) ──────────────────────────────
        "menu.header":                   "⌨ LangSwitcher",
        "menu.convertText":              "Convert Text",
        "menu.activeLayouts":            "Active Layouts:",
        "menu.conversions":              "Conversions:",
        "menu.settings":                 "Settings...",
        "menu.about":                    "About LangSwitcher",
        "menu.quit":                     "Quit LangSwitcher",
        "menu.tooltip":                  "LangSwitcher — %@ to convert",

        // ── Settings Window ─────────────────────────────────────────
        "settings.windowTitle":          "LangSwitcher Settings",
        "settings.tab.general":          "General",
        "settings.tab.layouts":          "Layouts",
        "settings.tab.hotkey":           "Hotkey",
        "settings.tab.permissions":      "Permissions",
        "settings.tab.log":              "Log",

        // ── General Tab ─────────────────────────────────────────────
        "general.language":              "Language",
        "general.launchAtLogin":         "Launch at Login",
        "general.playSound":             "Play Sound on Conversion",
        "general.showNotifications":     "Show Notifications",
        "general.smartConversion":       "Smart Conversion (No Selection)",
        "general.mode":                  "Mode:",
        "general.layoutSwitch":          "Layout Switch after Conversion",
        "general.howItWorks":            "How It Works",
        "general.howItWorksText":        "When text is selected, the shortcut converts the selection.\nWhen no text is selected, the behavior depends on the Smart Conversion mode above.",
        "general.statistics":            "Statistics",
        "general.totalConversions":      "Total Conversions:",

        // ── Smart Conversion Modes ──────────────────────────────────
        "smartMode.lastWord.name":       "Last Word Only",
        "smartMode.greedyLine.name":     "Greedy (Entire Phrase)",
        "smartMode.disabled.name":       "Disabled",
        "smartMode.lastWord.desc":       "Converts only the last typed word before the cursor.",
        "smartMode.greedyLine.desc":     "Selects text to the start of line, finds where the wrong layout begins, and converts the entire wrong-layout phrase.",
        "smartMode.disabled.desc":       "Smart conversion is off. You must manually select text before pressing the hotkey.",

        // ── Layout Switch Modes ─────────────────────────────────────
        "layoutSwitchMode.always.name":          "Always switch layout",
        "layoutSwitchMode.ifLastWord.name":      "Switch if last word was converted",
        "layoutSwitchMode.ifAnyWord.name":       "Switch if any word required conversion",
        "layoutSwitchMode.always.desc":          "Always switch the keyboard layout after pressing the hotkey, regardless of whether text was converted.",
        "layoutSwitchMode.ifLastWord.desc":      "Switch the layout only if the last word before the cursor was typed in the wrong layout and got reconverted.",
        "layoutSwitchMode.ifAnyWord.desc":       "Switch the layout if any word in the converted text needed reconversion to the correct layout.",

        // ── Layouts Tab ─────────────────────────────────────────────
        "layouts.title":                 "Active Keyboard Layouts",
        "layouts.description":           "These layouts are detected from your system keyboard settings. The converter maps characters between them based on physical key positions.",
        "layouts.refresh":               "Refresh from System",
        "layouts.count":                 "%d layouts detected",

        // ── Hotkey Tab ──────────────────────────────────────────────
        "hotkey.title":                  "Keyboard Shortcut",
        "hotkey.description":            "Press this shortcut to convert text. If text is selected it converts the selection; otherwise it auto-selects the last word.",
        "hotkey.current":                "Current shortcut:",
        "hotkey.useDoubleShift":         "Use Double Shift (⇧⇧) as shortcut",
        "hotkey.doubleShiftHint":        "Quickly press Shift twice to trigger conversion. This is the recommended shortcut — fast and doesn't conflict with other apps.",
        "hotkey.customTitle":            "Custom Shortcut",

        // ── Hotkey Recorder ─────────────────────────────────────────
        "hotkeyRecorder.prompt":         "Click \"Record\" and press your desired shortcut:",
        "hotkeyRecorder.pressKey":       "Press a key combination...",
        "hotkeyRecorder.cancel":         "Cancel",
        "hotkeyRecorder.record":         "Record",

        // ── Permissions Tab ─────────────────────────────────────────
        "permissions.title":             "Permissions",
        "permissions.description":       "LangSwitcher needs Accessibility access to read and replace selected text in other applications.",
        "permissions.accessibilityTitle":"Accessibility Access",
        "permissions.granted":           "Granted — LangSwitcher can convert text",
        "permissions.notGranted":        "Not granted — Please enable in System Settings",
        "permissions.grantAccess":       "Grant Access",
        "permissions.howToEnable":       "How to enable:",
        "permissions.step1":             "1. Open System Settings > Privacy & Security > Accessibility",
        "permissions.step2":             "2. Click the lock icon to make changes",
        "permissions.step3":             "3. Enable LangSwitcher in the list",
        "permissions.step4":             "4. Restart LangSwitcher if needed",
        "permissions.openSettings":      "Open System Settings",
        "permissions.refreshStatus":     "Refresh Status",

        // ── Conversion Log Tab ──────────────────────────────────────
        "log.title":                     "Conversion Log",
        "log.entries":                   "%d entries",
        "log.exportJSON":                "Export JSON",
        "log.clearAll":                  "Clear All",
        "log.ratingHint":                "Rate each conversion as correct or incorrect to build training data. Click to cycle: unrated -> correct -> incorrect -> unrated.",
        "log.emptyTitle":                "No conversions logged yet.",
        "log.emptyHint":                 "Use the hotkey to convert text and entries will appear here.",
        "log.clearConfirmTitle":         "Clear All Logs?",
        "log.clearConfirmMessage":       "This will permanently delete all conversion log entries. This cannot be undone.",
        "log.cancel":                    "Cancel",
        "log.deleteEntry":               "Delete this entry",
        "log.exportPanelTitle":          "Export Conversion Log",
        "log.ratingUnrated":             "Unrated — click to mark as correct",
        "log.ratingCorrect":             "Correct — click to mark as incorrect",
        "log.ratingIncorrect":           "Incorrect — click to clear rating",

        // ── Logging Settings (General Tab) ─────────────────────────
        "general.logging":               "Conversion Logging",
        "general.loggingEnabled":        "Enable Conversion Logging",
        "general.loggingDisabledNote":   "Logging is disabled by default for your privacy. When enabled, conversions are stored locally on your Mac.",
        "general.logMaxEntries":         "Maximum Log Entries",
        "general.logUnlimited":          "0 = unlimited",

        // ── Logging Disabled (Log Tab) ─────────────────────────────
        "log.disabledTitle":             "Logging is Disabled",
        "log.disabledHint":              "Enable conversion logging in the General tab to start recording conversions.",

        // ── About Window ────────────────────────────────────────────
        "about.windowTitle":             "About LangSwitcher",
        "about.appName":                 "LangSwitcher",
        "about.version":                 "Version 1.0.0",
        "about.tagline":                 "Open-source keyboard layout text converter for macOS",
        "about.howToUse":                "How to use:",
        "about.step1":                   "Select text typed in wrong layout",
        "about.step2":                   "Press ⇧⇧ (double Shift)",
        "about.step3":                   "Text is automatically converted!",
        "about.github":                  "GitHub",
        "about.license":                 "MIT License",

        // ── Alerts (AppDelegate) ────────────────────────────────────
        "alert.accessibilityTitle":      "Accessibility Access Required",
        "alert.accessibilityMessage":    """
LangSwitcher needs Accessibility permission to read and replace text.

Go to System Settings → Privacy & Security → Accessibility and enable LangSwitcher.

If running from Xcode: add the built app from DerivedData or add Xcode itself.

If you already granted permission but it still doesn't work:
1. Remove LangSwitcher from the Accessibility list
2. Re-add it
3. Restart the app

Also check: Privacy & Security → Input Monitoring — LangSwitcher may need to be listed there too.
""",
        "alert.openSystemSettings":      "Open System Settings",
        "alert.continueAnyway":          "Continue Anyway",

        // ── Common ──────────────────────────────────────────────────
        "common.cancel":                 "Cancel",
    ]

    @MainActor static func register() {
        LocalizationManager.shared.register(language: "en", strings: strings)
    }
}
