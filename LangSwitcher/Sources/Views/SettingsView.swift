import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var l10n: LocalizationManager
    @State private var selectedTab = 0
    
    private var tabItems: [(String, String)] {
        [
            (l10n.t("settings.tab.general"), "gear"),
            (l10n.t("settings.tab.layouts"), "keyboard"),
            (l10n.t("settings.tab.hotkey"), "command"),
            (l10n.t("settings.tab.permissions"), "lock.shield"),
            (l10n.t("settings.tab.log"), "list.bullet.rectangle"),
        ]
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Classic segmented tab bar
            HStack(spacing: 0) {
                ForEach(Array(tabItems.enumerated()), id: \.offset) { index, item in
                    Button {
                        selectedTab = index
                    } label: {
                        VStack(spacing: 3) {
                            Image(systemName: item.1)
                                .font(.system(size: 16))
                            Text(item.0)
                                .font(.caption2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(selectedTab == index ? Color.accentColor.opacity(0.15) : Color.clear)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(selectedTab == index ? .primary : .secondary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 4)
            
            Divider()
                .padding(.top, 4)
            
            // Tab content
            Group {
                switch selectedTab {
                case 0:
                    GeneralSettingsTab()
                        .environmentObject(settingsManager)
                        .environmentObject(l10n)
                case 1:
                    LayoutsSettingsTab()
                        .environmentObject(settingsManager)
                        .environmentObject(l10n)
                case 2:
                    HotkeySettingsTab()
                        .environmentObject(settingsManager)
                        .environmentObject(l10n)
                case 3:
                    PermissionsView()
                        .environmentObject(l10n)
                case 4:
                    ConversionLogView(logStore: ConversionLogStore.shared)
                        .environmentObject(settingsManager)
                        .environmentObject(l10n)
                default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 580, height: 520)
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
                        Text(smartModeDisplayName(mode)).tag(mode)
                    }
                }
                .pickerStyle(.radioGroup)
                
                Text(smartModeDescription(settingsManager.smartConversionMode))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }
            
            Section(l10n.t("general.layoutSwitch")) {
                Picker(l10n.t("general.mode"), selection: $settingsManager.layoutSwitchMode) {
                    ForEach(LayoutSwitchMode.allCases, id: \.self) { mode in
                        Text(layoutSwitchModeDisplayName(mode)).tag(mode)
                    }
                }
                .pickerStyle(.radioGroup)
                
                Text(layoutSwitchModeDescription(settingsManager.layoutSwitchMode))
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
    
    // MARK: - Mode Display Helpers
    // Use l10n from @EnvironmentObject so SwiftUI re-renders on language change
    
    private func smartModeDisplayName(_ mode: SmartConversionMode) -> String {
        switch mode {
        case .lastWord: return l10n.t("smartMode.lastWord.name")
        case .greedyLine: return l10n.t("smartMode.greedyLine.name")
        case .disabled: return l10n.t("smartMode.disabled.name")
        }
    }
    
    private func smartModeDescription(_ mode: SmartConversionMode) -> String {
        switch mode {
        case .lastWord: return l10n.t("smartMode.lastWord.desc")
        case .greedyLine: return l10n.t("smartMode.greedyLine.desc")
        case .disabled: return l10n.t("smartMode.disabled.desc")
        }
    }
    
    private func layoutSwitchModeDisplayName(_ mode: LayoutSwitchMode) -> String {
        switch mode {
        case .always: return l10n.t("layoutSwitchMode.always.name")
        case .ifLastWordConverted: return l10n.t("layoutSwitchMode.ifLastWord.name")
        case .ifAnyWordConverted: return l10n.t("layoutSwitchMode.ifAnyWord.name")
        }
    }
    
    private func layoutSwitchModeDescription(_ mode: LayoutSwitchMode) -> String {
        switch mode {
        case .always: return l10n.t("layoutSwitchMode.always.desc")
        case .ifLastWordConverted: return l10n.t("layoutSwitchMode.ifLastWord.desc")
        case .ifAnyWordConverted: return l10n.t("layoutSwitchMode.ifAnyWord.desc")
        }
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
