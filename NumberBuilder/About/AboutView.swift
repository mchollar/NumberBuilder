import SwiftUI

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

    var body: some View {
        List {
            Section {
                VStack(spacing: 12) {
                    Image("NumberBuilder Icon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 96, height: 96)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .cardSurface()
                    Text("Number Builder")
                        .font(.nbNumber(22))
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
