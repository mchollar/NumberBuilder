import SwiftUI
import NumberBuilderKit

struct RollView: View {
    @State private var viewModel = RollViewModel()
    @FocusState private var targetFieldFocused: Bool

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
                viewModel.rollDice()
            } label: {
                Label("Roll", systemImage: "die.face.5.fill")
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
