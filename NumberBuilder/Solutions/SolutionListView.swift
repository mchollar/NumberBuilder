import SwiftUI
import NumberBuilderKit

struct SolutionListView: View {
    let title: String
    let tier: SolutionTier
    let solutions: [Solution]

    var body: some View {
        List(solutions) { solution in
            SolutionExpressionView(solution: solution, tint: tier.accentColor)
                .listRowBackground(Color.nbCardSurface)
        }
        .scrollContentBackground(.hidden)
        .readableContentWidth()
        .background(Color.nbBackground)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Solution List") {
    let sample: [Solution] = (1...6).map { value in
        Solution(result: value * 2, dice: [DieValue(base: value), DieValue(base: 2)], operations: [.multiply], tier: .basic)
    }
    return NavigationStack {
        SolutionListView(title: "Basic Solutions", tier: .basic, solutions: sample)
    }
}
