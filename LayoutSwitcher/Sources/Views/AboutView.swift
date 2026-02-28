import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "keyboard")
                .font(.system(size: 48))
                .foregroundStyle(.blue)
            
            Text("LayoutSwitcher")
                .font(.title)
                .bold()
            
            Text("Version 1.0.0")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Text("Open-source keyboard layout text converter for macOS")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            
            Divider()
            
            VStack(spacing: 8) {
                Text("How to use:")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 4) {
                    Label("Select text typed in wrong layout", systemImage: "1.circle")
                    Label("Press your hotkey (default: ⌥S)", systemImage: "2.circle")
                    Label("Text is automatically converted!", systemImage: "3.circle")
                }
                .font(.caption)
            }
            
            Divider()
            
            HStack {
                Link("GitHub", destination: URL(string: "https://github.com/nicklama/LayoutSwitcher")!)
                    .font(.caption)
                
                Text("•")
                    .foregroundStyle(.secondary)
                
                Text("MIT License")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(24)
        .frame(width: 350, height: 380)
    }
}
