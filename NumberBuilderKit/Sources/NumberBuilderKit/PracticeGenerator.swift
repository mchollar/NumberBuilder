/// Generates solvable Practice-mode puzzles *by construction* rather than by reverse-searching a
/// random roll for a matching target: pick dice, pick per-die variants respecting the requested
/// tier, pick valid operators, evaluate left to right to get the target. This guarantees
/// solvability without running a full `SolverEngine` search, so it's fast enough to regenerate
/// instantly for a "New Puzzle" action. Non-deterministic (plain system randomness) -- unlike
/// `DailyChallengeGenerator`, practice puzzles don't need to reproduce across devices.
public enum PracticeGenerator {
    public struct Puzzle: Sendable, Hashable {
        public let dice: [Int]
        public let target: Int
        public let tier: SolutionTier
        /// One real way to reach `target` -- generation already builds this for free, and it
        /// doubles as the answer a "Reveal Answer" action can show.
        public let exampleSolution: Solution
    }

    public static func generate(
        tier: SolutionTier,
        diceCount: Int = SolverConfiguration.classicDiceCount,
        diceSides: Int = SolverConfiguration.classicDiceSides,
        maxExponent: Int? = nil
    ) -> Puzzle {
        let resolvedMaxExponent = maxExponent ?? SolverConfiguration.recommendedMaxExponent(forDiceCount: diceCount)
        while true {
            let faces = DiceRoller.roll(count: diceCount, sides: diceSides)
            if let puzzle = attempt(faces: faces, tier: tier, maxExponent: resolvedMaxExponent) {
                return puzzle
            }
        }
    }

    private static func attempt(faces: [Int], tier: SolutionTier, maxExponent: Int) -> Puzzle? {
        // Force exactly one (randomly chosen) die to use the tier-defining technique, so
        // generation succeeds on the first attempt rather than rejection-sampling for it; the
        // other dice pick freely from their full variant list, including staying plain.
        let forcedIndex = tier == .basic ? nil : Int.random(in: faces.indices)

        var dice: [DieValue] = []
        for (index, face) in faces.enumerated() {
            let variants = DieValue(base: face).variants(
                maxExponent: maxExponent,
                allowExponents: tier != .basic,
                allowRoots: tier == .rootsAndExponents
            )
            let pool: [DieValue]
            if index == forcedIndex {
                let required = tier == .rootsAndExponents
                    ? variants.filter { $0.root != 1 }
                    : variants.filter { $0.exponent != 1 }
                pool = required.isEmpty ? variants : required
            } else {
                pool = variants
            }
            guard let chosen = pool.randomElement() else { return nil }
            dice.append(chosen)
        }

        guard SolutionTier.classify(dice: dice) == tier else { return nil }

        var operations: [MathOperation] = []
        var accumulator = dice[0].value
        for die in dice.dropFirst() {
            let validOperations = MathOperation.allCases.filter { $0.apply(accumulator, die.value) != nil }
            guard let operation = validOperations.randomElement(),
                  let next = operation.apply(accumulator, die.value) else { return nil }
            operations.append(operation)
            accumulator = next
        }

        guard accumulator > 0 else { return nil }

        let solution = Solution(result: accumulator, dice: dice, operations: operations, tier: tier)
        return Puzzle(dice: faces, target: accumulator, tier: tier, exampleSolution: solution)
    }
}
