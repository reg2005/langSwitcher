import SwiftUI

struct PermissionsView: View {
    @State private var hasAccessibility = AccessibilityService.hasAccessibilityPermission
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Permissions")
                .font(.headline)
            
            Text("LayoutSwitcher needs Accessibility access to read and replace selected text in other applications.")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            GroupBox {
                HStack {
                    Image(systemName: hasAccessibility ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(hasAccessibility ? .green : .orange)
                        .font(.title2)
                    
                    VStack(alignment: .leading) {
                        Text("Accessibility Access")
                            .font(.body)
                            .bold()
                        Text(hasAccessibility ? "Granted — LayoutSwitcher can convert text" : "Not granted — Please enable in System Settings")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    if !hasAccessibility {
                        Button("Grant Access") {
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
                        Text("How to enable:")
                            .font(.subheadline)
                            .bold()
                        
                        Text("1. Open System Settings > Privacy & Security > Accessibility")
                        Text("2. Click the lock icon to make changes")
                        Text("3. Enable LayoutSwitcher in the list")
                        Text("4. Restart LayoutSwitcher if needed")
                    }
                    .font(.caption)
                    .padding(4)
                }
                
                Button("Open System Settings") {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
            
            Spacer()
            
            Button("Refresh Status") {
                hasAccessibility = AccessibilityService.hasAccessibilityPermission
            }
            .font(.caption)
        }
        .padding()
    }
}
