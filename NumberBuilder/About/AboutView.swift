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

    var body: some View {
        List {
            Section {
                VStack(spacing: 12) {
                    Image("NumberBuilder Icon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 96, height: 96)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .cardShadow()
                    Text("Number Builder")
                        .font(.title2.bold())
                    Text("\(appVersion) (\(appBuild))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .listRowBackground(Color.clear)

            Section {
                Button {
                    openReviewPage()
                } label: {
                    Label("Rate Number Builder", systemImage: "star")
                }
                Button {
                    if MailComposeView.canSendMail {
                        isShowingMailComposer = true
                    } else {
                        isShowingMailUnavailableAlert = true
                    }
                } label: {
                    Label("Send Feedback", systemImage: "envelope")
                }
            }
        }
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
