import SwiftUI
import UIKit
import NumberBuilderKit

/// Phases for the die glyph that pops over a slot when Roll is tapped — the wheel picker itself
/// is never animated (it's a real interactive control; scaling/rotating it looked broken).
private enum DiePopPhase {
    case hidden, pop

    var scale: CGFloat {
        switch self {
        case .hidden: return 0.5
        case .pop: return 1.35
        }
    }

    var opacity: Double {
        switch self {
        case .hidden: return 0
        case .pop: return 1
        }
    }
}

struct SolveView: View {
    @State private var viewModel = SolveViewModel()
    @FocusState private var targetFieldFocused: Bool
    /// Bumped only by the Roll button — dice bouncing should never fire from manually scrolling
    /// a wheel to pick a value by hand.
    @State private var rollTrigger = 0
    @AppStorage(DiceAppearanceSettings.colorSchemeKey) private var diceColorScheme: DiceColorScheme = .rainbow
    @AppStorage(DiceAppearanceSettings.styleKey) private var diceStyle: DiceRenderStyle = .filledColoredBackground

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                puzzleCard
                calculateButton
                progressSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .readableContentWidth()
        }
        .background(Color.nbBackground.ignoresSafeArea())
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Number Builder")
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
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { targetFieldFocused = false }
            }
        }
        .navigationDestination(item: solveResultBinding) { result in
            SolutionsSummaryView(solutions: result.solutions, diceFaces: result.diceFaces, target: result.target)
        }
    }

    /// Roll and Calculate used to live in two separate stacked cards -- merged the roll/target
    /// setup into one so the screen reads as a single continuous flow instead of two visually
    /// identical gray boxes. Calculate itself stays outside this card as its own element (per the
    /// reference mock) -- it's the one primary action for the whole screen, not part of the setup
    /// card's own content.
    private var puzzleCard: some View {
        VStack(spacing: 16) {
            sectionLabel("Your Roll")
            diceRow
            Button {
                targetFieldFocused = false
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                viewModel.rollDice()
                rollTrigger += 1
            } label: {
                Label("Roll", systemImage: "die.face.5.fill")
                    .symbolEffect(.bounce, value: rollTrigger)
            }
            .buttonStyle(.nbOutline(tint: .rollAccent))

            Divider()
                .padding(.vertical, 4)

            sectionLabel("Target Number")
            TextField("0", text: $viewModel.targetText)
                .keyboardType(.numberPad)
                .font(.nbNumber(40))
                .multilineTextAlignment(.center)
                .focused($targetFieldFocused)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.innerSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(targetFieldFocused ? Color.primary : Color.primary.opacity(0.15), lineWidth: targetFieldFocused ? 2 : 1)
                        )
                )
                .onChange(of: viewModel.targetText) {
                    viewModel.resetForNewRoll()
                }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .cardSurface()
    }

    private var calculateButton: some View {
        Button {
            targetFieldFocused = false
            viewModel.calculate()
        } label: {
            Text("Calculate")
        }
        .buttonStyle(.nbNeutral(isEnabled: viewModel.canCalculate))
        .disabled(!viewModel.canCalculate)
    }

    /// Three dice pickers at `DiceWheelPicker`'s "big dice" max size (112x192, from an earlier
    /// explicit request) don't leave room for both the card's own padding and a real outer screen
    /// margin on every device -- 3x112 + 2x12 gaps alone is 360pt, which is nearly the *entire*
    /// width of a compact iPhone once the card's padding is added, leaving next to nothing for the
    /// margin around the card itself. Rather than a fixed size, that 112pt is now a ceiling: a
    /// `GeometryReader` reads however much width is actually proposed here (already shrunk by the
    /// screen's outer padding and the card's own internal padding, since `puzzleCard` now accepts
    /// its proposed width instead of demanding its full natural size) and scales every dice
    /// dimension down together, proportionally, only as far as needed to fit. On iPad (or any
    /// screen with room -- `readableContentWidth()` caps the column at 600pt, well over the 360pt
    /// these need at full size), the scale factor is always 1 and nothing shrinks.
    private var diceRow: some View {
        GeometryReader { proxy in
            let maxRowWidth = DiceWheelPicker.maxColumnWidth * 3 + diceGap * 2
            let scale = proxy.size.width > 0 ? min(1, proxy.size.width / maxRowWidth) : 1
            let dieWidth = DiceWheelPicker.maxColumnWidth * scale
            let dieHeight = DiceWheelPicker.maxRowHeight * 3 * scale

            HStack(spacing: diceGap * scale) {
                ForEach(0..<3, id: \.self) { index in
                    DiceWheelPicker(
                        selection: Binding(
                            get: { viewModel.diceFaces[index] },
                            set: { newValue in
                                viewModel.diceFaces[index] = newValue
                                viewModel.resetForNewRoll()
                            }
                        ),
                        colorScheme: diceColorScheme,
                        style: diceStyle,
                        index: index,
                        rowHeight: DiceWheelPicker.maxRowHeight * scale,
                        imageSize: DiceWheelPicker.maxImageSize * scale,
                        columnWidth: dieWidth
                    )
                    .id(index)
                    // UIPickerView's own intrinsic size (320x216) wins over the `sizeThatFits`
                    // override during SwiftUI's *ideal*-size layout pass (used e.g. when a parent
                    // stack up the tree computes how much space it wants), even though rendering
                    // itself already respects the smaller reported size. Left unpinned, that
                    // oversized ideal size ballooned every ancestor's width. Pinning an explicit
                    // frame here (matching the picker's own columnWidth/rowHeight*visibleRows)
                    // forces SwiftUI to treat this as a fixed leaf everywhere, not just in the
                    // final render.
                    .frame(width: dieWidth, height: dieHeight)
                    .clipped()
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.innerSurface)
                    )
                    .overlay {
                        // A decorative die that pops over the slot on Roll and fades away, revealing
                        // the (unanimated, still perfectly interactive) wheel underneath already
                        // settled on its new value.
                        DiceFaceView(value: viewModel.diceFaces[index], colorScheme: diceColorScheme, style: diceStyle, index: index, tier: nil)
                            .frame(width: 64 * scale, height: 64 * scale)
                            .allowsHitTesting(false)
                            .phaseAnimator([DiePopPhase.hidden, .pop, .hidden], trigger: rollTrigger) { view, phase in
                                view
                                    .scaleEffect(phase.scale)
                                    .opacity(phase.opacity)
                            } animation: { phase in
                                switch phase {
                                case .pop: .spring(response: 0.3, dampingFraction: 0.55).delay(Double(index) * 0.07)
                                case .hidden: .easeOut(duration: 0.22).delay(Double(index) * 0.07)
                                }
                            }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: DiceWheelPicker.maxRowHeight * 3)
    }

    private var diceGap: CGFloat { 12 }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .tracking(0.5)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var progressSection: some View {
        if viewModel.isSolving {
            VStack(spacing: 8) {
                ProgressView()
                    .tint(.primary)
                Text("Total Solutions Found: \(viewModel.progressCount)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .cardSurface()
        }
    }

    /// `navigationDestination(item:)` instead of the boolean `isPresented:` form -- the latter is
    /// where a real iPadOS 26 SwiftUI bug lives: with it, this screen's own `.navigationTitle`
    /// silently fails to render on iPad's floating tab bar (confirmed by removing it and watching
    /// the title come back), while `PracticeView`, which has no `navigationDestination` at all,
    /// was unaffected. The `item:` form carries the same push-when-solved behavior without
    /// tripping it.
    private var solveResultBinding: Binding<SolveResult?> {
        Binding(
            get: {
                guard viewModel.hasSolved, let solutions = viewModel.solutions, let target = viewModel.target else { return nil }
                return SolveResult(solutions: solutions, diceFaces: viewModel.diceFaces, target: target)
            },
            set: { if $0 == nil { viewModel.hasSolved = false } }
        )
    }
}

/// Bundles a finished solve's results for `navigationDestination(item:)` -- `Hashable` so SwiftUI
/// can use it as the destination's identity (no separate `id` needed, `Solution` is already
/// `Hashable`/`Sendable`).
private struct SolveResult: Hashable {
    let solutions: [Solution]
    let diceFaces: [Int]
    let target: Int
}

#Preview("Solve") {
    NavigationStack {
        SolveView()
    }
}
