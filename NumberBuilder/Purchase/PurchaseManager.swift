import Foundation
import Observation
import StoreKit

/// Owns Challenge mode's free-trial/purchase state -- a single shared instance rather than
/// per-screen state, since Explore and Challenge are two independent `NavigationStack`s under the
/// same `TabView` and both need the same answer to "has this device unlocked Challenge." Mirrors
/// this app's existing static-shared-instance pattern (`AppLogger`) rather than introducing
/// SwiftUI environment-object injection for the first time.
@Observable
@MainActor
final class PurchaseManager {
    static let shared = PurchaseManager()

    /// Must match whatever non-consumable product the user creates in App Store Connect (or the
    /// local `Configuration.storekit` file used for development/testing).
    static let productID = "Widgetilities.NumberBuilder.unlockChallenge"
    static let freeTrialLimit = 3

    private(set) var isUnlocked = false
    private(set) var product: Product?

    /// How many free puzzles have been completed/revealed toward the trial limit -- persisted so
    /// it survives relaunches, using the same shared-key pattern as every other cross-file
    /// `UserDefaults` value in this app (see `DebugResettableFlag`).
    private(set) var freePuzzlesUsed: Int {
        didSet {
            UserDefaults.standard.set(freePuzzlesUsed, forKey: DebugResettableFlag.freeChallengePuzzlesUsedKey)
        }
    }

    var hasChallengeAccess: Bool {
        isUnlocked || freePuzzlesUsed < Self.freeTrialLimit
    }

    private var transactionListenerTask: Task<Void, Never>?

    private init() {
        freePuzzlesUsed = UserDefaults.standard.integer(forKey: DebugResettableFlag.freeChallengePuzzlesUsedKey)
        // Long-lived for the app's lifetime -- catches purchases/restores/Family Sharing
        // entitlements that arrive asynchronously (e.g. Ask to Buy approval, or a family
        // member's purchase syncing), not just ones this device's own purchase() call initiated.
        transactionListenerTask = Task { [weak self] in
            await self?.observeTransactionUpdates()
        }
        Task { [weak self] in
            await self?.loadProduct()
            await self?.refreshEntitlement()
        }
    }

    /// No-ops once already unlocked -- once purchased, there's nothing left to count toward.
    func recordFreePuzzleCompletion() {
        guard !isUnlocked else { return }
        freePuzzlesUsed += 1
        AppLogger.purchase.debug("Free puzzle completion recorded: \(self.freePuzzlesUsed)/\(Self.freeTrialLimit)")
    }

    func loadProduct() async {
        guard product == nil else { return }
        do {
            let products = try await Product.products(for: [Self.productID])
            product = products.first
            if product == nil {
                AppLogger.purchase.error("No product returned for id \(Self.productID) -- check the StoreKit configuration or App Store Connect product")
            }
        } catch {
            AppLogger.purchase.error("Failed to load product \(Self.productID): \(error.localizedDescription)")
        }
    }

    func purchase() async throws {
        if product == nil {
            await loadProduct()
        }
        guard let product else { return }
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            if case .verified(let transaction) = verification {
                isUnlocked = true
                await transaction.finish()
                AppLogger.purchase.debug("Purchase succeeded")
            }
        case .userCancelled, .pending:
            break
        @unknown default:
            break
        }
    }

    func restorePurchases() async {
        try? await AppStore.sync()
        await refreshEntitlement()
    }

    /// Placeholder for Apple's required parental-gate step (Guideline 1.3) before showing a
    /// purchase flow in an app with a child audience -- whether it's strictly required here still
    /// depends on an unresolved Kids Category question. Lives here (not on any one view) so every
    /// purchase entry point -- the forced/voluntary paywall and the Purchases screen in Settings --
    /// shares exactly one hook; wiring in a real gate later (a two-digit multiplication problem is
    /// the leading candidate) only needs to change this one function.
    static func passesParentalGate() -> Bool {
        true // TODO: parental gate not yet implemented -- see plan file for context.
    }

    private func refreshEntitlement() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result, transaction.productID == Self.productID {
                isUnlocked = true
                return
            }
        }
    }

    private func observeTransactionUpdates() async {
        for await result in Transaction.updates {
            guard case .verified(let transaction) = result, transaction.productID == Self.productID else { continue }
            isUnlocked = true
            await transaction.finish()
            AppLogger.purchase.debug("Transaction update unlocked Challenge mode")
        }
    }

    #if DEBUG
    /// Bypasses real entitlement checks entirely -- for quickly exercising both the paywalled and
    /// unlocked UI states without completing an actual StoreKit transaction each time.
    func debugSetUnlocked(_ value: Bool) {
        isUnlocked = value
    }

    func debugResetFreePuzzlesUsed() {
        freePuzzlesUsed = 0
    }
    #endif
}
