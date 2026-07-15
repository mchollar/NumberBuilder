/// Everything a `SolverEngine` needs to search for solutions: the rolled dice, the target
/// number, and which rule variant is in effect.
public struct SolverConfiguration: Sendable, Hashable {
    public var dice: [Int]
    public var target: Int
    public var allowExponents: Bool
    public var allowRoots: Bool
    public var maxExponent: Int

    /// `maxExponent` defaults to `recommendedMaxExponent(forDiceCount:)` when omitted, so a
    /// caller that doesn't think about performance still gets a safe search space. Pass an
    /// explicit value to override (e.g. for tests that need a specific power to appear).
    public init(
        dice: [Int],
        target: Int,
        allowExponents: Bool = true,
        allowRoots: Bool = true,
        maxExponent: Int? = nil
    ) {
        self.dice = dice
        self.target = target
        self.allowExponents = allowExponents
        self.allowRoots = allowRoots
        self.maxExponent = maxExponent ?? Self.recommendedMaxExponent(forDiceCount: dice.count)
    }

    public static let classicDiceCount = 3
    public static let classicDiceSides = 6

    /// Caps the power/root search space so larger dice-count rule variants stay interactive.
    /// Benchmarked empirically against `SolverEngine`'s branch-and-bound pruning (see
    /// `SolverEngineBenchmarkTests`): 5 dice at `maxExponent` 5 takes ~14s, at 3 takes ~4s, both
    /// down from the pre-pruning brute force's 134s/10s. 3 is the sweet spot -- comfortably
    /// interactive while allowing noticeably more exponent/root variety than the old cap of 2.
    /// 4 dice stayed under a second even at `maxExponent` 5, so only 5 dice needs scaling down
    /// given the plan's stated cap of 5 dice; the `default` case beyond that is unbenchmarked
    /// and deliberately conservative since there's no current plan to support more than 5 dice.
    public static func recommendedMaxExponent(forDiceCount diceCount: Int) -> Int {
        switch diceCount {
        case ..<5: return 5
        case 5: return 3
        default: return 1
        }
    }
}
