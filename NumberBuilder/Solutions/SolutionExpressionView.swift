import SwiftUI
import NumberBuilderKit

/// Renders a `Solution`'s expression with real superscripts (smaller font + baseline offset)
/// instead of the shipped app's unicode-superscript-character string concatenation.
///
/// When any die uses an exponent or root, a second, smaller "evaluated" line is shown
/// underneath with the same expression fully computed to plain integers — e.g. `4² + 2 = 18`
/// over `16 + 2 = 18` — so the exponent/root's value is legible without cramming it inline.
struct SolutionExpressionView: View {
    let solution: Solution
    var tint: Color = .nbAccent

    private var hasComputedValues: Bool {
        solution.dice.contains { $0.exponent != 1 || $0.root != 1 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                ForEach(Array(solution.expressionTokens.enumerated()), id: \.offset) { _, token in
                    primaryToken(token)
                }
            }
            .font(.nbNumber(19, weight: .medium))

            if hasComputedValues {
                HStack(spacing: 4) {
                    ForEach(Array(solution.expressionTokens.enumerated()), id: \.offset) { _, token in
                        evaluatedToken(token)
                    }
                }
                .font(.nbNumber(14, weight: .medium))
                .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func primaryToken(_ token: ExpressionToken) -> some View {
        switch token {
        case .number(let die):
            primaryDieView(die)
        case .op(let operation):
            Text(operation.symbol)
                .foregroundStyle(operation.accentColor)
        case .openParen:
            Text("(")
                .foregroundStyle(.secondary)
        case .closeParen:
            Text(")")
                .foregroundStyle(.secondary)
        case .equals(let result):
            Text("= \(result)")
                .fontWeight(.bold)
                .foregroundStyle(tint)
        }
    }

    private func primaryDieView(_ die: DieValue) -> some View {
        HStack(alignment: .top, spacing: 1) {
            Text("\(die.base)")
            if die.exponent != 1 || die.root != 1 {
                Text(die.root == 1 ? "\(die.exponent)" : "\(die.exponent)/\(die.root)")
                    .font(.system(.caption2, design: .rounded, weight: .semibold))
                    .baselineOffset(10)
                    .foregroundStyle(tint)
            }
        }
    }

    /// Same token stream as `primaryToken`, but every die renders as its plain computed value.
    @ViewBuilder
    private func evaluatedToken(_ token: ExpressionToken) -> some View {
        switch token {
        case .number(let die):
            Text("\(die.value)")
        case .op(let operation):
            Text(operation.symbol)
        case .openParen:
            Text("(")
        case .closeParen:
            Text(")")
        case .equals(let result):
            Text("= \(result)")
                .fontWeight(.semibold)
        }
    }
}

#Preview("Expression") {
    let basic = Solution(
        result: 11,
        dice: [DieValue(base: 5), DieValue(base: 3), DieValue(base: 6)],
        operations: [.add, .subtract],
        tier: .basic
    )
    let withExponent = DieValue(base: 4)
        .variants(maxExponent: 3, allowExponents: true, allowRoots: true)
        .first { $0.exponent != 1 && $0.root == 1 } ?? DieValue(base: 4)
    let exponentSolution = Solution(
        result: withExponent.value + 2,
        dice: [withExponent, DieValue(base: 2)],
        operations: [.add],
        tier: .exponents
    )
    let withRoot = DieValue(base: 6)
        .variants(maxExponent: 3, allowExponents: true, allowRoots: true)
        .first { $0.root != 1 } ?? DieValue(base: 6)
    let rootSolution = Solution(
        result: withRoot.value,
        dice: [withRoot],
        operations: [],
        tier: .rootsAndExponents
    )

    return VStack(alignment: .leading, spacing: 20) {
        SolutionExpressionView(solution: basic, tint: SolutionTier.basic.accentColor)
        SolutionExpressionView(solution: exponentSolution, tint: SolutionTier.exponents.accentColor)
        SolutionExpressionView(solution: rootSolution, tint: SolutionTier.rootsAndExponents.accentColor)
    }
    .padding(24)
}
