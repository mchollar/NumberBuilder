import SwiftUI
import NumberBuilderKit

struct SolutionsSummaryView: View {
    let solutions: [Solution]
    let diceFaces: [Int]
    let target: Int

    @AppStorage("hasSeenResultsHelp") private var hasSeenResultsHelp = false
    @State private var showHelp = false

    private var basic: [Solution] { solutions.filter { $0.tier == .basic } }
    private var exponents: [Solution] { solutions.filter { $0.tier == .exponents } }
    private var rootsAndExponents: [Solution] { solutions.filter { $0.tier == .rootsAndExponents } }

    var body: some View {
        List {
            tierSection(title: "Basic Solutions", solutions: basic)
            tierSection(title: "Using Exponents", solutions: exponents)
            tierSection(title: "Using Exponents & Roots", solutions: rootsAndExponents)
        }
        .navigationTitle("\(diceFaces.map(String.init).joined(separator: ", ")) → \(target)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showHelp = true
                } label: {
                    Image(systemName: "questionmark.circle")
                }
            }
        }
        .alert("Results Help", isPresented: $showHelp) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(helpMessage)
        }
        .onAppear {
            if !hasSeenResultsHelp {
                showHelp = true
                hasSeenResultsHelp = true
            }
        }
    }

    @ViewBuilder
    private func tierSection(title: String, solutions: [Solution]) -> some View {
        if !solutions.isEmpty {
            Section("\(title): \(solutions.count)") {
                SolutionExpressionView(solution: solutions[0])
                if solutions.count > 1 {
                    NavigationLink("Show All Results") {
                        SolutionListView(title: title, solutions: solutions)
                    }
                }
            }
        }
    }

    private var helpMessage: String {
        """
        The results are divided into three categories: Basic, Using Exponents, and Using Exponents & Roots. Only one of each solution type (if any) is shown on this page. More results of each type can be viewed by tapping "Show All Results."

        • Basic solutions use only +, −, ×, and ÷.
        • Using Exponents solutions also allow whole-number exponents.
        • Using Exponents & Roots solutions also allow fractional exponents (roots).

        A number with an exponent or root shows its calculated value in square brackets [].
        """
    }
}
