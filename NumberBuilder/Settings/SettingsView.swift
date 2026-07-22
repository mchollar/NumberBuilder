import SwiftUI
import UIKit

/// The app's real "configure/learn" entry point -- reached via a gear icon on both Explore and
/// Challenge's toolbars, so it's consistently available regardless of which tab you're on (the
/// old "i" icon only ever lived on Explore's toolbar, which is exactly the friction this screen
/// exists to fix). `AboutView` is purely informational now (icon/name/version, developer,
/// copyright) -- everything actionable that used to live there (Rate, Feedback, Share, the debug
/// menu) lives here instead.
struct SettingsView: View {
    @State private var isShowingMailComposer = false
    @State private var isShowingMailUnavailableAlert = false

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    private static let appStoreURL = URL(string: "https://itunes.apple.com/app/id1489526164")!

    var body: some View {
        List {
            Section {
                NavigationLink {
                    DiceAppearanceView()
                } label: {
                    settingsRow("Dice Appearance", systemImage: "die.face.5.fill", tint: .pink)
                }
                NavigationLink {
                    HowToPlayView()
                } label: {
                    settingsRow("How to Play", systemImage: "questionmark.circle.fill", tint: .nbAccent)
                }
            }
            .listRowBackground(Color.nbCardSurface)

            Section {
                Button {
                    openReviewPage()
                } label: {
                    settingsRow("Rate Number Builder", systemImage: "star.fill", tint: .yellow)
                }
                Button {
                    if MailComposeView.canSendMail {
                        isShowingMailComposer = true
                    } else {
                        isShowingMailUnavailableAlert = true
                    }
                } label: {
                    settingsRow("Send Feedback", systemImage: "envelope.fill", tint: .green)
                }
                ShareLink(item: Self.appStoreURL) {
                    settingsRow("Share Number Builder", systemImage: "square.and.arrow.up.fill", tint: .blue)
                }
            } footer: {
                Text("No data is collected. No ads, ever.")
            }
            .listRowBackground(Color.nbCardSurface)

            Section {
                NavigationLink {
                    PurchasesView()
                } label: {
                    settingsRow("Purchases", systemImage: "cart.fill", tint: .brown)
                }
            }
            .listRowBackground(Color.nbCardSurface)

            Section {
                NavigationLink {
                    AboutView()
                } label: {
                    settingsRow("About Number Builder", systemImage: "info.circle.fill", tint: .indigo)
                }
            }
            .listRowBackground(Color.nbCardSurface)

            #if DEBUG
            Section {
                NavigationLink {
                    DebugMenuView()
                } label: {
                    settingsRow("Debug Menu", systemImage: "ladybug.fill", tint: .gray)
                }
            }
            .listRowBackground(Color.nbCardSurface)
            #endif
        }
        .scrollContentBackground(.hidden)
        .readableContentWidth()
        .background(Color.nbBackground)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isShowingMailComposer) {
            MailComposeView(
                recipient: "support@widgetilities.com",
                subject: "Feedback for Number Builder \(appVersion)"
            )
        }
        .alert("Unable to Send Mail", isPresented: $isShowingMailUnavailableAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please check settings and enable Mail.")
        }
    }

    /// Every row used to render a plain black/white SF Symbol regardless of what it did, which read
    /// as flat and undifferentiated. A tinted rounded-square badge behind each icon (mirroring
    /// iOS's own Settings app, and reusing colors already established elsewhere in the app --
    /// `MathOperation.accentColor`'s palette, `SolutionTier.accentColor`'s red) breaks that up
    /// without introducing a whole new palette. A single `.opacity()` on the tint for the badge
    /// background looks right in both light and dark mode without separate-casing either.
    private func settingsRow(_ title: String, systemImage: String, tint: Color) -> some View {
        Label {
            Text(title)
                .foregroundStyle(Color.primary)
        } icon: {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(tint.accessibleIconTint(against: .nbCardSurface))
                .frame(width: 30, height: 30)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(tint.opacity(NBMetrics.iconBadgeWashOpacity))
                )
        }
    }

    private func openReviewPage() {
        guard let url = URL(string: "https://itunes.apple.com/app/id1489526164?action=write-review") else { return }
        UIApplication.shared.open(url)
    }
}

#Preview("Settings") {
    NavigationStack {
        SettingsView()
    }
}
