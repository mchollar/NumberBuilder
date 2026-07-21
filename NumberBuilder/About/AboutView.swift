import SwiftUI
import UIKit

/// Reads the actual rendered app icon out of the bundle rather than keeping a second, separately
/// maintained copy of the icon artwork as its own asset -- one source of truth for "what does
/// Number Builder's icon look like," so it can't quietly drift out of sync with the real one.
private extension Bundle {
    var iconFileName: String? {
        guard let icons = infoDictionary?["CFBundleIcons"] as? [String: Any],
              let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
              let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String]
        else { return nil }
        return iconFiles.last
    }
}

/// Purely informational -- icon/name/version, then static developer/copyright facts. Everything
/// actionable (Rate, Feedback, Share, the debug menu) lives in `SettingsView` now, which is also
/// where this screen is reached from.
struct AboutView: View {
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }
    private var appBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
    }
    /// Number Builder itself dates from 2020 -- distinct from Widgetilities LLC's own 2019
    /// founding date, which isn't what a copyright notice on this particular app should reflect.
    /// Computed rather than a fixed "2020–2026" so the range doesn't quietly go stale on its own.
    private var copyrightYearRange: String {
        let currentYear = Calendar.current.component(.year, from: Date())
        return currentYear > 2020 ? "2020–\(currentYear)" : "2020"
    }
    private var appIconImage: Image {
        if let iconFileName = Bundle.main.iconFileName, let uiImage = UIImage(named: iconFileName) {
            return Image(uiImage: uiImage)
        }
        return Image(systemName: "app.fill")
    }

    var body: some View {
        List {
            Section {
                VStack(spacing: 12) {
                    appIconImage
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 96, height: 96)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .cardSurface()
                    Text("Number Builder")
                        .nbNumberFont(22)
                    Text("Version \(appVersion) (\(appBuild))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .listRowBackground(Color.clear)

            Section {
                infoRow("Developer", "Widgetilities LLC")
                infoRow("Copyright", "© \(copyrightYearRange)")
            }
            .listRowBackground(Color.nbCardSurface)
        }
        .scrollContentBackground(.hidden)
        .readableContentWidth()
        .background(Color.nbBackground)
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(Color.primary)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview("About") {
    NavigationStack {
        AboutView()
    }
}
