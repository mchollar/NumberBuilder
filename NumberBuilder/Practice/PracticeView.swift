import SwiftUI
import NumberBuilderKit

/// Shared `UserDefaults` keys the Debug Menu can reset -- centralized as named constants rather
/// than string literals duplicated across files (a typo in a duplicated key wouldn't error, just
/// silently point at a second default).
enum DebugResettableFlag {
    static let hasSeenPracticeIntroKey = "hasSeenPracticeIntro"
    /// How many free Challenge puzzles have been completed/revealed toward the trial limit --
    /// read/written by `PurchaseManager`, reset here by `DebugMenuView` for testing.
    static let freeChallengePuzzlesUsedKey = "freeChallengePuzzlesUsed"
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
    @AppStorage(DiceAppearanceSettings.colorSchemeKey) private var diceColorScheme: DiceColorScheme = .rainbow
    @AppStorage(DiceAppearanceSettings.styleKey) private var diceStyle: DiceRenderStyle = .filledColoredBackground
    /// The *voluntary* look at the paywall, reached by tapping the trial banner before the cap is
    /// hit -- distinct from `viewModel.isPaywalled`'s forced, non-dismissable body substitution.
    @State private var showingPaywallSheet = false

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
        Group {
            if viewModel.isPaywalled {
                PaywallView()
            } else {
                normalContent
            }
        }
        .navigationTitle("Challenge")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    SettingsView()
                } label: {
                    Image(systemName: "gearshape")
                }
                .tint(.primary)
            }
        }
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
        .sheet(isPresented: $showingPaywallSheet) {
            PaywallView(onDismiss: { showingPaywallSheet = false })
        }
        .onChange(of: viewModel.feedback) { _, newValue in
            if case .correct = newValue {
                correctTrigger += 1
            }
        }
        .onChange(of: PurchaseManager.shared.isUnlocked) { _, isUnlocked in
            // Resume play automatically once a purchase/restore lands while paywalled -- no
            // reason to make the player manually retry New Puzzle after paying for exactly that.
            if isUnlocked, viewModel.isPaywalled {
                viewModel.newPuzzle()
            }
        }
        .navigationDestination(item: allSolutionsResultBinding) { result in
            SolutionsSummaryView(solutions: result.solutions, diceFaces: result.diceFaces, target: result.target)
        }
    }

    private var normalContent: some View {
        // The trial banner is pinned above the `ScrollView` in a plain `VStack` rather than via
        // `.safeAreaInset(edge: .top)` -- that combination silently suppresses the navigation
        // bar's large title (the space stays reserved, but the title text itself never draws),
        // a real SwiftUI quirk, not something specific to this screen's content.
        VStack(spacing: 0) {
            if !PurchaseManager.shared.isUnlocked {
                trialBanner
            }
            ScrollView {
                VStack(spacing: 20) {
                    levelPicker
                    puzzleCard
                    answerCard
                    variantPicker
                    operatorPicker
                    controls
                }
                .padding(20)
                .readableContentWidth()
            }
            .background(Color.nbBackground.ignoresSafeArea())
        }
    }

    /// Tells players about the free trial up front (visible from puzzle 1, not only once they're
    /// running low) rather than only surfacing it once they hit the cap. Pinned above the
    /// scrolling content via `.safeAreaInset` so it stays visible without scrolling away.
    private var trialBanner: some View {
        Button {
            showingPaywallSheet = true
        } label: {
            HStack {
                Text("🎉 Free Trial — \(remainingFreePuzzles) puzzle\(remainingFreePuzzles == 1 ? "" : "s") left")
                    .font(.footnote.weight(.semibold))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(Color.nbCardSurface)
        }
        .buttonStyle(.plain)
        .foregroundStyle(viewModel.tier.accentColor)
    }

    private var remainingFreePuzzles: Int {
        max(0, PurchaseManager.freeTrialLimit - PurchaseManager.shared.freePuzzlesUsed)
    }

    /// `navigationDestination(item:)`, not the boolean `isPresented:` form -- see `SolveView`'s
    /// own identical note on the real iPadOS bug that form trips.
    private var allSolutionsResultBinding: Binding<AllSolutionsResult?> {
        Binding(
            get: {
                guard viewModel.hasLoadedAllSolutions, let solutions = viewModel.allSolutions else { return nil }
                return AllSolutionsResult(solutions: solutions, diceFaces: viewModel.puzzle.dice, target: viewModel.puzzle.target)
            },
            set: { if $0 == nil { viewModel.hasLoadedAllSolutions = false } }
        )
    }

    /// One row, not two -- an earlier design split "which techniques" (tier) and "how intense"
    /// (a separate toggle) into two stacked button rows, which took up too much vertical space
    /// for a single difficulty choice. `PracticeLevel` bundles both into one ordered dial, shown
    /// as a stepper with its own explanation directly underneath so the level is self-describing
    /// without a trip to How to Play.
    private var levelPicker: some View {
        VStack(spacing: 6) {
            HStack {
                levelStepButton(systemImage: "chevron.left", isEnabled: viewModel.level != .one) {
                    viewModel.selectLevel(viewModel.level.previous)
                }
                Spacer()
                Text("Level \(viewModel.level.rawValue)")
                    .font(.nbNumber(20, weight: .bold))
                    .foregroundStyle(viewModel.tier.accentColor)
                    .contentTransition(.numericText())
                Spacer()
                levelStepButton(systemImage: "chevron.right", isEnabled: viewModel.level != .six) {
                    viewModel.selectLevel(viewModel.level.next)
                }
            }
            Text(viewModel.level.description)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
    }

    private func levelStepButton(systemImage: String, isEnabled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                action()
            }
        } label: {
            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))
                .frame(width: 44, height: 44)
        }
        .foregroundStyle(isEnabled ? viewModel.tier.accentColor : Color.secondary.opacity(0.3))
        .disabled(!isEnabled)
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
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                    .layoutPriority(1)
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
                    // A used die reads as "this slot is empty, its die went into the answer above"
                    // rather than just a fainter copy of itself -- matches `blankSlot`'s dashed
                    // square in the answer card, so the same "nothing here" language is reused
                    // instead of inventing a second one.
                    if isUsed {
                        Image(systemName: "square.dashed")
                            .font(.system(size: 26))
                            .foregroundStyle(.secondary.opacity(0.4))
                            .frame(width: 56, height: 56)
                    } else {
                        DiceFaceView(value: face, colorScheme: diceColorScheme, style: diceStyle, index: index, tier: viewModel.tier)
                            .frame(width: 56, height: 56)
                            .opacity(isAvailable ? 1 : 0.35)
                    }
                }
                .disabled(!isAvailable)
            }
        }
        .padding(8)
        .overlay(highlightBorder(viewModel.isAwaitingDie, cornerRadius: 14))
        .animation(.easeInOut(duration: 0.25), value: viewModel.isAwaitingDie)
    }

    /// The moving "it's this section's turn" indicator shared by the dice tray, variant row, and
    /// operator row -- all three stay visible and in place the whole puzzle now (see
    /// `variantPicker`/`operatorPicker`'s doc comments for why they used to reveal/hide instead),
    /// so this border is what actually shows the player where to look next.
    private func highlightBorder(_ isActive: Bool, cornerRadius: CGFloat = 20) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .strokeBorder(isActive ? viewModel.tier.accentColor : Color.clear, lineWidth: 2.5)
    }

    /// Everything about the player's attempt lives in one card now -- the built expression, the
    /// correct/incorrect status once there's one to show (never phrased as a bare "= N" the way
    /// this used to be, which reads as a claim about the player's own expression rather than a
    /// goal reminder -- that ambiguity is exactly what made revealing-without-submitting look like
    /// a correct answer even when it wasn't), and the revealed solution folded in below a divider
    /// instead of spawning a second floating card. No standing target restatement either -- the
    /// roll card above already shows it; see `statusLine`'s doc comment.
    private var answerCard: some View {
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

            // No standing "Target: N" line here -- the roll card right above already shows the
            // target, and repeating it a few inches lower added nothing until there was an actual
            // result to react to. The target only resurfaces once `statusLine` has something to
            // compare it against (a Submit or a Reveal), folded into that one line instead of
            // living here permanently.
            statusLine

            if viewModel.isRevealed {
                Divider()
                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Here's One Way")
                    HStack(alignment: .firstTextBaseline) {
                        // Reuses `SolutionExpressionView` (Solve mode's own results renderer)
                        // rather than a bespoke label, so a revealed expression looks exactly
                        // like the real thing instead of a second, slightly-different notation
                        // to learn.
                        SolutionExpressionView(solution: viewModel.puzzle.exampleSolution, tint: viewModel.tier.accentColor)
                        Spacer()
                        // The one example above is just one way -- this hands the same dice/
                        // target to the real solver (via `PuzzleSolver`, shared with Solve mode)
                        // and pushes Explore's own results screen once it's done, matching
                        // Explore's exact solve-then-push interaction rather than inventing a
                        // second navigation pattern.
                        Button {
                            viewModel.showAllSolutions()
                        } label: {
                            HStack(spacing: 2) {
                                Text("Show all")
                                Image(systemName: "chevron.right")
                            }
                            .font(.footnote.weight(.semibold))
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(viewModel.tier.accentColor)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }

    @ViewBuilder
    private var statusLine: some View {
        switch viewModel.feedback {
        case .none:
            EmptyView()
        case .correct:
            // The target only ever reappears here, folded into the one moment it's actually
            // doing work: confirming the match, not restating a number already visible above.
            // Fixed green rather than `tier.accentColor` -- Basic's tier color is the same red
            // `.incorrect` uses below, which made a correct answer look like an error on that tier.
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .symbolEffect(.bounce, value: correctTrigger)
                Text("Correct! = \(viewModel.puzzle.target)")
            }
            .font(.nbNumber(24, weight: .bold))
            .foregroundStyle(.green)
            .frame(maxWidth: .infinity, alignment: .center)
            .transition(.scale(scale: 0.85).combined(with: .opacity))
        case .incorrect(let got):
            // Both numbers in one line, read as a false equation -- clearer at a glance than a
            // sentence, and the only place the target needs to show up at all once there's
            // something real to compare it against.
            HStack(spacing: 8) {
                Image(systemName: "xmark.circle.fill")
                Text("\(got) ≠ \(viewModel.puzzle.target)")
            }
            .font(.nbNumber(24, weight: .bold))
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity, alignment: .center)
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    /// Always on screen from the first frame, rather than appearing only once a die is placed --
    /// the operator symbols are the same every turn regardless of puzzle state, so there's
    /// nothing to wait to compute. `highlightBorder`/disabled-dimming show whether it's actually
    /// this row's turn instead of the row itself popping in and out.
    private var operatorPicker: some View {
        let isActive = viewModel.isAwaitingOperation
        return HStack(spacing: 12) {
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
                .buttonStyle(.nbTonal(tint: operation.accentColor, isEnabled: isActive))
                .disabled(!isActive)
            }
        }
        .padding(20)
        .cardSurface()
        .overlay(highlightBorder(isActive))
        .animation(.easeInOut(duration: 0.25), value: isActive)
    }

    private var controls: some View {
        // Once the puzzle is solved, "Reset" (retry the same roll) shouldn't outrank "New Puzzle"
        // (move on) as the primary action -- a win state's main CTA is "keep going," not "do that
        // again." Incorrect/revealed states keep Reset as primary, since retrying the same puzzle
        // is genuinely the likely next move there.
        let isCorrect = viewModel.feedback == .correct
        return VStack(spacing: 12) {
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
            .buttonStyle(
                isCorrect
                    ? AnyButtonStyle(.nbTonal(tint: viewModel.tier.accentColor))
                    : AnyButtonStyle(.nbPrimary(tint: viewModel.tier.accentColor, isEnabled: viewModel.hasConcluded || viewModel.isComplete))
            )
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
            .buttonStyle(
                isCorrect
                    ? AnyButtonStyle(.nbPrimary(tint: viewModel.tier.accentColor))
                    : AnyButtonStyle(.nbTonal(tint: viewModel.tier.accentColor))
            )
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .tracking(0.5)
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

    /// Always on screen (from the first frame, alongside `operatorPicker`) for every tier except
    /// `.basic` -- a plain die only ever has one legal "variant" (itself), so there's never
    /// anything to choose there and the row would just sit permanently empty all puzzle long.
    /// For the two harder tiers, though, it's present the whole time: empty/disabled before a die
    /// is active (its content is die-specific, so there's nothing real to show pre-emptively),
    /// populated and highlighted once a die lands with more than one option. Both the variant row
    /// and `operatorPicker` can be highlighted together right after a die lands -- changing the
    /// variant and choosing the next operator are both legal next taps at that point, it's not a
    /// strict one-at-a-time sequence.
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
        if viewModel.tier != .basic {
            let isActive = viewModel.activeDieSlot != nil && viewModel.activeVariantOptions.count > 1
            Group {
                if isActive {
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
                } else {
                    Text("—")
                        .font(.nbNumber(20, weight: .bold))
                        .foregroundStyle(.secondary.opacity(0.4))
                        .frame(maxWidth: .infinity, minHeight: 20)
                        .padding(20)
                }
            }
            .cardSurface()
            .overlay(highlightBorder(isActive))
            .animation(.easeInOut(duration: 0.25), value: isActive)
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

/// Bundles a "Show all" solve's results for `navigationDestination(item:)` -- mirrors `SolveView`'s
/// own `SolveResult` exactly, just named for where it's produced.
private struct AllSolutionsResult: Hashable {
    let solutions: [Solution]
    let diceFaces: [Int]
    let target: Int
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
    let viewModel = PracticeViewModel(level: .five)
    if let trayIndex = viewModel.puzzle.dice.indices.first(where: { viewModel.canPlaceTrayDie(at: $0) }) {
        viewModel.placeTrayDie(at: trayIndex)
    }
    return NavigationStack {
        PracticeView(viewModel: viewModel)
    }
}

/// Builds and places `puzzle.exampleSolution` exactly, tray tap by tray tap, via the view model's
/// own public API -- guarantees a complete, *correct* workspace without simulating touches or
/// needing to reverse-engineer a valid answer by hand for every preview.
@MainActor
private func buildExampleSolution(_ viewModel: PracticeViewModel) {
    let solution = viewModel.puzzle.exampleSolution
    for (index, die) in solution.dice.enumerated() {
        guard let trayIndex = viewModel.puzzle.dice.indices.first(where: { idx in
            !viewModel.usedTrayIndices.contains(idx) && viewModel.puzzle.dice[idx] == die.base
        }) else { continue }
        viewModel.placeTrayDie(at: trayIndex)
        if viewModel.activeDieSlot != nil,
           let match = viewModel.activeVariantOptions.first(where: { $0.exponent == die.exponent && $0.root == die.root }) {
            viewModel.selectVariant(match)
        }
        if index < solution.operations.count {
            viewModel.placeOperation(solution.operations[index])
        }
    }
}

/// Places every tray die at its plain value, joined with `+` -- a complete workspace that's
/// virtually never the target (targets aren't generated as a plain left-to-right sum), which is
/// all a "here's what an incorrect attempt looks like" preview needs.
@MainActor
private func buildNaiveWrongGuess(_ viewModel: PracticeViewModel) {
    let diceCount = viewModel.puzzle.dice.count
    for index in 0..<diceCount {
        guard let trayIndex = viewModel.puzzle.dice.indices.first(where: { !viewModel.usedTrayIndices.contains($0) }) else { continue }
        viewModel.placeTrayDie(at: trayIndex)
        if index < diceCount - 1 {
            viewModel.placeOperation(.add)
        }
    }
}

#Preview("Answer Card - Complete, Unsubmitted") {
    let viewModel = PracticeViewModel(level: .three)
    buildExampleSolution(viewModel)
    return NavigationStack {
        PracticeView(viewModel: viewModel)
    }
}

#Preview("Answer Card - Correct") {
    let viewModel = PracticeViewModel(level: .three)
    buildExampleSolution(viewModel)
    viewModel.submit()
    return NavigationStack {
        PracticeView(viewModel: viewModel)
    }
}

#Preview("Answer Card - Incorrect") {
    let viewModel = PracticeViewModel(level: .one)
    buildNaiveWrongGuess(viewModel)
    viewModel.submit()
    return NavigationStack {
        PracticeView(viewModel: viewModel)
    }
}

#Preview("Answer Card - Revealed (never submitted)") {
    // The exact scenario that started this redesign: an incorrect, complete workspace, revealed
    // without ever tapping Submit.
    let viewModel = PracticeViewModel(level: .one)
    buildNaiveWrongGuess(viewModel)
    viewModel.revealAnswer()
    return NavigationStack {
        PracticeView(viewModel: viewModel)
    }
}

#Preview("Answer Card - Revealed after Incorrect") {
    let viewModel = PracticeViewModel(level: .one)
    buildNaiveWrongGuess(viewModel)
    viewModel.submit()
    viewModel.revealAnswer()
    return NavigationStack {
        PracticeView(viewModel: viewModel)
    }
}
