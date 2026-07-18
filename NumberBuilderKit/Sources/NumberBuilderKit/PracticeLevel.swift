/// Challenge's single difficulty dial. Supersedes an earlier two-axis design (`SolutionTier` +
/// a separate "how intense" setting) that controlled difficulty indirectly through per-die
/// exponent caps -- that let puzzles reach targets like 288 on the second-easiest setting, since
/// capping what one die can become doesn't bound what the dice add up to once combined (even
/// three plain dice multiply to 216). This instead names each level by the one thing that
/// actually matters to a player: how big the target gets, alongside which techniques are in
/// play. Modeled loosely on the real N2K's own board levels, which are likewise defined by
/// target range rather than by capping individual dice.
public enum PracticeLevel: Int, CaseIterable, Sendable, Hashable, Comparable {
    case one = 1, two, three, four, five, six

    public static func < (lhs: PracticeLevel, rhs: PracticeLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    public var next: PracticeLevel {
        PracticeLevel(rawValue: rawValue + 1) ?? self
    }

    public var previous: PracticeLevel {
        PracticeLevel(rawValue: rawValue - 1) ?? self
    }

    /// Which techniques this level requires -- exactly one die must demonstrate it (see
    /// `PracticeGenerator`), same as the old tier system.
    public var tier: SolutionTier {
        switch self {
        case .one, .two: return .basic
        case .three, .four: return .exponents
        case .five, .six: return .rootsAndExponents
        }
    }

    /// The real constraint driving generation -- a puzzle is only accepted if its target falls
    /// at or under this. 36 matches the real N2K board's own size (1-36) for the easiest level.
    public var maxTarget: Int {
        switch self {
        case .one: return 36
        case .two: return 100
        case .three: return 100
        case .four: return 250
        case .five: return 250
        case .six: return 1000
        }
    }

    /// Short, self-explanatory line shown directly under the level stepper -- written to stand
    /// alone without needing a trip to How to Play.
    public var description: String {
        switch self {
        case .one: return "Add, subtract, multiply, divide. Targets stay under 36."
        case .two: return "Same operations, bigger targets — up to 100."
        case .three: return "Adds powers. Targets stay under 100."
        case .four: return "Powers allowed, bigger targets — up to 250."
        case .five: return "Adds fractional exponents too. Targets stay under 250."
        case .six: return "Powers and fractional exponents, targets up to 1,000."
        }
    }
}
