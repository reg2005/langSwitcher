import SwiftUI

// MARK: - Conversion Log View (Settings Tab)

struct ConversionLogView: View {
    @ObservedObject var logStore: ConversionLogStore
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var l10n: LocalizationManager
    @State private var showClearConfirmation = false
    
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .medium
        return f
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Show disabled state when logging is off
            if !settingsManager.loggingEnabled {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "eye.slash")
                        .font(.system(size: 36))
                        .foregroundStyle(.tertiary)
                    Text(l10n.t("log.disabledTitle"))
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text(l10n.t("log.disabledHint"))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
            // Header
            HStack {
                Text(l10n.t("log.title"))
                    .font(.headline)
                
                Spacer()
                
                Text(l10n.t("log.entries").replacingOccurrences(of: "%d", with: "\(logStore.logs.count)"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Button(l10n.t("log.exportJSON")) {
                    exportJSON()
                }
                .font(.caption)
                
                Button(l10n.t("log.clearAll")) {
                    showClearConfirmation = true
                }
                .font(.caption)
                .foregroundStyle(.red)
            }
            
            Text(l10n.t("log.ratingHint"))
                .font(.caption)
                .foregroundStyle(.secondary)
            
            // Log list
            if logStore.logs.isEmpty {
                VStack {
                    Spacer()
                    Text(l10n.t("log.emptyTitle"))
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity)
                    Text(l10n.t("log.emptyHint"))
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
                        .environmentObject(l10n)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            } // end else (logging enabled)
        }
        .padding()
        .alert(l10n.t("log.clearConfirmTitle"), isPresented: $showClearConfirmation) {
            Button(l10n.t("log.cancel"), role: .cancel) {}
            Button(l10n.t("log.clearAll"), role: .destructive) {
                logStore.clearAll()
            }
        } message: {
            Text(l10n.t("log.clearConfirmMessage"))
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
        panel.title = l10n.t("log.exportPanelTitle")
        
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
    @EnvironmentObject var l10n: LocalizationManager
    
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
            .help(l10n.t("log.deleteEntry"))
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
        case nil:    return l10n.t("log.ratingUnrated")
        case true?:  return l10n.t("log.ratingCorrect")
        case false?: return l10n.t("log.ratingIncorrect")
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
