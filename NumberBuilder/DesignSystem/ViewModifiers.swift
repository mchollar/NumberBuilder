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

extension MathOperation {
    /// Consistent per-operator color, shared by every screen that renders an operator symbol
    /// (Solve results, Practice's operator picker and placed workspace tokens) — distinct from
    /// the tier accent colors so the two color systems don't blur together.
    var accentColor: Color {
        switch self {
        case .add: return .green
        case .subtract: return .orange
        case .multiply: return .blue
        case .divide: return .pink
        }
    }
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
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.cardBorder, lineWidth: 1)
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
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.nbNumber(17, weight: .semibold))
            .foregroundStyle(isEnabled ? tint : Color.gray)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Capsule(style: .continuous)
                    .fill((isEnabled ? tint : Color.gray).opacity(0.15))
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Solid, appearance-inverted capsule button -- `Color.primary` fill (near-black in light mode,
/// near-white in dark mode) with `Color(.systemBackground)` text (the adaptive opposite, so it
/// always contrasts against its own fill without a hardcoded color that would break in one mode --
/// the exact bug class the dice `.plain` scheme and `HowToPlayView`'s step badges both hit before).
/// Used where a primary action should carry no hue at all -- Solve's Calculate button -- distinct
/// from `NBPrimaryButtonStyle`, which stays available for tier/accent-tinted primary buttons
/// (Practice's Submit/Reset) that are explicitly meant to keep their color.
struct NBNeutralButtonStyle: ButtonStyle {
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.nbNumber(17, weight: .semibold))
            .foregroundStyle(isEnabled ? Color(.systemBackground) : Color.mutedText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Capsule(style: .continuous)
                    .fill(isEnabled ? Color.primary : Color.innerSurface)
            )
            .overlay(
                // The disabled fill (innerSurface) sits close in lightness to the new softer page
                // background -- without this, the capsule's own edges were nearly invisible,
                // reading as a borderless rectangle rather than a button. The enabled state
                // (solid black/white) already has plenty of contrast on its own.
                Capsule(style: .continuous)
                    .strokeBorder(isEnabled ? Color.clear : Color.primary.opacity(0.15), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == NBNeutralButtonStyle {
    static var nbNeutral: NBNeutralButtonStyle { NBNeutralButtonStyle() }
    static func nbNeutral(isEnabled: Bool = true) -> NBNeutralButtonStyle { NBNeutralButtonStyle(isEnabled: isEnabled) }
}

/// Outline/ghost capsule button — transparent fill, a colored border and text, no background
/// wash. Quieter than `NBTonalButtonStyle` (which fills with a translucent tint) -- used for
/// Solve's Roll button, so it reads as a secondary action next to the solid neutral Calculate.
struct NBOutlineButtonStyle: ButtonStyle {
    var tint: Color = .nbAccent

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.nbNumber(17, weight: .semibold))
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Capsule(style: .continuous)
                    .strokeBorder(tint, lineWidth: 1.5)
            )
            // A stroke-only background has a transparent interior, so without an explicit hit
            // shape SwiftUI only registers taps on the label/border pixels themselves -- the
            // empty middle of the pill didn't respond at all. This makes the whole capsule
            // tappable, matching every other button style here (which get this for free from
            // their opaque fill).
            .contentShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == NBOutlineButtonStyle {
    static var nbOutline: NBOutlineButtonStyle { NBOutlineButtonStyle() }
    static func nbOutline(tint: Color = .nbAccent) -> NBOutlineButtonStyle { NBOutlineButtonStyle(tint: tint) }
}

extension ButtonStyle where Self == NBPrimaryButtonStyle {
    static var nbPrimary: NBPrimaryButtonStyle { NBPrimaryButtonStyle() }
    static func nbPrimary(tint: Color = .nbAccent, isEnabled: Bool = true) -> NBPrimaryButtonStyle {
        NBPrimaryButtonStyle(tint: tint, isEnabled: isEnabled)
    }
}

extension ButtonStyle where Self == NBTonalButtonStyle {
    static var nbTonal: NBTonalButtonStyle { NBTonalButtonStyle() }
    static func nbTonal(tint: Color = .nbAccent, isEnabled: Bool = true) -> NBTonalButtonStyle {
        NBTonalButtonStyle(tint: tint, isEnabled: isEnabled)
    }
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
