import SwiftUI
import NumberBuilderKit

struct RollView: View {
    @State private var viewModel = RollViewModel()
    @FocusState private var targetFieldFocused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                diceRow
                rollButton
                targetField
                calculateButton
                progressSection
            }
            .padding(24)
        }
        .navigationTitle("Number Builder")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    AboutView()
                } label: {
                    Image(systemName: "info.circle")
                }
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
                        Image("Dice\(face)").tag(face)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 90, height: 110)
            }
        }
    }

    private var rollButton: some View {
        Button {
            targetFieldFocused = false
            viewModel.rollDice()
        } label: {
            Label("Roll", systemImage: "die.face.5")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
    }

    private var targetField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Target Number")
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField("Enter a number", text: $viewModel.targetText)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .focused($targetFieldFocused)
                .onChange(of: viewModel.targetText) {
                    viewModel.resetForNewRoll()
                }
        }
    }

    private var calculateButton: some View {
        Button {
            targetFieldFocused = false
            viewModel.calculate()
        } label: {
            Text("Calculate")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .disabled(!viewModel.canCalculate)
    }

    @ViewBuilder
    private var progressSection: some View {
        if viewModel.isSolving {
            VStack(spacing: 8) {
                ProgressView()
                Text("Total Solutions Found: \(viewModel.progressCount)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
