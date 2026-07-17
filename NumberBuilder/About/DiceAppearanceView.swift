import SwiftUI
import NumberBuilderKit

/// Shared `UserDefaults` keys for the player's dice appearance choice -- read by every real
/// dice-rendering call site (`SolveView`, `PracticeView`, `DiceWheelPicker`), written only here.
enum DiceAppearanceSettings {
    static let colorSchemeKey = "diceColorScheme"
    static let styleKey = "diceRenderStyle"
}

/// Lets the player pick how dice are drawn -- reached from `AboutView`. `DiceFaceView` does the
/// actual drawing; this screen is just a picker over its two axes (color source, render style)
/// plus a live preview so a choice is visible before committing to it.
struct DiceAppearanceView: View {
    @AppStorage(DiceAppearanceSettings.colorSchemeKey) private var colorScheme: DiceColorScheme = .primary
    @AppStorage(DiceAppearanceSettings.styleKey) private var style: DiceRenderStyle = .filledColoredBackground

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                preview

                optionSection(title: "Color") {
                    ForEach(DiceColorScheme.allCases) { option in
                        optionRow(
                            isSelected: colorScheme == option,
                            label: option.label,
                            swatch: DiceFaceView(value: 4, colorScheme: option, style: style, index: 1, tier: .exponents)
                        ) {
                            colorScheme = option
                        }
                    }
                }

                optionSection(title: "Style") {
                    ForEach(DiceRenderStyle.allCases) { option in
                        optionRow(
                            isSelected: style == option,
                            label: option.label,
                            swatch: DiceFaceView(value: 4, colorScheme: colorScheme, style: option, index: 1, tier: .exponents)
                        ) {
                            style = option
                        }
                    }
                }
            }
            .padding(20)
            .readableContentWidth()
        }
        .background(Color.nbBackground)
        .navigationTitle("Dice Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var preview: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { index in
                    DiceFaceView(value: [1, 4, 6][index], colorScheme: colorScheme, style: style, index: index, tier: .exponents)
                        .frame(width: 80, height: 80)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .cardSurface()
    }

    private func optionSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .tracking(0.5)
            VStack(spacing: 10) {
                content()
            }
        }
    }

    private func optionRow(isSelected: Bool, label: String, swatch: DiceFaceView, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                swatch.frame(width: 56, height: 56)
                Text(label)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.nbAccent)
                }
            }
            .padding(14)
            .cardSurface(cornerRadius: 16)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(isSelected ? Color.nbAccent : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview("Dice Appearance") {
    NavigationStack {
        DiceAppearanceView()
    }
}
