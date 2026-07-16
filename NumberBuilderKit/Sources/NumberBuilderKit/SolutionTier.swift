/// Which of the three difficulty tiers a `Solution` falls into, ordered easiest to hardest.
public enum SolutionTier: CaseIterable, Sendable, Hashable {
    case basic
    case exponents
    case rootsAndExponents

    /// Classifies a fully-built expression by the most advanced technique any die uses -- any
    /// root bumps it to `.rootsAndExponents` regardless of other dice; otherwise any non-1
    /// exponent bumps it to `.exponents`; plain dice throughout is `.basic`.
    public static func classify(dice: [DieValue]) -> SolutionTier {
        var usesExponent = false
        for die in dice {
            if die.root != 1 { return .rootsAndExponents }
            if die.exponent != 1 { usesExponent = true }
        }
        return usesExponent ? .exponents : .basic
    }
}
