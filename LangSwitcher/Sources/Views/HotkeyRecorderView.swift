import SwiftUI
import Carbon

// MARK: - Hotkey Recorder View
// Allows user to record a custom keyboard shortcut

struct HotkeyRecorderView: View {
    @Binding var keyCode: UInt16
    @Binding var modifiers: NSEvent.ModifierFlags
    @State private var isRecording = false
    @State private var monitor: Any?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Click \"Record\" and press your desired shortcut:")
                .font(.subheadline)
            
            HStack {
                if isRecording {
                    Text("Press a key combination...")
                        .foregroundStyle(.orange)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(.orange.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    Text(currentShortcutDescription)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                
                Button(isRecording ? "Cancel" : "Record") {
                    if isRecording {
                        stopRecording()
                    } else {
                        startRecording()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(isRecording ? .red : .blue)
            }
        }
    }
    
    private var currentShortcutDescription: String {
        let mods = HotkeyManager.modifierFlagsToString(modifiers)
        let key = HotkeyManager.keyCodeToString(keyCode)
        return "\(mods)\(key)"
    }
    
    private func startRecording() {
        isRecording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let eventMods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            
            // Require at least one modifier
            if eventMods.contains(.command) || eventMods.contains(.option) ||
               eventMods.contains(.control) || eventMods.contains(.shift) {
                self.keyCode = event.keyCode
                self.modifiers = eventMods
                stopRecording()
                
                // Notify that hotkey changed
                NotificationCenter.default.post(name: .hotkeySettingsChanged, object: nil)
                
                return nil // Consume the event
            }
            
            return event
        }
    }
    
    private func stopRecording() {
        isRecording = false
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
}
