import SwiftUI
import UIKit

struct AboutView: View {
    @State private var isShowingMailComposer = false
    @State private var isShowingMailUnavailableAlert = false

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }
    private var appBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
    }

    private static let appStoreURL = URL(string: "https://itunes.apple.com/app/id1489526164")!

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
                    Text("\(appVersion) (\(appBuild))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .listRowBackground(Color.clear)

            Section {
                NavigationLink {
                    HowToPlayView()
                } label: {
                    Label("How to Play", systemImage: "questionmark.circle.fill")
                        .foregroundStyle(Color.nbAccent)
                }
            }
            .listRowBackground(Color.nbCardSurface)

            Section {
                Button {
                    openReviewPage()
                } label: {
                    Label("Rate Number Builder", systemImage: "star.fill")
                        .foregroundStyle(Color.nbAccent)
                }
                Button {
                    if MailComposeView.canSendMail {
                        isShowingMailComposer = true
                    } else {
                        isShowingMailUnavailableAlert = true
                    }
                } label: {
                    Label("Send Feedback", systemImage: "envelope.fill")
                        .foregroundStyle(Color.nbAccent)
                }
                ShareLink(item: Self.appStoreURL) {
                    Label("Share Number Builder", systemImage: "square.and.arrow.up.fill")
                        .foregroundStyle(Color.nbAccent)
                }
            } footer: {
                Text("No data is collected. No ads, ever.")
            }
            .listRowBackground(Color.nbCardSurface)
        }
        .scrollContentBackground(.hidden)
        .background(Color.nbBackground)
        .navigationTitle("About")
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

#Preview("About") {
    NavigationStack {
        AboutView()
    }
}
