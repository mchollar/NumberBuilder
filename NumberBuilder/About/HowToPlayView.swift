import SwiftUI
import NumberBuilderKit

struct HowToPlayView: View {
    var body: some View {
        List {
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

            Section("Solution Tiers") {
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
        .scrollContentBackground(.hidden)
        .background(Color.nbBackground)
        .navigationTitle("How to Play")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func stepRow(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.nbNumber(14, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Circle().fill(Color.nbAccent))
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 2)
    }
}

#Preview("How to Play") {
    NavigationStack {
        HowToPlayView()
    }
}
