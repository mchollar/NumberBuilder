import SwiftUI
import NumberBuilderKit

struct SolutionsSummaryView: View {
    let solutions: [Solution]
    let diceFaces: [Int]
    let target: Int

    @State private var showHelp = false
    @AppStorage(DiceAppearanceSettings.colorSchemeKey) private var diceColorScheme: DiceColorScheme = .rainbow
    @AppStorage(DiceAppearanceSettings.styleKey) private var diceStyle: DiceRenderStyle = .filledColoredBackground

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

            if solutions.isEmpty {
                emptyState
            } else {
                tierSection(tier: .basic, title: "Basic Solutions", solutions: basic)
                tierSection(tier: .exponents, title: "Using Exponents", solutions: exponents)
                tierSection(tier: .rootsAndExponents, title: "Using Exponents & Roots", solutions: rootsAndExponents)
            }
        }
        .scrollContentBackground(.hidden)
        .readableContentWidth()
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
                .accessibilityLabel("Results Help")
            }
        }
        .sheet(isPresented: $showHelp) {
            ResultsHelpSheet()
        }
    }

    private var scoreboard: some View {
        HStack(spacing: 16) {
            HStack(spacing: 6) {
                ForEach(Array(diceFaces.enumerated()), id: \.offset) { index, face in
                    DiceFaceView(value: face, colorScheme: diceColorScheme, style: diceStyle, index: index, tier: nil)
                        .frame(width: 56, height: 56)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Rolled \(diceFaces.map(String.init).joined(separator: ", "))")
            Image(systemName: "arrow.right")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text("\(target)")
                .nbNumberFont(32)
                .foregroundStyle(Color.nbAccent)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .cardSurface()
        .padding(.vertical, 4)
    }

    private var emptyState: some View {
        Section {
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.magnifyingglass")
                    .font(.system(size: 36))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                Text("No Solutions Found")
                    .nbNumberFont(20)
                Text("There's no way to reach \(target) with \(diceFaces.map(String.init).joined(separator: ", ")).")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .padding(.horizontal, 20)
        }
        .listRowBackground(Color.nbCardSurface)
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
                        .accessibilityHidden(true)
                    Text("\(title) · \(solutions.count)")
                }
            }
            .listRowBackground(Color.nbCardSurface)
        }
    }

}

/// Replaces a plain `.alert()` wall of text with something that actually shows the three tiers'
/// own colors and badges instead of just describing them -- the same "Basic / Exponents /
/// Exponents & Roots" colored-dot language already used in `tierSection`'s header and
/// `HowToPlayView`'s tier list, reused here rather than invented fresh.
private struct ResultsHelpSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 12) {
                        ForEach(SolutionTier.allCases, id: \.self) { tier in
                            tierCard(tier)
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        tip(systemImage: "square.stack.3d.up.fill", text: "Only the first match of each type shows here — tap **Show All Results** to see the rest.")
                        tip(systemImage: "textformat.superscript", text: "An exponent or root gets a smaller line underneath with its fully calculated value.")
                    }
                    .padding(16)
                    .cardSurface()
                }
                .padding(20)
                .readableContentWidth()
            }
            .background(Color.nbBackground.ignoresSafeArea())
            .navigationTitle("Results Help")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .tint(.nbAccent)
                }
            }
        }
    }

    private func tierCard(_ tier: SolutionTier) -> some View {
        HStack(spacing: 14) {
            Text(badgeGlyph(tier))
                .nbNumberFont(20, weight: .bold)
                .foregroundStyle(tier.accentColor.accessibleIconTint(against: .nbCardSurface))
                .frame(width: 48, height: 48)
                .background(
                    Circle().fill(tier.accentColor.opacity(0.18))
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(tier.shortTitle)
                    .font(.headline)
                    .foregroundStyle(tier.accentColor)
                Text(tier.explanation)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .cardSurface()
        .accessibilityElement(children: .combine)
    }

    private func tip(systemImage: String, text: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(Color.nbAccent)
                .frame(width: 20)
            Text(text)
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }

    private func badgeGlyph(_ tier: SolutionTier) -> String {
        switch tier {
        case .basic: return "±"
        case .exponents: return "x²"
        case .rootsAndExponents: return "√x"
        }
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

#Preview("Results — No Solutions") {
    NavigationStack {
        SolutionsSummaryView(solutions: [], diceFaces: [1, 1, 1], target: 500)
    }
}
