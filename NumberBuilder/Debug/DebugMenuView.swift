import SwiftUI

/// Dev-only tools for resetting in-app state that's otherwise awkward to reach (onboarding
/// flags, and eventually IAP entitlement/purchase state) without deleting and reinstalling the
/// app. Never compiled into a release build -- `AboutView` only links to this behind `#if DEBUG`.
struct DebugMenuView: View {
    @AppStorage(DebugResettableFlag.hasSeenChallengeIntroKey) private var hasSeenChallengeIntro = false

    var body: some View {
        List {
            Section {
                Toggle("Challenge intro seen", isOn: $hasSeenChallengeIntro)
            } header: {
                Text("Onboarding")
            } footer: {
                Text("Turn off to see the Challenge intro sheet again next time you open the Challenge tab.")
            }
            .listRowBackground(Color.nbCardSurface)

            #if DEBUG
            Section {
                Toggle("Force Challenge Unlocked", isOn: Binding(
                    get: { PurchaseManager.shared.isUnlocked },
                    set: { PurchaseManager.shared.debugSetUnlocked($0) }
                ))
                Button("Reset Free Puzzle Counter", role: .destructive) {
                    PurchaseManager.shared.debugResetFreePuzzlesUsed()
                }
            } header: {
                Text("In-App Purchase")
            } footer: {
                Text("Free puzzles used: \(PurchaseManager.shared.freePuzzlesUsed)/\(PurchaseManager.freeTrialLimit)")
            }
            .listRowBackground(Color.nbCardSurface)
            #endif
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
