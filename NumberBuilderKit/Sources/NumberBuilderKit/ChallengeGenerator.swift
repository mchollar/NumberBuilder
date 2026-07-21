/// Generates solvable Challenge-mode puzzles *by construction* rather than by reverse-searching a
/// random roll for a matching target: pick dice, pick per-die variants respecting the requested
/// level's technique, pick valid operators, evaluate left to right to get the target -- then
/// keep only results at or under the level's `maxTarget`. This guarantees solvability without
/// running a full `SolverEngine` search, so it's fast enough to regenerate instantly for a "New
/// Puzzle" action. Non-deterministic (plain system randomness) -- unlike `DailyChallengeGenerator`,
/// challenge puzzles don't need to reproduce across devices.
///
/// Rejecting on the *combined* target rather than capping each die's own exponent individually
/// is deliberate: capping one die's power doesn't bound what the dice multiply out to once
/// combined (three plain dice alone can reach 216), and a target ceiling naturally filters out
/// oversized individual dice too, since a die like 6⁵ = 7776 essentially never combines back down
/// under even the most generous level's ceiling.
public enum ChallengeGenerator {
    public struct Puzzle: Sendable, Hashable {
        public let dice: [Int]
        public let target: Int
        public let level: ChallengeLevel
        /// One real way to reach `target` -- generation already builds this for free, and it
        /// doubles as the answer a "Reveal Answer" action can show.
        public let exampleSolution: Solution

        public var tier: SolutionTier { level.tier }
    }

    /// Bounded rather than `while true` -- a real, shipped bug (an earlier design that made one
    /// tier/setting combination mathematically unreachable) turned an unbounded retry loop into
    /// an infinite one that pinned the CPU and froze the app. Higher than the old per-tier budget
    /// since rejecting on target range needs more tries on average than rejecting on tier alone,
    /// but every level still resolves in well under this in practice -- see
    /// `ChallengeGeneratorTests.testEveryLevelTerminates`.
    private static let maxAttemptsPerLevel = 2000

    public static func generate(
        level: ChallengeLevel,
        diceCount: Int = SolverConfiguration.classicDiceCount,
        diceSides: Int = SolverConfiguration.classicDiceSides
    ) -> Puzzle {
        if let puzzle = attemptRepeatedly(level: level, diceCount: diceCount, diceSides: diceSides) {
            return puzzle
        }
        // Should be unreachable -- every shipped level is verified achievable by
        // `ChallengeGeneratorTests.testEveryLevelTerminates`. If some future change to the level
        // table (a tighter ceiling, more dice) makes a level truly impossible, this is the
        // last-resort fallback: `.one`, which is always trivially solvable. Loudly flagged in
        // debug/test builds rather than silently shipping another freeze.
        assertionFailure("ChallengeGenerator exhausted \(maxAttemptsPerLevel) attempts for level \(level) -- falling back")
        if level != .one, let puzzle = attemptRepeatedly(level: .one, diceCount: diceCount, diceSides: diceSides) {
            return puzzle
        }
        return Puzzle(
            dice: [1, 1, 1],
            target: 3,
            level: .one,
            exampleSolution: Solution(result: 3, dice: [DieValue(base: 1), DieValue(base: 1), DieValue(base: 1)], operations: [.add, .add], tier: .basic)
        )
    }

    private static func attemptRepeatedly(level: ChallengeLevel, diceCount: Int, diceSides: Int) -> Puzzle? {
        for _ in 0..<maxAttemptsPerLevel {
            let faces = DiceRoller.roll(count: diceCount, sides: diceSides)
            if let puzzle = attempt(faces: faces, level: level) {
                return puzzle
            }
        }
        return nil
    }

    private static func attempt(faces: [Int], level: ChallengeLevel) -> Puzzle? {
        let tier = level.tier

        // Force exactly one (randomly chosen) die to use *some* non-trivial technique this level
        // allows, so generation succeeds on the first attempt rather than rejection-sampling for
        // it, and every puzzle demonstrably steps up from Basic. Deliberately *not* forcing the
        // level's single most advanced technique specifically (e.g. always forcing a root on the
        // Roots levels) -- since only a rolled 4 can ever produce a root value at all (see
        // `DieValue.challengeVariants`), that would have silently meant "every Roots-level roll
        // must contain a 4," turning a technique that's supposed to be a *possibility* into a
        // hidden requirement on the dice themselves. A fractional exponent is now something that
        // *can* show up on the Roots levels when a 4 comes up and gets picked -- not something
        // every puzzle is engineered to force. The other dice pick freely from their full variant
        // list, including staying plain. The target ceiling below does the real work of keeping
        // puzzles from getting out of hand -- letting more than one die go complex is fine as
        // long as the combined result still fits.
        let forcedIndex = tier == .basic ? nil : Int.random(in: faces.indices)

        var dice: [DieValue] = []
        for (index, face) in faces.enumerated() {
            let variants = DieValue.challengeVariants(
                base: face,
                allowExponents: tier != .basic,
                allowRoots: tier == .rootsAndExponents
            )
            let pool: [DieValue]
            if index == forcedIndex {
                let required = variants.filter { $0.exponent != 1 || $0.root != 1 }
                pool = required.isEmpty ? variants : required
            } else {
                pool = variants
            }
            guard let chosen = pool.randomElement() else { return nil }
            dice.append(chosen)
        }

        // A range, not an exact match -- a Roots-level puzzle whose forced die happens to land on
        // a plain exponent (no 4 was rolled, say) is still a perfectly valid puzzle for that
        // level now, just one that didn't happen to use a root this time. But the lower bound
        // still matters and can't just be dropped: forcing above can silently fail on its own
        // (the forced die's *rolled face* might be 1, which can never take an exponent at all,
        // regardless of what tier asked for), and without a floor here that failure would have
        // quietly slipped through as an all-plain puzzle at a level that's supposed to guarantee
        // better than Basic. So every non-Basic level still requires at least `.exponents` --
        // only the ceiling (which technique tops it out) is what's now permissive.
        let minimumTier: SolutionTier = tier == .basic ? .basic : .exponents
        let achievedTier = SolutionTier.classify(dice: dice)
        guard achievedTier >= minimumTier, achievedTier <= tier else { return nil }

        var operations: [MathOperation] = []
        var accumulator = dice[0].value
        for die in dice.dropFirst() {
            let validOperations = MathOperation.allCases.filter { $0.apply(accumulator, die.value) != nil }
            guard let operation = validOperations.randomElement(),
                  let next = operation.apply(accumulator, die.value) else { return nil }
            operations.append(operation)
            accumulator = next
        }

        guard accumulator > 0, accumulator <= level.maxTarget else { return nil }

        // The solution's own tier reflects what these specific dice actually demonstrate, not
        // the level's ceiling -- they can now differ (a Roots-level puzzle whose forced die
        // landed on a plain exponent is still tagged `.exponents` here), and `Solution.tier`
        // means "what this solution actually uses" everywhere else it's set (Explore mode's real
        // solver results included), so this keeps that meaning consistent rather than special-
        // casing Challenge to mean something else.
        let solution = Solution(result: accumulator, dice: dice, operations: operations, tier: achievedTier)
        return Puzzle(dice: faces, target: accumulator, level: level, exampleSolution: solution)
    }
}
