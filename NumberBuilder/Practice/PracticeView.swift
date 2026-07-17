import SwiftUI
import NumberBuilderKit

/// Shared `UserDefaults` key for the Practice intro flag -- `DebugMenuView` also reads/writes
/// this, so it lives here as a named constant rather than as a string literal duplicated in both
/// files (a typo in a duplicated key wouldn't error, just silently point at a second default).
enum DebugResettableFlag {
    static let hasSeenPracticeIntroKey = "hasSeenPracticeIntro"
}

struct PracticeView: View {
    @State private var viewModel: PracticeViewModel
    /// Flips true the first time this sheet is shown, so a newcomer sees the explainer exactly
    /// once across every future launch -- persisted rather than session-only, since most players
    /// won't revisit Practice again within the same run of the app.
    @AppStorage(DebugResettableFlag.hasSeenPracticeIntroKey) private var hasSeenPracticeIntro = false
    @State private var showingIntro = false
    /// Bumped only when `feedback` transitions *into* `.correct`, so the checkmark's bounce
    /// fires once per win rather than replaying on every unrelated view update.
    @State private var correctTrigger = 0

    /// Defaults to a fresh puzzle for real use; the override lets previews drive the view model
    /// into a specific state (e.g. mid-placement, to inspect `variantPicker`) without simulating
    /// taps. Defaults to `nil` rather than a default-argument `PracticeViewModel()` -- default
    /// argument expressions evaluate outside the initializer's actor context, which can't satisfy
    /// `PracticeViewModel`'s `@MainActor` isolation.
    @MainActor
    init(viewModel: PracticeViewModel? = nil) {
        _viewModel = State(initialValue: viewModel ?? PracticeViewModel())
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                tierPicker
                puzzleCard
                workspaceCard
                revealedAnswerCard
                variantPicker
                operatorPicker
                feedbackBanner
                controls
            }
            .padding(20)
            .readableContentWidth()
        }
        .background(Color.nbBackground.ignoresSafeArea())
        .navigationTitle("Practice")
        .onAppear {
            guard !hasSeenPracticeIntro else { return }
            hasSeenPracticeIntro = true
            showingIntro = true
        }
        .sheet(isPresented: $showingIntro) {
            NavigationStack {
                HowToPlayView(initialMode: .practice, showsDoneButton: true)
            }
        }
        .onChange(of: viewModel.feedback) { _, newValue in
            if case .correct = newValue {
                correctTrigger += 1
            }
        }
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
                    withAnimation(.easeInOut(duration: 0.25)) {
                        viewModel.placeTrayDie(at: index)
                    }
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
            HStack(spacing: 6) {
                ForEach(Array(workspaceTokens.enumerated()), id: \.offset) { _, token in
                    workspaceToken(token)
                }
            }
            .font(.nbNumber(34, weight: .bold))
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .frame(maxWidth: .infinity, alignment: .center)

            // A separate line, not another token in the row above: a big target (e.g. 5 digits)
            // would otherwise have to fight the dice/paren glyphs for the same shrunk-to-fit
            // width and lose, truncating to "12,5...". On its own line it always gets the full
            // card width to scale within.
            Text("= \(viewModel.puzzle.target)")
                .font(.nbNumber(28, weight: .bold))
                .foregroundStyle(viewModel.tier.accentColor)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }

    /// Shown after Reveal Answer -- reuses `SolutionExpressionView` (Solve mode's own results
    /// renderer) rather than a bespoke label, so a revealed expression looks exactly like the
    /// real thing instead of a second, slightly-different notation the player has to learn.
    @ViewBuilder
    private var revealedAnswerCard: some View {
        if viewModel.isRevealed {
            VStack(alignment: .leading, spacing: 8) {
                sectionLabel("Answer")
                SolutionExpressionView(solution: viewModel.puzzle.exampleSolution, tint: viewModel.tier.accentColor)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardSurface()
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    @ViewBuilder
    private var operatorPicker: some View {
        if viewModel.isAwaitingOperation {
            HStack(spacing: 12) {
                ForEach(MathOperation.allCases, id: \.self) { operation in
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            viewModel.placeOperation(operation)
                        }
                    } label: {
                        Text(operation.symbol)
                            .font(.nbNumber(35, weight: .bold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.nbTonal(tint: operation.accentColor))
                }
            }
            .padding(20)
            .cardSurface()
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    @ViewBuilder
    private var feedbackBanner: some View {
        switch viewModel.feedback {
        case .none:
            EmptyView()
        case .correct:
            HStack(spacing: 10) {
                Image(systemName: "checkmark.seal.fill")
                    .symbolEffect(.bounce, value: correctTrigger)
                Text("Correct!")
            }
            .font(.nbNumber(18))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.nbAccent))
            .transition(.scale(scale: 0.85).combined(with: .opacity))
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
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    private var controls: some View {
        VStack(spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                    if viewModel.hasConcluded {
                        viewModel.resetEntries()
                    } else {
                        viewModel.submit()
                    }
                }
            } label: {
                Text(viewModel.hasConcluded ? "Reset" : "Submit")
            }
            .buttonStyle(.nbPrimary(tint: viewModel.tier.accentColor, isEnabled: viewModel.hasConcluded || viewModel.isComplete))
            .disabled(!viewModel.hasConcluded && !viewModel.isComplete)

            HStack(spacing: 12) {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        viewModel.undoLast()
                    }
                } label: {
                    Label("Undo", systemImage: "arrow.uturn.backward")
                }
                .buttonStyle(.nbTonal(tint: viewModel.tier.accentColor, isEnabled: viewModel.canUndo))
                .disabled(!viewModel.canUndo)

                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        viewModel.revealAnswer()
                    }
                } label: {
                    Label("Reveal Answer", systemImage: "eye.fill")
                }
                .buttonStyle(.nbTonal(tint: viewModel.tier.accentColor, isEnabled: !viewModel.isRevealed))
                .disabled(viewModel.isRevealed)
            }

            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    viewModel.newPuzzle()
                }
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
        return tokens
    }

    @ViewBuilder
    private func workspaceToken(_ token: WorkspaceToken) -> some View {
        switch token {
        case .dieSlot(let index):
            if let die = viewModel.placedDice[index] {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        viewModel.removeDieSlot(index)
                    }
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
                    withAnimation(.easeInOut(duration: 0.25)) {
                        viewModel.removeOperationSlot(index)
                    }
                } label: {
                    Text(operation.symbol)
                        .foregroundStyle(operation.accentColor)
                }
                .buttonStyle(.plain)
            } else {
                blankSlot
            }
        case .openParen:
            Text("(").foregroundStyle(.secondary)
        case .closeParen:
            Text(")").foregroundStyle(.secondary)
        }
    }

    private func dieSlotView(_ die: DieValue) -> some View {
        HStack(alignment: .top, spacing: 1) {
            Text("\(die.base)")
            if die.exponent != 1 || die.root != 1 {
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

    // MARK: - Variant picker

    /// Shown right after a tray die lands, alongside `operatorPicker` -- lets the player
    /// optionally raise that die to a power/root before moving on. Never shown for `.basic`,
    /// since a plain die only ever has one legal "variant" (itself).
    ///
    /// Straight powers (root == 1) and root-derived values are split by a vertical divider --
    /// `DieValue.variants` interleaves them (it walks exponents ascending, checking every root at
    /// each one), so without a visual break the two techniques would blur together in one row.
    ///
    /// Horizontally scrollable rather than squeezed to fit the screen -- forcing every chip into
    /// one fixed-width row (a 3-die puzzle can have 6+ options) made each one a cramped, tall
    /// oval on iPhone and broke fractions like "3/2" onto three lines for lack of room.
    @ViewBuilder
    private var variantPicker: some View {
        if viewModel.activeVariantOptions.count > 1 {
            let powers = viewModel.activeVariantOptions.filter { $0.root == 1 }
            let roots = viewModel.activeVariantOptions.filter { $0.root != 1 }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(powers, id: \.self) { variant in
                        variantButton(variant)
                    }
                    if !powers.isEmpty, !roots.isEmpty {
                        Rectangle()
                            .fill(Color.secondary.opacity(0.25))
                            .frame(width: 1)
                            .padding(.vertical, 6)
                    }
                    ForEach(roots, id: \.self) { variant in
                        variantButton(variant)
                    }
                }
                .padding(20)
            }
            .cardSurface()
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    private func variantButton(_ variant: DieValue) -> some View {
        let isSelected = viewModel.activeDieSlot.flatMap { viewModel.placedDice[$0] } == variant
        return Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                viewModel.selectVariant(variant)
            }
        } label: {
            // `NBTonalButtonStyle`/`NBPrimaryButtonStyle` only add *vertical* padding -- they
            // lean on `.frame(maxWidth: .infinity)` for horizontal breathing room, which works
            // in a full-width row but does nothing in an unconstrained scroll view, so a
            // single-character label like plain "4" would otherwise hug the pill's edges. The
            // `minWidth` on top makes every chip in a row at least as wide as the plain-value
            // one (which has no superscript to pad it out), instead of the plain case reading
            // narrower than its power/root siblings.
            variantOptionLabel(variant)
                .frame(minWidth: 30)
                .padding(.horizontal, 16)
        }
        .buttonStyle(
            isSelected
                ? AnyButtonStyle(.nbPrimary(tint: viewModel.tier.accentColor))
                : AnyButtonStyle(.nbTonal(tint: viewModel.tier.accentColor))
        )
    }

    /// Notation only, deliberately no computed value -- working out what a power/root equals is
    /// part of the practice, not something the app should do for the player.
    private func variantOptionLabel(_ die: DieValue) -> some View {
        HStack(alignment: .top, spacing: 1) {
            Text("\(die.base)")
            if die.exponent != 1 || die.root != 1 {
                Text(die.root == 1 ? "\(die.exponent)" : "\(die.exponent)/\(die.root)")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .baselineOffset(8)
            }
        }
        .font(.nbNumber(20, weight: .bold))
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

#Preview("Practice - Variant Picker (Roots)") {
    // Places the first tray die that has more than one legal variant, entirely in code -- no
    // simulated taps needed to inspect `variantPicker`'s layout on its own.
    let viewModel = PracticeViewModel(tier: .rootsAndExponents)
    if let trayIndex = viewModel.puzzle.dice.indices.first(where: { viewModel.canPlaceTrayDie(at: $0) }) {
        viewModel.placeTrayDie(at: trayIndex)
    }
    return NavigationStack {
        PracticeView(viewModel: viewModel)
    }
}
