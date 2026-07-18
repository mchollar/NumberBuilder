import SwiftUI
import NumberBuilderKit

/// Explains both modes behind one segmented control rather than two separate screens -- Solve
/// and Practice share the same `SolutionTier` rules, so a single view avoids duplicating that
/// section, and it gives the Practice auto-show-once intro (see `PracticeView`) a clean way to
/// open pre-selected to Practice via `initialMode`, no scroll-position hack needed.
struct HowToPlayView: View {
    enum Mode: String, CaseIterable, Hashable {
        case solve = "Explore"
        case practice = "Challenge"
    }

    @State private var mode: Mode
    /// True only when presented as a sheet (the Practice auto-show-once intro) -- pushed from
    /// About via `NavigationLink`, the automatic back button already covers dismissal.
    private var showsDoneButton: Bool
    @Environment(\.dismiss) private var dismiss

    init(initialMode: Mode = .solve, showsDoneButton: Bool = false) {
        _mode = State(initialValue: initialMode)
        self.showsDoneButton = showsDoneButton
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Mode", selection: $mode) {
                ForEach(Mode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
            .padding(.top, 12)

            List {
                switch mode {
                case .solve: solveContent
                case .practice: practiceContent
                }
            }
            .scrollContentBackground(.hidden)
        }
        .readableContentWidth()
        .background(Color.nbBackground)
        .navigationTitle("How to Play")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if showsDoneButton {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private var solveContent: some View {
        Section {
            Text("Roll three dice, then try to reach a target number by combining them with math — strictly left to right, just like the real game, with no operator precedence to worry about.")
        }
        .listRowBackground(Color.nbCardSurface)

        Section("The Basics") {
            stepRow(number: 1, text: "Tap Roll, or dial in dice by hand on the wheels.")
            stepRow(number: 2, text: "Enter a target number.")
            stepRow(number: 3, text: "Tap Calculate to see every way to reach it.")
        }
        .listRowBackground(Color.nbCardSurface)

        tierSection(title: "Solution Tiers")
    }

    @ViewBuilder
    private var practiceContent: some View {
        Section {
            Text("Challenge hands you a roll and a target — you build the answer yourself, tapping dice and operators into place left to right.")
        }
        .listRowBackground(Color.nbCardSurface)

        Section("The Basics") {
            stepRow(number: 1, text: "Pick a difficulty at the top: Basic, Exponents, or Roots.")
            stepRow(number: 2, text: "Tap a die to place it in your answer.")
            stepRow(number: 3, text: "On harder difficulties, optionally tap a power or root to change that die's value before choosing an operator.")
            stepRow(number: 4, text: "Tap +, −, ×, or ÷ to combine it with the next die.")
            stepRow(number: 5, text: "Tap Submit once your answer is complete — or tap a placed die or operator to undo back to that point.")
        }
        .listRowBackground(Color.nbCardSurface)

        tierSection(title: "Difficulty Levels")
    }

    @ViewBuilder
    private func tierSection(title: String) -> some View {
        Section(title) {
            ForEach(SolutionTier.allCases, id: \.self) { tier in
                HStack(alignment: .top, spacing: 10) {
                    Circle()
                        .fill(tier.accentColor)
                        .frame(width: 8, height: 8)
                        .padding(.top, 6)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(tier.shortTitle)
                            .fontWeight(.semibold)
                        Text(tier.explanation)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .listRowBackground(Color.nbCardSurface)
    }

    private func stepRow(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.nbNumber(14, weight: .bold))
                .foregroundStyle(Color(.systemBackground))
                .frame(width: 22, height: 22)
                .background(Circle().fill(Color.primary))
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 2)
    }
}

#Preview("How to Play - Solve") {
    NavigationStack {
        HowToPlayView()
    }
}

#Preview("How to Play - Practice Sheet") {
    NavigationStack {
        HowToPlayView(initialMode: .practice, showsDoneButton: true)
    }
}
