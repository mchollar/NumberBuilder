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
    private(set) var level: PracticeLevel
    private(set) var puzzle: PracticeGenerator.Puzzle
    /// Convenience for every call site that only cares which techniques are in play (dice/tier
    /// coloring, the variant picker) -- fully implied by `level` now, not a separate choice.
    var tier: SolutionTier { level.tier }
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
    /// True once the player has given up on the current puzzle via Reveal Answer -- locks every
    /// further interaction (tray taps, variant/operator selection, Submit) until New Puzzle,
    /// rather than treating the reveal as a hint they can still act on.
    private(set) var isRevealed = false

    /// Drives "Show all" -- runs the puzzle's own dice/target through the real solver (same as
    /// Explore mode would) so a player can see every way to reach the target, not just the one
    /// `exampleSolution` a reveal shows. Shares `PuzzleSolver` with `SolveViewModel` rather than
    /// duplicating the solve/progress-tracking logic.
    private let allSolutionsSolver = PuzzleSolver()
    var hasLoadedAllSolutions = false
    var allSolutions: [Solution]? { allSolutionsSolver.solutions }

    /// True once the current puzzle's first conclusion has already been counted toward the free
    /// trial -- guards `recordConclusionIfNeeded()` so retrying the *same* puzzle via `Reset` and
    /// concluding again doesn't burn a second credit (Reset's whole purpose is trying a different
    /// expression for the same dice/target, which should stay free).
    private var hasCountedCurrentPuzzle = false
    /// True when the free trial is exhausted and Challenge hasn't been unlocked -- `PracticeView`
    /// shows `PaywallView` instead of the normal puzzle content whenever this is true. Set at
    /// init (in case the trial was already exhausted in a previous session) and re-checked on
    /// every `newPuzzle()` attempt, not on every puzzle generation eagerly -- an already-concluded
    /// puzzle stays visible/retryable via Reset even after the cap is hit, since nothing re-checks
    /// access until the *next* new-puzzle attempt.
    private(set) var isPaywalled: Bool

    init(level: PracticeLevel = .one) {
        self.level = level
        let puzzle = PracticeGenerator.generate(level: level)
        self.puzzle = puzzle
        self.placedDice = Array(repeating: nil, count: puzzle.dice.count)
        self.placedOperations = Array(repeating: nil, count: puzzle.dice.count - 1)
        self.trayIndexForDieSlot = Array(repeating: nil, count: puzzle.dice.count)
        self.isPaywalled = !PurchaseManager.shared.hasChallengeAccess
    }

    func selectLevel(_ newLevel: PracticeLevel) {
        guard newLevel != level else { return }
        level = newLevel
        newPuzzle()
    }

    func newPuzzle() {
        guard PurchaseManager.shared.hasChallengeAccess else {
            isPaywalled = true
            AppLogger.practice.debug("New puzzle blocked -- free trial exhausted")
            return
        }
        isPaywalled = false
        puzzle = PracticeGenerator.generate(level: level)
        placedDice = Array(repeating: nil, count: puzzle.dice.count)
        placedOperations = Array(repeating: nil, count: puzzle.dice.count - 1)
        trayIndexForDieSlot = Array(repeating: nil, count: puzzle.dice.count)
        feedback = .none
        activeDieSlot = nil
        activeVariantOptions = []
        isRevealed = false
        hasCountedCurrentPuzzle = false
        AppLogger.practice.debug("New puzzle: dice \(self.puzzle.dice), target \(self.puzzle.target), tier \(String(describing: self.tier))")
    }

    /// Counts this puzzle toward the free trial the first time it concludes -- called from both
    /// `submit()` and `revealAnswer()`, the app's only two "this attempt is over" moments.
    private func recordConclusionIfNeeded() {
        guard !hasCountedCurrentPuzzle else { return }
        hasCountedCurrentPuzzle = true
        PurchaseManager.shared.recordFreePuzzleCompletion()
    }

    /// Clears every placed die/operator, feedback, and reveal state -- but keeps the same puzzle
    /// (dice/target/tier), unlike `newPuzzle()` which generates a fresh one. Lets a player retry
    /// the same roll after getting it wrong, revealing the answer, or even after solving it
    /// correctly (there's often more than one valid expression for the same dice/target).
    func resetEntries() {
        placedDice = Array(repeating: nil, count: puzzle.dice.count)
        placedOperations = Array(repeating: nil, count: puzzle.dice.count - 1)
        trayIndexForDieSlot = Array(repeating: nil, count: puzzle.dice.count)
        feedback = .none
        activeDieSlot = nil
        activeVariantOptions = []
        isRevealed = false
    }

    /// True once this attempt has concluded -- a Submit happened (right or wrong) or the answer
    /// was revealed. Drives the Submit button's relabeling to Reset.
    var hasConcluded: Bool {
        feedback != .none || isRevealed
    }

    var usedTrayIndices: Set<Int> {
        Set(trayIndexForDieSlot.compactMap { $0 })
    }

    private var nextDieSlot: Int? { placedDice.firstIndex(where: { $0 == nil }) }
    private var nextOperationSlot: Int? { placedOperations.firstIndex(where: { $0 == nil }) }

    /// True exactly when the next open slot is a die -- i.e. every operation before it is
    /// already filled (or there are none yet, for the very first die). Always false once
    /// revealed, which is what stops the tray/pickers from accepting further taps.
    var isAwaitingDie: Bool {
        guard !isRevealed, let dieSlot = nextDieSlot else { return false }
        return placedOperations.prefix(dieSlot).allSatisfy { $0 != nil }
    }

    var isAwaitingOperation: Bool {
        guard !isRevealed, let opSlot = nextOperationSlot else { return false }
        return placedDice[opSlot] != nil
    }

    var isComplete: Bool {
        placedDice.allSatisfy { $0 != nil } && placedOperations.allSatisfy { $0 != nil }
    }

    /// Whether there's anything to undo -- the most recent placement, mirroring `isAwaitingDie`'s
    /// own account of "what happened last": a die still open for a variant swap (including the
    /// final die, which stays open until Submit), or else the last-placed operator.
    var canUndo: Bool {
        guard !isRevealed else { return false }
        return activeDieSlot != nil || placedOperations.contains { $0 != nil }
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
        return DieValue.practiceVariants(
            base: face,
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
        guard isAwaitingDie, !usedTrayIndices.contains(trayIndex), let slot = nextDieSlot else {
            AppLogger.practice.debug("Ignored tray tap at index \(trayIndex): not awaiting a die or already used")
            return
        }
        let variants = validVariants(for: trayIndex, atSlot: slot)
        let plain = variants.first { $0.exponent == 1 && $0.root == 1 }
        guard let defaultVariant = plain ?? variants.first else {
            AppLogger.practice.debug("Ignored tray tap at index \(trayIndex): no legal variant for slot \(slot)")
            return
        }
        placedDice[slot] = defaultVariant
        trayIndexForDieSlot[slot] = trayIndex
        activeDieSlot = slot
        activeVariantOptions = variants
        feedback = .none
    }

    /// Swaps the active slot's die for a different power/root of the same value -- freely
    /// re-selectable until the next operator locks the slot in.
    func selectVariant(_ variant: DieValue) {
        guard !isRevealed, let slot = activeDieSlot else { return }
        placedDice[slot] = variant
        feedback = .none
    }

    func placeOperation(_ operation: MathOperation) {
        guard isAwaitingOperation, let slot = nextOperationSlot else {
            AppLogger.practice.debug("Ignored operator tap: not awaiting an operation")
            return
        }
        placedOperations[slot] = operation
        activeDieSlot = nil
        activeVariantOptions = []
        feedback = .none
    }

    /// Removing a die (or operation) also clears everything after it, since the whole chain
    /// depended on it -- this doubles as the entire undo mechanism, no separate button needed.
    func removeDieSlot(_ index: Int) {
        guard !isRevealed, placedDice[index] != nil else { return }
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
        guard !isRevealed, placedOperations[index] != nil else { return }
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

    /// Undoes the single most recent placement -- a still-open die (including the final die,
    /// which stays "open" until Submit) or, failing that, the last-placed operator. Reuses
    /// `removeDieSlot`/`removeOperationSlot` rather than duplicating their cascade-clear logic.
    func undoLast() {
        guard canUndo else { return }
        if let slot = activeDieSlot {
            removeDieSlot(slot)
        } else if let lastOpIndex = placedOperations.lastIndex(where: { $0 != nil }) {
            removeOperationSlot(lastOpIndex)
        }
    }

    /// Gives up on the current puzzle -- shows `puzzle.exampleSolution` (already built for free
    /// by `PracticeGenerator`) and locks every further interaction until Reset/New Puzzle.
    /// Deliberately not recoverable: revealing is treated as the end of this attempt, not a hint
    /// you keep playing after. Leaves `feedback` untouched on purpose -- clearing it used to wipe
    /// an existing "Not quite" banner, which made revealing after a wrong Submit look like a win
    /// (the answer card appearing with no error message nearby read as success).
    func revealAnswer() {
        guard !isRevealed else { return }
        isRevealed = true
        activeDieSlot = nil
        activeVariantOptions = []
        recordConclusionIfNeeded()
        AppLogger.practice.debug("Revealed answer for dice \(self.puzzle.dice), target \(self.puzzle.target)")
    }

    /// Solves the puzzle's own dice/target for real, independent of `level` -- "Show all" means
    /// genuinely everything reachable, the same as visiting Explore directly with this roll and
    /// target, not just techniques consistent with what this puzzle's level happened to allow.
    func showAllSolutions() {
        hasLoadedAllSolutions = false
        AppLogger.practice.debug("Solving all solutions for dice \(self.puzzle.dice), target \(self.puzzle.target)")
        allSolutionsSolver.solve(dice: puzzle.dice, target: puzzle.target) { [weak self] results in
            self?.hasLoadedAllSolutions = true
            AppLogger.practice.debug("Found \(results.count) total solutions")
        }
    }

    func submit() {
        guard isComplete, !isRevealed else { return }
        let dice = placedDice.compactMap { $0 }
        let operations = placedOperations.compactMap { $0 }
        guard let result = evaluate(dice: dice, operations: operations) else { return }
        feedback = result == puzzle.target ? .correct : .incorrect(got: result)
        recordConclusionIfNeeded()
        AppLogger.practice.debug("Submitted: got \(result), target \(self.puzzle.target), tier \(String(describing: self.tier))")
    }
}
