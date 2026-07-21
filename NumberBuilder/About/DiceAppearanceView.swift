import SwiftUI
import NumberBuilderKit

/// Shared `UserDefaults` keys for the player's dice appearance choice -- read by every real
/// dice-rendering call site (`SolveView`, `ChallengeView`, `DiceWheelPicker`), written only here.
enum DiceAppearanceSettings {
    static let colorSchemeKey = "diceColorScheme"
    static let styleKey = "diceRenderStyle"
}

/// Lets the player pick how dice are drawn -- reached from `AboutView`. `DiceFaceView` does the
/// actual drawing; this screen is just a picker over its two axes (color source, render style)
/// plus a live preview so a choice is visible before committing to it.
struct DiceAppearanceView: View {
    @AppStorage(DiceAppearanceSettings.colorSchemeKey) private var colorScheme: DiceColorScheme = .rainbow
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

                // No labels here on purpose -- unlike Color (where the same shape means
                // different things depending on the word next to it), each style is visually
                // self-explanatory on sight, so a kid can just tap the look they like.
                optionSection(title: "Style") {
                    HStack(spacing: 20) {
                        ForEach(DiceRenderStyle.allCases) { option in
                            styleSwatch(option)
                        }
                    }
                    .padding(14)
                    .cardSurface(cornerRadius: 16)
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
                        .foregroundStyle(Color.primary)
                }
            }
            .padding(14)
            .cardSurface(cornerRadius: 16)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(isSelected ? Color.primary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    /// Style swatches skip the row/checkmark treatment `optionRow` uses for Color -- just the die
    /// itself with a ring when selected. VoiceOver still gets `option.label` even though it's
    /// never shown on screen.
    private func styleSwatch(_ option: DiceRenderStyle) -> some View {
        let isSelected = style == option
        return Button {
            style = option
        } label: {
            DiceFaceView(value: 4, colorScheme: colorScheme, style: option, index: 1, tier: .exponents)
                .frame(width: 64, height: 64)
                .padding(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(isSelected ? Color.primary : Color.clear, lineWidth: 3)
                )
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .accessibilityLabel(option.label)
    }
}

#Preview("Dice Appearance") {
    NavigationStack {
        DiceAppearanceView()
    }
}
