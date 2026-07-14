/// Which of the three difficulty tiers a `Solution` falls into, ordered easiest to hardest.
public enum SolutionTier: CaseIterable, Sendable, Hashable {
    case basic
    case exponents
    case rootsAndExponents
}
