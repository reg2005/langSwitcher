import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var l10n: LocalizationManager
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralSettingsTab()
                .environmentObject(settingsManager)
                .environmentObject(l10n)
                .tabItem {
                    Label(l10n.t("settings.tab.general"), systemImage: "gear")
                }
                .tag(0)
            
            LayoutsSettingsTab()
                .environmentObject(settingsManager)
                .environmentObject(l10n)
                .tabItem {
                    Label(l10n.t("settings.tab.layouts"), systemImage: "keyboard")
                }
                .tag(1)
            
            HotkeySettingsTab()
                .environmentObject(settingsManager)
                .environmentObject(l10n)
                .tabItem {
                    Label(l10n.t("settings.tab.hotkey"), systemImage: "command")
                }
                .tag(2)
            
            PermissionsView()
                .environmentObject(l10n)
                .tabItem {
                    Label(l10n.t("settings.tab.permissions"), systemImage: "lock.shield")
                }
                .tag(3)
            
            ConversionLogView(logStore: ConversionLogStore.shared)
                .environmentObject(l10n)
                .tabItem {
                    Label(l10n.t("settings.tab.log"), systemImage: "list.bullet.rectangle")
                }
                .tag(4)
        }
        .frame(width: 580, height: 520)
        .padding()
    }
}

// MARK: - General Settings

struct GeneralSettingsTab: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var l10n: LocalizationManager
    
    var body: some View {
        Form {
            Section {
                Picker(l10n.t("general.language"), selection: $l10n.currentLanguage) {
                    ForEach(LocalizationManager.availableLanguages, id: \.code) { lang in
                        Text(lang.name).tag(lang.code)
                    }
                }
                
                Toggle(l10n.t("general.launchAtLogin"), isOn: $settingsManager.launchAtLogin)
                Toggle(l10n.t("general.playSound"), isOn: $settingsManager.playSounds)
                Toggle(l10n.t("general.showNotifications"), isOn: $settingsManager.showNotifications)
            }
            
            Section(l10n.t("general.smartConversion")) {
                Picker(l10n.t("general.mode"), selection: $settingsManager.smartConversionMode) {
                    ForEach(SmartConversionMode.allCases, id: \.self) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.radioGroup)
                
                Text(settingsManager.smartConversionMode.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }
            
            Section(l10n.t("general.layoutSwitch")) {
                Picker(l10n.t("general.mode"), selection: $settingsManager.layoutSwitchMode) {
                    ForEach(LayoutSwitchMode.allCases, id: \.self) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.radioGroup)
                
                Text(settingsManager.layoutSwitchMode.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }
            
            Section(l10n.t("general.howItWorks")) {
                Text(l10n.t("general.howItWorksText"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Section(l10n.t("general.statistics")) {
                HStack {
                    Text(l10n.t("general.totalConversions"))
                    Spacer()
                    Text("\(settingsManager.conversionCount)")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Layouts Settings

struct LayoutsSettingsTab: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var l10n: LocalizationManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(l10n.t("layouts.title"))
                .font(.headline)
            
            Text(l10n.t("layouts.description"))
                .font(.caption)
                .foregroundStyle(.secondary)
            
            List {
                ForEach(settingsManager.enabledLayouts) { layout in
                    HStack {
                        Image(systemName: "keyboard")
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading) {
                            Text(layout.localizedName)
                                .font(.body)
                            Text(layout.id)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
                        Text(layout.languageCode.uppercased())
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(.blue.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    .padding(.vertical, 2)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            HStack {
                Button(l10n.t("layouts.refresh")) {
                    settingsManager.refreshSystemLayouts()
                }
                
                Spacer()
                
                Text(l10n.t("layouts.count").replacingOccurrences(of: "%d", with: "\(settingsManager.enabledLayouts.count)"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}

// MARK: - Hotkey Settings

struct HotkeySettingsTab: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var l10n: LocalizationManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(l10n.t("hotkey.title"))
                .font(.headline)
            
            Text(l10n.t("hotkey.description"))
                .font(.caption)
                .foregroundStyle(.secondary)
            
            // Current shortcut display
            HStack {
                Text(l10n.t("hotkey.current"))
                Spacer()
                Text(settingsManager.hotkeyDescription)
                    .font(.system(.title2, design: .rounded))
                    .bold()
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            Divider()
            
            // Double Shift toggle
            Toggle(l10n.t("hotkey.useDoubleShift"), isOn: $settingsManager.useDoubleShift)
                .toggleStyle(.switch)
            
            Text(l10n.t("hotkey.doubleShiftHint"))
                .font(.caption)
                .foregroundStyle(.secondary)
            
            if !settingsManager.useDoubleShift {
                Divider()
                
                Text(l10n.t("hotkey.customTitle"))
                    .font(.subheadline)
                    .bold()
                
                HotkeyRecorderView(
                    keyCode: $settingsManager.hotkeyKeyCode,
                    modifiers: Binding(
                        get: { settingsManager.hotkeyModifierFlags },
                        set: { settingsManager.hotkeyModifierFlags = $0 }
                    )
                )
                .environmentObject(l10n)
            }
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Launch at Login Helper

enum LaunchAtLoginHelper {
    static func setLaunchAtLogin(_ enabled: Bool) {
        // In production, use SMAppService (macOS 13+) or ServiceManagement
        // For now this is a placeholder
    }
}
