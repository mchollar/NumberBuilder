import Foundation
import Observation
import NumberBuilderKit

/// Drives the tap-to-build workspace: a fixed die/op/die/op/die pattern (classic 3-dice puzzles)
/// filled in strictly left to right, mirroring exactly how `Solution.expressionTokens` renders a
/// finished answer -- the parens are always visible from the start, before anything is placed, so
/// the left-to-right grouping is never a mystery.
@Observable
@MainActor
final class PracticeViewModel {
    private(set) var tier: SolutionTier
    private(set) var puzzle: PracticeGenerator.Puzzle
    private(set) var placedDice: [DieValue?]
    private(set) var placedOperations: [MathOperation?]
    private(set) var trayIndexForDieSlot: [Int?]

    enum Feedback: Equatable {
        case none
        case correct
        case incorrect(got: Int)
    }
    private(set) var feedback: Feedback = .none

    /// The die slot a tray tap most recently placed, while it's still open to a power/root
    /// change -- cleared the moment the following operator is chosen (or, for the last die,
    /// left open until Submit/New Puzzle since there's no following operator to lock it in).
    private(set) var activeDieSlot: Int?
    /// Every legal power/root this die could stand in as, given the operator right before it
    /// (or every plain-tier variant if there's nothing before it yet). Always includes the
    /// plain value placed on tap; more than one entry only past `.basic`.
    private(set) var activeVariantOptions: [DieValue] = []

    init(tier: SolutionTier = .basic) {
        self.tier = tier
        let puzzle = PracticeGenerator.generate(tier: tier)
        self.puzzle = puzzle
        self.placedDice = Array(repeating: nil, count: puzzle.dice.count)
        self.placedOperations = Array(repeating: nil, count: puzzle.dice.count - 1)
        self.trayIndexForDieSlot = Array(repeating: nil, count: puzzle.dice.count)
    }

    func selectTier(_ newTier: SolutionTier) {
        guard newTier != tier else { return }
        tier = newTier
        newPuzzle()
    }

    func newPuzzle() {
        puzzle = PracticeGenerator.generate(tier: tier)
        placedDice = Array(repeating: nil, count: puzzle.dice.count)
        placedOperations = Array(repeating: nil, count: puzzle.dice.count - 1)
        trayIndexForDieSlot = Array(repeating: nil, count: puzzle.dice.count)
        feedback = .none
        activeDieSlot = nil
        activeVariantOptions = []
    }

    var usedTrayIndices: Set<Int> {
        Set(trayIndexForDieSlot.compactMap { $0 })
    }

    private var nextDieSlot: Int? { placedDice.firstIndex(where: { $0 == nil }) }
    private var nextOperationSlot: Int? { placedOperations.firstIndex(where: { $0 == nil }) }

    /// True exactly when the next open slot is a die -- i.e. every operation before it is
    /// already filled (or there are none yet, for the very first die).
    var isAwaitingDie: Bool {
        guard let dieSlot = nextDieSlot else { return false }
        return placedOperations.prefix(dieSlot).allSatisfy { $0 != nil }
    }

    var isAwaitingOperation: Bool {
        guard let opSlot = nextOperationSlot else { return false }
        return placedDice[opSlot] != nil
    }

    var isComplete: Bool {
        placedDice.allSatisfy { $0 != nil } && placedOperations.allSatisfy { $0 != nil }
    }

    /// The value built from dice `[0..<slot)` combined by operators `[0..<slot-1)`, or nil
    /// before the first die lands -- deliberately excludes `slot` itself so it can be used to
    /// validate candidates *for* that slot without circularity.
    private func accumulator(before slot: Int) -> Int? {
        guard slot > 0 else { return nil }
        let dice = placedDice[0..<slot].compactMap { $0 }
        guard dice.count == slot else { return nil }
        let ops = placedOperations[0..<(slot - 1)].compactMap { $0 }
        guard ops.count == slot - 1 else { return nil }
        return evaluate(dice: dice, operations: ops)
    }

    private func pendingOperator(before slot: Int) -> MathOperation? {
        guard slot > 0 else { return nil }
        return placedOperations[slot - 1]
    }

    /// Every power/root this die could stand in as, for the current tier -- just the plain base
    /// for `.basic`, several for the harder tiers.
    private func availableVariants(at trayIndex: Int) -> [DieValue] {
        let face = puzzle.dice[trayIndex]
        let maxExponent = SolverConfiguration.recommendedMaxExponent(forDiceCount: puzzle.dice.count)
        return DieValue(base: face).variants(
            maxExponent: maxExponent,
            allowExponents: tier != .basic,
            allowRoots: tier == .rootsAndExponents
        )
    }

    /// `availableVariants`, narrowed to the ones the operator right before `slot` can actually
    /// combine with (or all of them, if `slot` is the very first die).
    private func validVariants(for trayIndex: Int, atSlot slot: Int) -> [DieValue] {
        let variants = availableVariants(at: trayIndex)
        guard let accumulator = accumulator(before: slot), let op = pendingOperator(before: slot) else {
            return variants
        }
        return variants.filter { op.apply(accumulator, $0.value) != nil }
    }

    /// Whether tapping this tray die right now would be legal -- guards against both "already
    /// used" and "no variant of it can actually combine with the pending operator" (e.g. an
    /// inexact division), so the tray only ever offers choices that lead somewhere valid.
    func canPlaceTrayDie(at trayIndex: Int) -> Bool {
        guard isAwaitingDie, !usedTrayIndices.contains(trayIndex), let slot = nextDieSlot else { return false }
        return !validVariants(for: trayIndex, atSlot: slot).isEmpty
    }

    /// Places the plain value immediately (the die to the power of 1, not 1 as in "to the power
    /// of 0") when it's legal, and opens `activeVariantOptions` so the player can optionally
    /// raise it to a power/root before choosing the next operator. Falls back to whatever the
    /// pending operator does allow if plain itself isn't a legal choice right now.
    func placeTrayDie(at trayIndex: Int) {
        guard isAwaitingDie, !usedTrayIndices.contains(trayIndex), let slot = nextDieSlot else { return }
        let variants = validVariants(for: trayIndex, atSlot: slot)
        let plain = variants.first { $0.exponent == 1 && $0.root == 1 }
        guard let defaultVariant = plain ?? variants.first else { return }
        placedDice[slot] = defaultVariant
        trayIndexForDieSlot[slot] = trayIndex
        activeDieSlot = slot
        activeVariantOptions = variants
        feedback = .none
    }

    /// Swaps the active slot's die for a different power/root of the same value -- freely
    /// re-selectable until the next operator locks the slot in.
    func selectVariant(_ variant: DieValue) {
        guard let slot = activeDieSlot else { return }
        placedDice[slot] = variant
        feedback = .none
    }

    func placeOperation(_ operation: MathOperation) {
        guard isAwaitingOperation, let slot = nextOperationSlot else { return }
        placedOperations[slot] = operation
        activeDieSlot = nil
        activeVariantOptions = []
        feedback = .none
    }

    /// Removing a die (or operation) also clears everything after it, since the whole chain
    /// depended on it -- this doubles as the entire undo mechanism, no separate button needed.
    func removeDieSlot(_ index: Int) {
        guard placedDice[index] != nil else { return }
        for i in index..<placedDice.count {
            placedDice[i] = nil
            trayIndexForDieSlot[i] = nil
        }
        for i in index..<placedOperations.count {
            placedOperations[i] = nil
        }
        activeDieSlot = nil
        activeVariantOptions = []
        feedback = .none
    }

    /// Undoing an operator hands the die right before it back to `activeDieSlot`, exactly as if
    /// it had just been tapped from the tray -- variant options recompute the same way.
    func removeOperationSlot(_ index: Int) {
        guard placedOperations[index] != nil else { return }
        placedOperations[index] = nil
        for i in (index + 1)..<placedDice.count {
            placedDice[i] = nil
            trayIndexForDieSlot[i] = nil
        }
        for i in (index + 1)..<placedOperations.count {
            placedOperations[i] = nil
        }
        if let trayIndex = trayIndexForDieSlot[index] {
            activeDieSlot = index
            activeVariantOptions = validVariants(for: trayIndex, atSlot: index)
        } else {
            activeDieSlot = nil
            activeVariantOptions = []
        }
        feedback = .none
    }

    func submit() {
        guard isComplete else { return }
        let dice = placedDice.compactMap { $0 }
        let operations = placedOperations.compactMap { $0 }
        guard let result = evaluate(dice: dice, operations: operations) else { return }
        feedback = result == puzzle.target ? .correct : .incorrect(got: result)
    }
}
