import SwiftUI

/// Dev-only tools for resetting in-app state that's otherwise awkward to reach (onboarding
/// flags, and eventually IAP entitlement/purchase state) without deleting and reinstalling the
/// app. Never compiled into a release build -- `AboutView` only links to this behind `#if DEBUG`.
struct DebugMenuView: View {
    @AppStorage(DebugResettableFlag.hasSeenPracticeIntroKey) private var hasSeenPracticeIntro = false

    var body: some View {
        List {
            Section {
                Toggle("Practice intro seen", isOn: $hasSeenPracticeIntro)
            } header: {
                Text("Onboarding")
            } footer: {
                Text("Turn off to see the Practice intro sheet again next time you open the Practice tab.")
            }
            .listRowBackground(Color.nbCardSurface)
        }
        .scrollContentBackground(.hidden)
        .readableContentWidth()
        .background(Color.nbBackground)
        .navigationTitle("Debug Menu")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Debug Menu") {
    NavigationStack {
        DebugMenuView()
    }
}
