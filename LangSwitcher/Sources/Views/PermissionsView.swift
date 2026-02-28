import SwiftUI

struct PermissionsView: View {
    @EnvironmentObject var l10n: LocalizationManager
    @State private var hasAccessibility = AccessibilityService.hasAccessibilityPermission
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(l10n.t("permissions.title"))
                .font(.headline)
            
            Text(l10n.t("permissions.description"))
                .font(.caption)
                .foregroundStyle(.secondary)
            
            GroupBox {
                HStack {
                    Image(systemName: hasAccessibility ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(hasAccessibility ? .green : .orange)
                        .font(.title2)
                    
                    VStack(alignment: .leading) {
                        Text(l10n.t("permissions.accessibilityTitle"))
                            .font(.body)
                            .bold()
                        Text(hasAccessibility ? l10n.t("permissions.granted") : l10n.t("permissions.notGranted"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    if !hasAccessibility {
                        Button(l10n.t("permissions.grantAccess")) {
                            AccessibilityService.requestAccessibilityPermission()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding(4)
            }
            
            if !hasAccessibility {
                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(l10n.t("permissions.howToEnable"))
                            .font(.subheadline)
                            .bold()
                        
                        Text(l10n.t("permissions.step1"))
                        Text(l10n.t("permissions.step2"))
                        Text(l10n.t("permissions.step3"))
                        Text(l10n.t("permissions.step4"))
                    }
                    .font(.caption)
                    .padding(4)
                }
                
                Button(l10n.t("permissions.openSettings")) {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
            
            Spacer()
            
            Button(l10n.t("permissions.refreshStatus")) {
                hasAccessibility = AccessibilityService.hasAccessibilityPermission
            }
            .font(.caption)
        }
        .padding()
    }
}
