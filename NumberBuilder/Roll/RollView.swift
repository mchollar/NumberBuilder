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

struct RollView: View {
    @State private var viewModel = RollViewModel()
    @FocusState private var targetFieldFocused: Bool
    /// Bumped only by the Roll button — dice bouncing should never fire from manually scrolling
    /// a wheel to pick a value by hand.
    @State private var rollTrigger = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                rollCard
                targetCard
                progressSection
            }
            .padding(20)
        }
        .background(Color.nbBackground.ignoresSafeArea())
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Number Builder")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    AboutView()
                } label: {
                    Image(systemName: "info.circle")
                }
                .tint(.nbAccent)
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { targetFieldFocused = false }
            }
        }
        .navigationDestination(isPresented: Binding(
            get: { viewModel.hasSolved },
            set: { if !$0 { viewModel.hasSolved = false } }
        )) {
            if let solutions = viewModel.solutions {
                SolutionsSummaryView(
                    solutions: solutions,
                    diceFaces: viewModel.diceFaces,
                    target: viewModel.target ?? 0
                )
            }
        }
    }

    private var rollCard: some View {
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
            .buttonStyle(.nbTonal(tint: .nbAccent))
        }
        .padding(20)
        .cardSurface()
    }

    private var diceRow: some View {
        HStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { index in
                Picker("Die \(index + 1)", selection: Binding(
                    get: { viewModel.diceFaces[index] },
                    set: { newValue in
                        viewModel.diceFaces[index] = newValue
                        viewModel.resetForNewRoll()
                    }
                )) {
                    ForEach(1...6, id: \.self) { face in
                        Image("Dice\(face)")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 28, height: 28)
                            .tag(face)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 90)
                .clipped()
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.primary.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
                        )
                )
                .overlay {
                    // A decorative die that pops over the slot on Roll and fades away, revealing
                    // the (unanimated, still perfectly interactive) wheel underneath already
                    // settled on its new value.
                    Image("Dice\(viewModel.diceFaces[index])")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 36, height: 36)
                        .padding(10)
                        .background(Circle().fill(Color.nbCardSurface))
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
    }

    private var targetCard: some View {
        VStack(spacing: 16) {
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
                        .fill(Color.primary.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(targetFieldFocused ? Color.nbAccent : Color.primary.opacity(0.1), lineWidth: targetFieldFocused ? 2 : 1)
                        )
                )
                .onChange(of: viewModel.targetText) {
                    viewModel.resetForNewRoll()
                }
            Button {
                targetFieldFocused = false
                viewModel.calculate()
            } label: {
                Text("Calculate")
            }
            .buttonStyle(.nbPrimary(tint: .nbAccent, isEnabled: viewModel.canCalculate))
            .disabled(!viewModel.canCalculate)
        }
        .padding(20)
        .cardSurface()
    }

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
                    .tint(.nbAccent)
                Text("Total Solutions Found: \(viewModel.progressCount)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .cardSurface()
        }
    }
}

#Preview("Roll") {
    NavigationStack {
        RollView()
    }
}
