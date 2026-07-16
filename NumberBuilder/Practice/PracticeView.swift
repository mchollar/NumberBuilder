import SwiftUI
import NumberBuilderKit

struct PracticeView: View {
    @State private var viewModel = PracticeViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                tierPicker
                puzzleCard
                workspaceCard
                feedbackBanner
                controls
            }
            .padding(20)
            .readableContentWidth()
        }
        .background(Color.nbBackground.ignoresSafeArea())
        .navigationTitle("Practice")
    }

    private var tierPicker: some View {
        HStack(spacing: 8) {
            ForEach(SolutionTier.allCases, id: \.self) { tier in
                Button {
                    viewModel.selectTier(tier)
                } label: {
                    Text(compactTitle(for: tier))
                        .font(.footnote.weight(.semibold))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(
                    viewModel.tier == tier
                        ? AnyButtonStyle(.nbPrimary(tint: tier.accentColor))
                        : AnyButtonStyle(.nbTonal(tint: tier.accentColor))
                )
            }
        }
    }

    private var puzzleCard: some View {
        VStack(spacing: 16) {
            HStack {
                sectionLabel("Your Roll")
                Spacer()
                sectionLabel("Target")
            }
            HStack {
                diceTray
                Spacer()
                Text("\(viewModel.puzzle.target)")
                    .font(.nbNumber(32))
                    .foregroundStyle(viewModel.tier.accentColor)
            }
        }
        .padding(20)
        .cardSurface()
    }

    private var diceTray: some View {
        HStack(spacing: 10) {
            ForEach(Array(viewModel.puzzle.dice.enumerated()), id: \.offset) { index, face in
                let isAvailable = viewModel.canPlaceTrayDie(at: index)
                let isUsed = viewModel.usedTrayIndices.contains(index)
                Button {
                    viewModel.placeTrayDie(at: index)
                } label: {
                    Image("Dice\(face)")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 44, height: 44)
                        .opacity(isUsed ? 0.25 : (isAvailable ? 1 : 0.35))
                }
                .disabled(!isAvailable)
            }
        }
    }

    private var workspaceCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Your Answer")
            HStack(spacing: 4) {
                ForEach(Array(workspaceTokens.enumerated()), id: \.offset) { _, token in
                    workspaceToken(token)
                }
            }
            .font(.nbNumber(22, weight: .medium))
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }

    @ViewBuilder
    private var feedbackBanner: some View {
        switch viewModel.feedback {
        case .none:
            EmptyView()
        case .correct:
            Text("Correct! 🎉")
                .font(.nbNumber(18))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.nbAccent))
        case .incorrect(let got):
            VStack(spacing: 4) {
                Text("Not quite")
                    .font(.nbNumber(16))
                Text("You got \(got) — target is \(viewModel.puzzle.target)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .cardSurface(cornerRadius: 16)
        }
    }

    private var controls: some View {
        VStack(spacing: 12) {
            Button {
                viewModel.submit()
            } label: {
                Text("Submit")
            }
            .buttonStyle(.nbPrimary(tint: viewModel.tier.accentColor, isEnabled: viewModel.isComplete))
            .disabled(!viewModel.isComplete)

            Button {
                viewModel.newPuzzle()
            } label: {
                Text("New Puzzle")
            }
            .buttonStyle(.nbTonal(tint: viewModel.tier.accentColor))
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .tracking(0.5)
    }

    /// `SolutionTier.shortTitle` ("Exponents & Roots") wraps to two lines in this narrow a pill,
    /// making it taller than its siblings -- a shorter, picker-specific label keeps the row
    /// uniform. `shortTitle` itself is unchanged for the places it already reads fine (Solve
    /// mode's results, How to Play).
    private func compactTitle(for tier: SolutionTier) -> String {
        switch tier {
        case .basic: return "Basic"
        case .exponents: return "Exponents"
        case .rootsAndExponents: return "Roots"
        }
    }

    // MARK: - Workspace tokens

    /// Mirrors `Solution.expressionTokens`' grouping exactly (parens around every die/op pair
    /// but the last), just with blanks standing in for anything not placed yet -- so the
    /// left-to-right grouping is visible from the very first frame, before any tap.
    private enum WorkspaceToken {
        case dieSlot(Int)
        case opSlot(Int)
        case openParen
        case closeParen
        case equals
    }

    private var workspaceTokens: [WorkspaceToken] {
        let diceCount = viewModel.puzzle.dice.count
        guard diceCount > 0 else { return [] }
        var tokens: [WorkspaceToken] = []
        let needsGrouping = diceCount > 2
        if needsGrouping {
            tokens.append(contentsOf: repeatElement(.openParen, count: diceCount - 2))
        }
        tokens.append(.dieSlot(0))
        for index in 1..<diceCount {
            tokens.append(.opSlot(index - 1))
            tokens.append(.dieSlot(index))
            if needsGrouping, index < diceCount - 1 {
                tokens.append(.closeParen)
            }
        }
        tokens.append(.equals)
        return tokens
    }

    @ViewBuilder
    private func workspaceToken(_ token: WorkspaceToken) -> some View {
        switch token {
        case .dieSlot(let index):
            if let die = viewModel.placedDice[index] {
                Button {
                    viewModel.removeDieSlot(index)
                } label: {
                    dieSlotView(die)
                }
                .buttonStyle(.plain)
            } else {
                blankSlot
            }
        case .opSlot(let index):
            if let operation = viewModel.placedOperations[index] {
                Button {
                    viewModel.removeOperationSlot(index)
                } label: {
                    Text(operation.symbol)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            } else {
                blankSlot
            }
        case .openParen:
            Text("(").foregroundStyle(.secondary)
        case .closeParen:
            Text(")").foregroundStyle(.secondary)
        case .equals:
            Text("= \(viewModel.puzzle.target)")
                .fontWeight(.bold)
                .foregroundStyle(viewModel.tier.accentColor)
        }
    }

    private func dieSlotView(_ die: DieValue) -> some View {
        HStack(alignment: .top, spacing: 1) {
            Text("\(die.base)")
            if die.exponent != 1 {
                Text(die.root == 1 ? "\(die.exponent)" : "\(die.exponent)/\(die.root)")
                    .font(.system(.caption2, design: .rounded, weight: .semibold))
                    .baselineOffset(10)
                    .foregroundStyle(viewModel.tier.accentColor)
            }
        }
    }

    private var blankSlot: some View {
        Image(systemName: "square.dashed")
            .foregroundStyle(.secondary.opacity(0.4))
    }
}

/// Type-erases `NBPrimaryButtonStyle`/`NBTonalButtonStyle` so the tier picker can switch between
/// them per-button based on selection state.
private struct AnyButtonStyle: ButtonStyle {
    private let _makeBody: (Configuration) -> AnyView

    init<S: ButtonStyle>(_ style: S) {
        _makeBody = { AnyView(style.makeBody(configuration: $0)) }
    }

    func makeBody(configuration: Configuration) -> some View {
        _makeBody(configuration)
    }
}

#Preview("Practice") {
    NavigationStack {
        PracticeView()
    }
}
