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
                    Label("Dice Appearance", systemImage: "die.face.5.fill")
                        .foregroundStyle(Color.primary)
                }
                NavigationLink {
                    HowToPlayView()
                } label: {
                    Label("How to Play", systemImage: "questionmark.circle.fill")
                        .foregroundStyle(Color.primary)
                }
            }
            .listRowBackground(Color.nbCardSurface)

            Section {
                Button {
                    openReviewPage()
                } label: {
                    Label("Rate Number Builder", systemImage: "star.fill")
                        .foregroundStyle(Color.primary)
                }
                Button {
                    if MailComposeView.canSendMail {
                        isShowingMailComposer = true
                    } else {
                        isShowingMailUnavailableAlert = true
                    }
                } label: {
                    Label("Send Feedback", systemImage: "envelope.fill")
                        .foregroundStyle(Color.primary)
                }
                ShareLink(item: Self.appStoreURL) {
                    Label("Share Number Builder", systemImage: "square.and.arrow.up.fill")
                        .foregroundStyle(Color.primary)
                }
            } footer: {
                Text("No data is collected. No ads, ever.")
            }
            .listRowBackground(Color.nbCardSurface)

            Section {
                NavigationLink {
                    AboutView()
                } label: {
                    Label("About Number Builder", systemImage: "info.circle.fill")
                        .foregroundStyle(Color.primary)
                }
            }
            .listRowBackground(Color.nbCardSurface)

            #if DEBUG
            Section {
                NavigationLink {
                    DebugMenuView()
                } label: {
                    Label("Debug Menu", systemImage: "ladybug.fill")
                        .foregroundStyle(Color.primary)
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
