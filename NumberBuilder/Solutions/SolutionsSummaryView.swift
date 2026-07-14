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
            Section {
                scoreboard
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())

            tierSection(tier: .basic, title: "Basic Solutions", solutions: basic)
            tierSection(tier: .exponents, title: "Using Exponents", solutions: exponents)
            tierSection(tier: .rootsAndExponents, title: "Using Exponents & Roots", solutions: rootsAndExponents)
        }
        .scrollContentBackground(.hidden)
        .background(Color.nbBackground)
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showHelp = true
                } label: {
                    Image(systemName: "questionmark.circle")
                }
                .tint(.nbAccent)
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

    private var scoreboard: some View {
        HStack(spacing: 16) {
            HStack(spacing: 6) {
                ForEach(Array(diceFaces.enumerated()), id: \.offset) { _, face in
                    Image("Dice\(face)")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                }
            }
            Image(systemName: "arrow.right")
                .foregroundStyle(.secondary)
            Text("\(target)")
                .font(.nbNumber(32))
                .foregroundStyle(Color.nbAccent)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .cardSurface()
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func tierSection(tier: SolutionTier, title: String, solutions: [Solution]) -> some View {
        if !solutions.isEmpty {
            Section {
                SolutionExpressionView(solution: solutions[0], tint: tier.accentColor)
                if solutions.count > 1 {
                    NavigationLink("Show All Results") {
                        SolutionListView(title: title, tier: tier, solutions: solutions)
                    }
                    .tint(tier.accentColor)
                }
            } header: {
                HStack(spacing: 6) {
                    Circle()
                        .fill(tier.accentColor)
                        .frame(width: 8, height: 8)
                    Text("\(title) · \(solutions.count)")
                }
            }
            .listRowBackground(Color.nbCardSurface)
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

#Preview("Results") {
    let exponentDie = DieValue(base: 4)
        .variants(maxExponent: 3, allowExponents: true, allowRoots: true)
        .first { $0.exponent != 1 && $0.root == 1 } ?? DieValue(base: 4)
    let rootDie = DieValue(base: 6)
        .variants(maxExponent: 3, allowExponents: true, allowRoots: true)
        .first { $0.root != 1 } ?? DieValue(base: 6)

    let sample: [Solution] = [
        Solution(result: 11, dice: [DieValue(base: 5), DieValue(base: 3), DieValue(base: 6)], operations: [.add, .subtract], tier: .basic),
        Solution(result: 8, dice: [DieValue(base: 5), DieValue(base: 3)], operations: [.add], tier: .basic),
        Solution(result: exponentDie.value + 2, dice: [exponentDie, DieValue(base: 2)], operations: [.add], tier: .exponents),
        Solution(result: rootDie.value, dice: [rootDie], operations: [], tier: .rootsAndExponents)
    ]

    return NavigationStack {
        SolutionsSummaryView(solutions: sample, diceFaces: [5, 3, 6], target: 11)
    }
}
