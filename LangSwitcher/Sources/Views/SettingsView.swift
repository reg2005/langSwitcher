import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralSettingsTab()
                .environmentObject(settingsManager)
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(0)
            
            LayoutsSettingsTab()
                .environmentObject(settingsManager)
                .tabItem {
                    Label("Layouts", systemImage: "keyboard")
                }
                .tag(1)
            
            HotkeySettingsTab()
                .environmentObject(settingsManager)
                .tabItem {
                    Label("Hotkey", systemImage: "command")
                }
                .tag(2)
            
            PermissionsView()
                .tabItem {
                    Label("Permissions", systemImage: "lock.shield")
                }
                .tag(3)
        }
        .frame(width: 520, height: 400)
        .padding()
    }
}

// MARK: - General Settings

struct GeneralSettingsTab: View {
    @EnvironmentObject var settingsManager: SettingsManager
    
    var body: some View {
        Form {
            Section {
                Toggle("Launch at Login", isOn: $settingsManager.launchAtLogin)
                Toggle("Play Sound on Conversion", isOn: $settingsManager.playSounds)
                Toggle("Show Notifications", isOn: $settingsManager.showNotifications)
            }
            
            Section("Smart Conversion (No Selection)") {
                Picker("Mode:", selection: $settingsManager.smartConversionMode) {
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
            
            Section("How It Works") {
                Text("When text is selected, the shortcut converts the selection.\nWhen no text is selected, the behavior depends on the Smart Conversion mode above.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Section("Statistics") {
                HStack {
                    Text("Total Conversions:")
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Keyboard Layouts")
                .font(.headline)
            
            Text("These layouts are detected from your system keyboard settings. The converter maps characters between them based on physical key positions.")
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
                Button("Refresh from System") {
                    settingsManager.refreshSystemLayouts()
                }
                
                Spacer()
                
                Text("\(settingsManager.enabledLayouts.count) layouts detected")
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Keyboard Shortcut")
                .font(.headline)
            
            Text("Press this shortcut to convert text. If text is selected it converts the selection; otherwise it auto-selects the last word.")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            // Current shortcut display
            HStack {
                Text("Current shortcut:")
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
            Toggle("Use Double Shift (⇧⇧) as shortcut", isOn: $settingsManager.useDoubleShift)
                .toggleStyle(.switch)
            
            Text("Quickly press Shift twice to trigger conversion. This is the recommended shortcut — fast and doesn't conflict with other apps.")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            if !settingsManager.useDoubleShift {
                Divider()
                
                Text("Custom Shortcut")
                    .font(.subheadline)
                    .bold()
                
                HotkeyRecorderView(
                    keyCode: $settingsManager.hotkeyKeyCode,
                    modifiers: Binding(
                        get: { settingsManager.hotkeyModifierFlags },
                        set: { settingsManager.hotkeyModifierFlags = $0 }
                    )
                )
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
