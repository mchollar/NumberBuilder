import SwiftUI
import NumberBuilderKit

// MARK: - Palette

extension Color {
    /// Primary accent — roll/calculate actions, and the "Basic" solution tier.
    static let nbAccent = Color("SlamRed")
    /// Secondary accent — the "Using Exponents" solution tier.
    static let nbSecondary = Color("AppCyan")
    /// Tertiary accent — the "Using Exponents & Roots" solution tier.
    static let nbTertiary = Color("RootViolet")
    /// Screen background, distinct from card surfaces so cards read as elevated.
    static let nbBackground = Color("BackgroundGray")
    /// Card/row surface, elevated above `nbBackground`.
    static let nbCardSurface = Color("CardSurface")
}

extension SolutionTier {
    var accentColor: Color {
        switch self {
        case .basic: return .nbAccent
        case .exponents: return .nbSecondary
        case .rootsAndExponents: return .nbTertiary
        }
    }

    var shortTitle: String {
        switch self {
        case .basic: return "Basic"
        case .exponents: return "Exponents"
        case .rootsAndExponents: return "Exponents & Roots"
        }
    }

    var explanation: String {
        switch self {
        case .basic: return "Uses only +, −, ×, and ÷."
        case .exponents: return "Also allows whole-number exponents, like 5²."
        case .rootsAndExponents: return "Also allows roots — fractional exponents, like 5 to the ½."
        }
    }
}

// MARK: - Typography

extension Font {
    /// Large rounded numerals — dice faces, the target number, headline results.
    static func nbNumber(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

// MARK: - Card surface

private struct CardSurfaceModifier: ViewModifier {
    var cornerRadius: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.nbCardSurface)
            )
            .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
    }
}

extension View {
    /// Legacy name kept for the About header; equivalent to `cardSurface()`.
    func cardShadow() -> some View {
        modifier(CardSurfaceModifier())
    }

    func cardSurface(cornerRadius: CGFloat = 20) -> some View {
        modifier(CardSurfaceModifier(cornerRadius: cornerRadius))
    }
}

// MARK: - Button styles

/// Full-width, capsule, filled accent button with a press-down scale — the app's primary action.
struct NBPrimaryButtonStyle: ButtonStyle {
    var tint: Color = .nbAccent
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.nbNumber(17, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Capsule(style: .continuous)
                    .fill(isEnabled ? tint : Color.gray.opacity(0.35))
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Tonal capsule button — secondary actions like "Roll" alongside a primary "Calculate".
struct NBTonalButtonStyle: ButtonStyle {
    var tint: Color = .nbAccent

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.nbNumber(17, weight: .semibold))
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Capsule(style: .continuous)
                    .fill(tint.opacity(0.15))
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == NBPrimaryButtonStyle {
    static var nbPrimary: NBPrimaryButtonStyle { NBPrimaryButtonStyle() }
    static func nbPrimary(tint: Color = .nbAccent, isEnabled: Bool = true) -> NBPrimaryButtonStyle {
        NBPrimaryButtonStyle(tint: tint, isEnabled: isEnabled)
    }
}

extension ButtonStyle where Self == NBTonalButtonStyle {
    static var nbTonal: NBTonalButtonStyle { NBTonalButtonStyle() }
    static func nbTonal(tint: Color = .nbAccent) -> NBTonalButtonStyle { NBTonalButtonStyle(tint: tint) }
}

// MARK: - Adaptive width

/// Constrains and centers content on wide screens (iPad, or an iPhone in landscape) so cards and
/// lists don't stretch edge-to-edge on a big display; a no-op on compact-width screens.
private struct ReadableContentWidthModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    var maxWidth: CGFloat

    func body(content: Content) -> some View {
        HStack {
            Spacer(minLength: 0)
            content.frame(maxWidth: horizontalSizeClass == .regular ? maxWidth : .infinity)
            Spacer(minLength: 0)
        }
    }
}

extension View {
    func readableContentWidth(_ maxWidth: CGFloat = 600) -> some View {
        modifier(ReadableContentWidthModifier(maxWidth: maxWidth))
    }
}
