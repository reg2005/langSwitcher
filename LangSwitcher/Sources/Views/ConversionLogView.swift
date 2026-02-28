import SwiftUI

// MARK: - Conversion Log View (Settings Tab)

struct ConversionLogView: View {
    @ObservedObject var logStore: ConversionLogStore
    @State private var showClearConfirmation = false
    
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .medium
        return f
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text("Conversion Log")
                    .font(.headline)
                
                Spacer()
                
                Text("\(logStore.logs.count) entries")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Button("Export JSON") {
                    exportJSON()
                }
                .font(.caption)
                
                Button("Clear All") {
                    showClearConfirmation = true
                }
                .font(.caption)
                .foregroundStyle(.red)
            }
            
            Text("Rate each conversion as correct or incorrect to build training data. Click to cycle: unrated -> correct -> incorrect -> unrated.")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            // Log list
            if logStore.logs.isEmpty {
                VStack {
                    Spacer()
                    Text("No conversions logged yet.")
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity)
                    Text("Use the hotkey to convert text and entries will appear here.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
            } else {
                List {
                    ForEach(logStore.logs) { entry in
                        ConversionLogRow(
                            entry: entry,
                            dateFormatter: dateFormatter,
                            onToggleRating: { toggleRating(entry: entry) },
                            onDelete: { logStore.delete(id: entry.id) }
                        )
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .alert("Clear All Logs?", isPresented: $showClearConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Clear All", role: .destructive) {
                logStore.clearAll()
            }
        } message: {
            Text("This will permanently delete all conversion log entries. This cannot be undone.")
        }
    }
    
    // MARK: - Rating Cycle
    
    /// Cycle: nil -> true -> false -> nil
    private func toggleRating(entry: ConversionLog) {
        let newValue: Bool?
        switch entry.isCorrect {
        case nil:   newValue = true
        case true?:  newValue = false
        case false?: newValue = nil
        }
        logStore.updateRating(id: entry.id, isCorrect: newValue)
    }
    
    // MARK: - Export
    
    private func exportJSON() {
        let json = logStore.exportJSON()
        
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "conversion_log.json"
        panel.title = "Export Conversion Log"
        
        if panel.runModal() == .OK, let url = panel.url {
            do {
                try json.write(to: url, atomically: true, encoding: .utf8)
                NSLog("[LangSwitcher] Exported \(logStore.logs.count) log entries to \(url.path)")
            } catch {
                NSLog("[LangSwitcher] Export failed: \(error)")
            }
        }
    }
}

// MARK: - Log Row

struct ConversionLogRow: View {
    let entry: ConversionLog
    let dateFormatter: DateFormatter
    let onToggleRating: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Rating button (tri-state)
            Button(action: onToggleRating) {
                ratingIcon
                    .font(.title2)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .help(ratingTooltip)
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(entry.inputText)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.red.opacity(0.8))
                        .lineLimit(1)
                    
                    Text("->")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(entry.outputText)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.green.opacity(0.8))
                        .lineLimit(1)
                }
                
                HStack(spacing: 8) {
                    Text(dateFormatter.string(from: entry.timestamp))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    
                    Text(entry.conversionMode)
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(.blue.opacity(0.1))
                        .clipShape(Capsule())
                    
                    Text(shortLayout(entry.sourceLayout) + " -> " + shortLayout(entry.targetLayout))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            
            Spacer()
            
            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Delete this entry")
        }
        .padding(.vertical, 2)
    }
    
    // MARK: - Rating Icon
    
    @ViewBuilder
    private var ratingIcon: some View {
        switch entry.isCorrect {
        case nil:
            Image(systemName: "circle")
                .foregroundStyle(.secondary)
        case true?:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case false?:
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.red)
        }
    }
    
    private var ratingTooltip: String {
        switch entry.isCorrect {
        case nil:    return "Unrated — click to mark as correct"
        case true?:  return "Correct — click to mark as incorrect"
        case false?: return "Incorrect — click to clear rating"
        }
    }
    
    // MARK: - Helpers
    
    private func shortLayout(_ layoutID: String) -> String {
        // "com.apple.keylayout.Russian" -> "Russian"
        if let last = layoutID.split(separator: ".").last {
            return String(last)
        }
        return layoutID
    }
}
