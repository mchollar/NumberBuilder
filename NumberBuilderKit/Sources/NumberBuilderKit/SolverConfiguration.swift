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
    /// Benchmarked empirically: 5 dice at `maxExponent` 5 took 134s (1.26M candidates); at 2 it
    /// took ~1s. 4 dice stayed under a second even at `maxExponent` 5, so only 5 dice needs
    /// scaling down given the plan's stated cap of 5 dice.
    public static func recommendedMaxExponent(forDiceCount diceCount: Int) -> Int {
        switch diceCount {
        case ..<5: return 5
        case 5: return 2
        default: return 1
        }
    }
}
