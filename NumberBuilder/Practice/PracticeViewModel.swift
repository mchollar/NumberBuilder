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

    /// The value of everything placed so far, or nil before the first die lands.
    private var runningAccumulator: Int? {
        let filledDice = placedDice.compactMap { $0 }
        guard !filledDice.isEmpty else { return nil }
        let opsNeeded = filledDice.count - 1
        let filledOps = placedOperations.compactMap { $0 }
        guard filledOps.count >= opsNeeded else { return nil }
        return evaluate(dice: filledDice, operations: Array(filledOps.prefix(opsNeeded)))
    }

    /// Whether tapping this tray die right now would be legal -- guards against both "already
    /// used" and "the pending operator can't actually combine with this value" (e.g. an inexact
    /// division), so the tray only ever offers choices that lead somewhere valid.
    func canPlaceTrayDie(at trayIndex: Int) -> Bool {
        guard isAwaitingDie, !usedTrayIndices.contains(trayIndex) else { return false }
        guard let accumulator = runningAccumulator, let pendingOp = placedOperations.compactMap({ $0 }).last else {
            return true
        }
        let candidateValue = DieValue(base: puzzle.dice[trayIndex]).value
        return pendingOp.apply(accumulator, candidateValue) != nil
    }

    func placeTrayDie(at trayIndex: Int) {
        guard canPlaceTrayDie(at: trayIndex), let slot = nextDieSlot else { return }
        placedDice[slot] = DieValue(base: puzzle.dice[trayIndex])
        trayIndexForDieSlot[slot] = trayIndex
        feedback = .none
    }

    func placeOperation(_ operation: MathOperation) {
        guard isAwaitingOperation, let slot = nextOperationSlot else { return }
        placedOperations[slot] = operation
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
        feedback = .none
    }

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
