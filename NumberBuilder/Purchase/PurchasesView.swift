import SwiftUI

/// Settings' persistent home for purchase state -- distinct from `PaywallView`, which only ever
/// appears when Challenge mode itself needs to interrupt or offer an upsell. This screen is the
/// place a player (or a parent) can check status, read what the purchase includes, buy, or
/// restore at any time, unlocked or not -- reachable from `SettingsView` regardless of trial state.
struct PurchasesView: View {
    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var errorMessage: String?
    @State private var isShowingRestoreResultAlert = false
    @State private var restoreResultMessage = ""

    private var purchaseManager: PurchaseManager { PurchaseManager.shared }

    var body: some View {
        List {
            Section {
                statusRow
            }
            .listRowBackground(Color.nbCardSurface)

            Section {
                Text("Unlock Challenge Mode gives you unlimited puzzles across every difficulty level. One purchase covers your whole family via Family Sharing.")
                    .foregroundStyle(.secondary)
            }
            .listRowBackground(Color.nbCardSurface)

            if !purchaseManager.isUnlocked {
                Section {
                    Button {
                        purchase()
                    } label: {
                        HStack {
                            Text(purchaseButtonTitle)
                                .foregroundStyle(Color.primary)
                            Spacer()
                            if isPurchasing {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isPurchasing || isRestoring)
                }
                .listRowBackground(Color.nbCardSurface)
            }

            Section {
                Button {
                    restore()
                } label: {
                    HStack {
                        Label("Restore Purchases", systemImage: "arrow.clockwise")
                            .foregroundStyle(Color.primary)
                        Spacer()
                        if isRestoring {
                            ProgressView()
                        }
                    }
                }
                .disabled(isPurchasing || isRestoring)
            } footer: {
                Text("Already purchased on another device, or part of a Family Sharing group? Restore to unlock here too.")
            }
            .listRowBackground(Color.nbCardSurface)
        }
        .scrollContentBackground(.hidden)
        .readableContentWidth()
        .background(Color.nbBackground)
        .navigationTitle("Purchases")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await purchaseManager.loadProduct()
        }
        .alert("Something Went Wrong", isPresented: .init(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
        .alert("Restore Purchases", isPresented: $isShowingRestoreResultAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(restoreResultMessage)
        }
    }

    private var statusRow: some View {
        HStack {
            if purchaseManager.isUnlocked {
                Label("Challenge Mode Unlocked", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(.green)
            } else {
                Label("Free Trial", systemImage: "hourglass")
                    .foregroundStyle(Color.primary)
                Spacer()
                Text("\(remainingFreePuzzles) puzzle\(remainingFreePuzzles == 1 ? "" : "s") left")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var remainingFreePuzzles: Int {
        max(0, PurchaseManager.freeTrialLimit - purchaseManager.freePuzzlesUsed)
    }

    private var purchaseButtonTitle: String {
        if let price = purchaseManager.product?.displayPrice {
            return "Unlock Challenge Mode — \(price)"
        }
        return "Unlock Challenge Mode"
    }

    private func purchase() {
        guard PurchaseManager.passesParentalGate() else { return }
        isPurchasing = true
        Task {
            defer { isPurchasing = false }
            do {
                try await purchaseManager.purchase()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func restore() {
        isRestoring = true
        Task {
            defer { isRestoring = false }
            await purchaseManager.restorePurchases()
            restoreResultMessage = purchaseManager.isUnlocked
                ? "Challenge mode is unlocked on this device."
                : "No previous purchase was found for this Apple ID."
            isShowingRestoreResultAlert = true
        }
    }
}

#Preview("Purchases - Locked") {
    NavigationStack {
        PurchasesView()
    }
}

#Preview("Purchases - Unlocked") {
    PurchaseManager.shared.debugSetUnlocked(true)
    return NavigationStack {
        PurchasesView()
    }
}
