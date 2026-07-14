import SwiftUI
import NumberBuilderKit

struct SolutionListView: View {
    let title: String
    let solutions: [Solution]

    var body: some View {
        List(solutions) { solution in
            SolutionExpressionView(solution: solution)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
