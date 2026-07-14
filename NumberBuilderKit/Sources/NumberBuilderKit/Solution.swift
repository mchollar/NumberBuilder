/// One way of combining a roll's dice (in this order, strictly left to right) to reach `result`.
public struct Solution: Identifiable, Hashable, Sendable {
    public let result: Int
    public let dice: [DieValue]
    public let operations: [MathOperation]
    public let tier: SolutionTier

    public init(result: Int, dice: [DieValue], operations: [MathOperation], tier: SolutionTier) {
        self.result = result
        self.dice = dice
        self.operations = operations
        self.tier = tier
    }

    /// Structural identity — two solutions with the same dice/operations/result are the same
    /// solution, so re-solving the same roll twice produces stable, diffable identities.
    public var id: Self { self }

    /// `((d0 op0 d1) op1 d2) ... opN-1 dN = result`. Always fully parenthesizes left-to-right
    /// groupings of three or more dice; a view can drop redundant parens as a display nicety.
    public var expressionTokens: [ExpressionToken] {
        guard let first = dice.first else { return [] }

        var tokens: [ExpressionToken] = []
        let needsGrouping = dice.count > 2
        if needsGrouping {
            tokens.append(contentsOf: repeatElement(.openParen, count: dice.count - 2))
        }
        tokens.append(.number(first))

        for index in dice.indices.dropFirst() {
            tokens.append(.op(operations[index - 1]))
            tokens.append(.number(dice[index]))
            if needsGrouping, index < dice.count - 1 {
                tokens.append(.closeParen)
            }
        }
        tokens.append(.equals(result))
        return tokens
    }
}

extension Solution: Comparable {
    public static func < (lhs: Solution, rhs: Solution) -> Bool {
        if lhs.result != rhs.result { return lhs.result < rhs.result }
        for (l, r) in zip(lhs.dice, rhs.dice) where l.base != r.base {
            return l.base < r.base
        }
        return lhs.dice.count < rhs.dice.count
    }
}
