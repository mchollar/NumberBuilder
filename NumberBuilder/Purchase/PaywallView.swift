import SwiftUI

/// Shown two ways: as a forced, non-dismissable substitute for Challenge's own content once the
/// free trial is exhausted (`ChallengeView`'s body swaps to this instead of the puzzle UI, no
/// dismiss path at all -- there's nothing behind it to go "back" to), and as a voluntary,
/// dismissable `.sheet` reached by tapping the trial banner before the cap is hit. `onDismiss`
/// being non-nil is what distinguishes the two -- pass it only for the sheet presentation.
struct PaywallView: View {
    var onDismiss: (() -> Void)?

    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var errorMessage: String?

    private var purchaseManager: PurchaseManager { PurchaseManager.shared }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let onDismiss {
                    HStack {
                        Spacer()
                        Button {
                            onDismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                VStack(spacing: 16) {
                    Text("Unlock Challenge Mode")
                        .font(.nbNumber(28))
                        .multilineTextAlignment(.center)

                    Text(subtitle)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    // A static preview so a kid can show a parent what they'd be unlocking
                    // without needing functional access to Challenge itself.
                    Image("ChallengePreview")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 320)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(Color.cardBorder, lineWidth: 1)
                        )
                }
                .padding(20)
                .cardSurface()

                VStack(spacing: 12) {
                    Button {
                        purchase()
                    } label: {
                        if isPurchasing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text(purchaseButtonTitle)
                        }
                    }
                    .buttonStyle(.nbPrimary(isEnabled: !isPurchasing && !isRestoring))
                    .disabled(isPurchasing || isRestoring)

                    Button {
                        restore()
                    } label: {
                        if isRestoring {
                            ProgressView()
                        } else {
                            Text("Restore Purchases")
                        }
                    }
                    .buttonStyle(.nbTonal(isEnabled: !isPurchasing && !isRestoring))
                    .disabled(isPurchasing || isRestoring)
                }

                Text("One purchase unlocks Challenge mode for your whole family via Family Sharing.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(20)
            .readableContentWidth()
        }
        .background(Color.nbBackground.ignoresSafeArea())
        .task {
            await purchaseManager.loadProduct()
        }
        .alert("Something Went Wrong", isPresented: .init(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    /// This screen is reachable two ways -- forced once the free trial is exhausted, or tapped
    /// into voluntarily from the trial banner while puzzles remain -- so the copy needs to match
    /// whichever is actually true instead of always claiming the trial is used up.
    private var subtitle: String {
        let remaining = max(0, PurchaseManager.freeTrialLimit - purchaseManager.freePuzzlesUsed)
        if remaining > 0 {
            return "You have \(remaining) free puzzle\(remaining == 1 ? "" : "s") left. Unlock unlimited puzzles across every difficulty level, for your whole family, anytime."
        }
        return "You've used your \(PurchaseManager.freeTrialLimit) free puzzles. Unlock unlimited puzzles across every difficulty level, for your whole family."
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
                if purchaseManager.isUnlocked {
                    onDismiss?()
                }
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
            if purchaseManager.isUnlocked {
                onDismiss?()
            }
        }
    }
}

#Preview("Paywall - Forced") {
    PaywallView()
}

#Preview("Paywall - Sheet") {
    NavigationStack {
        Color.clear
            .sheet(isPresented: .constant(true)) {
                PaywallView(onDismiss: {})
            }
    }
}
