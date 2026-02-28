import SwiftUI

struct AboutView: View {
    @EnvironmentObject var l10n: LocalizationManager
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "keyboard")
                .font(.system(size: 48))
                .foregroundStyle(.blue)
            
            Text(l10n.t("about.appName"))
                .font(.title)
                .bold()
            
            Text(l10n.t("about.version"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Text(l10n.t("about.tagline"))
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            
            Divider()
            
            VStack(spacing: 8) {
                Text(l10n.t("about.howToUse"))
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 4) {
                    Label(l10n.t("about.step1"), systemImage: "1.circle")
                    Label(l10n.t("about.step2"), systemImage: "2.circle")
                    Label(l10n.t("about.step3"), systemImage: "3.circle")
                }
                .font(.caption)
            }
            
            Divider()
            
            HStack {
                Link(l10n.t("about.github"), destination: URL(string: "https://github.com/reg2005/langSwitcher")!)
                    .font(.caption)
                
                Text("•")
                    .foregroundStyle(.secondary)
                
                Text(l10n.t("about.license"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(24)
        .frame(width: 350, height: 380)
    }
}
