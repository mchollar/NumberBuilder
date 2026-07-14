import SwiftUI
import NumberBuilderKit

/// Renders a `Solution`'s expression with real superscripts (smaller font + baseline offset)
/// instead of the shipped app's unicode-superscript-character string concatenation.
struct SolutionExpressionView: View {
    let solution: Solution

    var body: some View {
        HStack(spacing: 3) {
            ForEach(Array(solution.expressionTokens.enumerated()), id: \.offset) { _, token in
                tokenView(token)
            }
        }
        .font(.system(.body, design: .rounded))
    }

    @ViewBuilder
    private func tokenView(_ token: ExpressionToken) -> some View {
        switch token {
        case .number(let die):
            dieView(die)
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

    private func dieView(_ die: DieValue) -> some View {
        HStack(alignment: .top, spacing: 1) {
            Text("\(die.base)")
            if die.exponent != 1 {
                Text(die.root == 1 ? "\(die.exponent)" : "\(die.exponent)/\(die.root)")
                    .font(.system(.caption2, design: .rounded))
                    .baselineOffset(9)
            }
            if die.exponent != 1 || die.root != 1 {
                Text("[\(die.value)]")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
