import SwiftUI
import UIKit
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
    /// (Solve results, Challenge's operator picker and placed workspace tokens) — distinct from
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
        case .rootsAndExponents: return "Also allows fractional exponents — a power and a root combined, like 4 to the 3/2, or occasionally a plain root like the square root of 4."
        }
    }
}

// MARK: - Shared metrics

/// Named values for numbers that repeated across multiple files for the same reason, found by
/// the 2026-07-21 magic-numbers audit -- every value here matches exactly what was already on
/// screen, so wiring these in is a naming pass, not a visual change. Deliberately excludes values
/// that only repeated by coincidence, not shared meaning (see the audit report for the full
/// reasoning) -- not every number in the app belongs in this list, only the ones doing the same
/// conceptual job in more than one place.
enum NBMetrics {
    static let cardCornerRadius: CGFloat = 20
    static let cardOuterPadding: CGFloat = 20
    /// `readableContentWidth()`'s regular-size-class (iPad) cap -- exposed as a named value so
    /// anything that needs to independently recompute the same effective content width (see
    /// `ChallengeView.answerCard`) can match it exactly, instead of guessing 600 a second time.
    static let readableContentMaxWidth: CGFloat = 600
    static let screenHorizontalMargin: CGFloat = 20
    static let innerElementPadding: CGFloat = 14
    static let buttonVerticalPadding: CGFloat = 16
    static let innerControlCornerRadius: CGFloat = 14
    static let iconContainerCornerRadius: CGFloat = 16
    static let hairlineBorderWidth: CGFloat = 1
    static let disabledBorderOpacity: Double = 0.15
    static let iconBadgeWashOpacity: Double = 0.18
    static let standardInteractionAnimation: Animation = .easeInOut(duration: 0.25)
    static let buttonPressAnimation: Animation = .spring(response: 0.25, dampingFraction: 0.7)
    static let standardDieIconSize: CGFloat = 64
    static let trayDieSize: CGFloat = 56
    static let bulletDotSize: CGFloat = 8
}

// MARK: - Typography

/// Large rounded numerals — dice faces, the target number, headline results. Scales with Dynamic
/// Type via `@ScaledMetric`, not a raw fixed-size `.system(size:)` font (which never grows or
/// shrinks with Text Size at all) and not a plain `UIFontMetrics.default.scaledValue(for:)` call
/// either -- an earlier version of this used that directly inside a `static func` returning a
/// plain `Font`, which shipped a real, live bug: since nothing in the view hierarchy actually
/// *read* an environment value SwiftUI tracks, SwiftUI had no way to know a given Text's
/// appearance depended on Dynamic Type, so it never proactively re-rendered that view when the
/// system text size changed live. The font value only updated the next time that view happened to
/// re-render for some unrelated reason (e.g. a tap changing other state) -- which looked like
/// content "fixing itself" after any interaction, and meant some elements (a `TextField`'s digits,
/// a button's label) stayed stuck at their old size when text size was turned back down. Only a
/// property wrapper declared on an actual `View`/`ViewModifier` (like `@ScaledMetric` here)
/// participates in SwiftUI's environment-dependency graph and triggers a real re-render when
/// Dynamic Type changes.
private struct NBNumberFontModifier: ViewModifier {
    @ScaledMetric private var size: CGFloat
    let weight: Font.Weight

    init(size: CGFloat, weight: Font.Weight) {
        self._size = ScaledMetric(wrappedValue: size)
        self.weight = weight
    }

    func body(content: Content) -> some View {
        content.font(.system(size: size, weight: weight, design: .rounded))
    }
}

extension View {
    func nbNumberFont(_ size: CGFloat, weight: Font.Weight = .bold) -> some View {
        modifier(NBNumberFontModifier(size: size, weight: weight))
    }
}

// MARK: - Card surface

private struct CardSurfaceModifier: ViewModifier {
    var cornerRadius: CGFloat = NBMetrics.cardCornerRadius

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.nbCardSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.cardBorder, lineWidth: NBMetrics.hairlineBorderWidth)
            )
            .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
    }
}

extension View {
    /// Legacy name kept for the About header; equivalent to `cardSurface()`.
    func cardShadow() -> some View {
        modifier(CardSurfaceModifier())
    }

    func cardSurface(cornerRadius: CGFloat = NBMetrics.cardCornerRadius) -> some View {
        modifier(CardSurfaceModifier(cornerRadius: cornerRadius))
    }
}

// MARK: - Contrast-aware color

/// Picks white or black text/icons for this color as a background, based on real WCAG contrast
/// math rather than an eyeballed brightness cutoff -- e.g. `NBPrimaryButtonStyle` hardcoding
/// white text washed out at 2.89:1 (light mode) / 1.85:1 (dark mode) against the Exponents
/// tier's cyan accent (WCAG's 3:1 minimum for large/bold text and non-text UI elements), and
/// `DiceFaceView`'s rainbow dice put white pips on yellow at 1.51:1. Both now pick their
/// foreground from this instead of assuming white always works on a saturated accent color.
///
/// Deliberately keeps white wherever it already clears 3:1 (red's dice pips pass at 3.55:1, for
/// instance) rather than always switching to whichever of black/white has the single highest
/// ratio -- that would have silently repainted colors that were never actually broken.
extension Color {
    var contrastAwareForeground: Color {
        let contrastWithWhite = 1.05 / (Self.relativeLuminance(self) + 0.05)
        return contrastWithWhite >= 3.0 ? .white : .black
    }

    /// Darkens this color just enough to clear WCAG's 3:1 non-text minimum against `background`,
    /// preserving hue/saturation -- for icon badges (Settings' rows, Results Help's tier cards)
    /// that render the same tint twice, once as a full-strength icon and once as a faint wash
    /// behind it. Some hues (yellow, green) are too light at full saturation to ever clear 3:1
    /// against *any* light card surface, no matter how the wash's own opacity is tuned -- as the
    /// wash approaches the icon's own color, contrast only drops further, never rises. Left
    /// unchanged wherever it already passes (most tints do).
    func accessibleIconTint(against background: Color) -> Color {
        guard Self.contrastRatio(self, background) < 3.0 else { return self }
        let uiColor = UIColor(self)
        var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
        guard uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) else {
            return self
        }
        var candidate = self
        var currentBrightness = brightness
        for _ in 0..<12 {
            currentBrightness *= 0.85
            candidate = Color(hue: hue, saturation: saturation, brightness: currentBrightness)
            if Self.contrastRatio(candidate, background) >= 3.0 {
                break
            }
        }
        return candidate
    }

    private static func relativeLuminance(_ color: Color) -> CGFloat {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        func linearize(_ channel: CGFloat) -> CGFloat {
            channel <= 0.03928 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
        }
        // Real WCAG relative luminance (sRGB-gamma-corrected), not a naive weighted RGB average.
        return 0.2126 * linearize(red) + 0.7152 * linearize(green) + 0.0722 * linearize(blue)
    }

    private static func contrastRatio(_ a: Color, _ b: Color) -> CGFloat {
        let l1 = relativeLuminance(a)
        let l2 = relativeLuminance(b)
        return (max(l1, l2) + 0.05) / (min(l1, l2) + 0.05)
    }
}

// MARK: - Button styles

/// Full-width, capsule, filled accent button with a press-down scale — the app's primary action.
struct NBPrimaryButtonStyle: ButtonStyle {
    var tint: Color = .nbAccent
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .nbNumberFont(17, weight: .semibold)
            .foregroundStyle(isEnabled ? tint.contrastAwareForeground : .white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, NBMetrics.buttonVerticalPadding)
            .background(
                Capsule(style: .continuous)
                    .fill(isEnabled ? tint : Color.gray.opacity(0.35))
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(NBMetrics.buttonPressAnimation, value: configuration.isPressed)
    }
}

/// Tonal capsule button — secondary actions like "Roll" alongside a primary "Calculate".
struct NBTonalButtonStyle: ButtonStyle {
    var tint: Color = .nbAccent
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .nbNumberFont(17, weight: .semibold)
            .foregroundStyle(isEnabled ? tint : Color.gray)
            .frame(maxWidth: .infinity)
            .padding(.vertical, NBMetrics.buttonVerticalPadding)
            .background(
                Capsule(style: .continuous)
                    .fill((isEnabled ? tint : Color.gray).opacity(NBMetrics.disabledBorderOpacity))
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(NBMetrics.buttonPressAnimation, value: configuration.isPressed)
    }
}

/// Solid, appearance-inverted capsule button -- `Color.primary` fill (near-black in light mode,
/// near-white in dark mode) with `Color(.systemBackground)` text (the adaptive opposite, so it
/// always contrasts against its own fill without a hardcoded color that would break in one mode --
/// the exact bug class the dice `.plain` scheme and `HowToPlayView`'s step badges both hit before).
/// Used where a primary action should carry no hue at all -- Solve's Calculate button -- distinct
/// from `NBPrimaryButtonStyle`, which stays available for tier/accent-tinted primary buttons
/// (Challenge's Submit/Reset) that are explicitly meant to keep their color.
struct NBNeutralButtonStyle: ButtonStyle {
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .nbNumberFont(17, weight: .semibold)
            .foregroundStyle(isEnabled ? Color(.systemBackground) : Color.mutedText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, NBMetrics.buttonVerticalPadding)
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
                    .strokeBorder(isEnabled ? Color.clear : Color.primary.opacity(NBMetrics.disabledBorderOpacity), lineWidth: NBMetrics.hairlineBorderWidth)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(NBMetrics.buttonPressAnimation, value: configuration.isPressed)
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
            .nbNumberFont(17, weight: .semibold)
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, NBMetrics.buttonVerticalPadding)
            .background(
                // A brief tint wash while held -- the scale-down alone was too subtle to read as
                // "this responded to my touch" on an otherwise-transparent outline button.
                Capsule(style: .continuous)
                    .fill(tint.opacity(configuration.isPressed ? 0.18 : 0))
            )
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
            .animation(NBMetrics.buttonPressAnimation, value: configuration.isPressed)
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
///
/// Compact (iPhone) used to just be `HStack { Spacer(minLength: 0); content.frame(maxWidth: .infinity);
/// Spacer(minLength: 0) }`. That shipped a real bug at extreme Dynamic Type sizes: `.frame(maxWidth:)`
/// only ever caps how far a view is *allowed* to grow -- it never forces content to actually measure
/// at a smaller size. An `HStack` grants each non-`Spacer` child its own ideal/natural width before
/// handing any leftover space to the `Spacer`s, so a single row anywhere inside `content` that
/// reported an oversized ideal width (any row of `.nbNumberFont`-scaled text at AX5) silently
/// expanded this whole wrapper, and every sibling row got centered and clipped along with it.
/// `.containerRelativeFrame` fixes that: it proposes a real, bounded width down into `content`
/// regardless of what content's ideal size wants.
///
/// Regular (iPad) still uses the original `HStack` + `.frame(maxWidth:)` approach, not
/// `.containerRelativeFrame` -- briefly unified with the compact case, which shipped a *different*
/// real bug: `.containerRelativeFrame` measures against a container reference that, on iPad with the
/// floating tab bar, does not match the actual visible content area the tab bar insets from the true
/// screen edges. The `HStack` form doesn't have this problem because it just uses whatever width its
/// real SwiftUI parent actually proposes to it (which already correctly reflects that inset), rather
/// than independently re-deriving a container size. Confirmed by direct bisection: reverting this one
/// case to the old `HStack` form fixed a real, visible mismatch between the readable-content column
/// and the app's own background on iPad.
///
/// Compact (iPhone) is now back to the *exact* original `.frame(maxWidth: .infinity)` too -- briefly
/// switched to `.containerRelativeFrame` (fed by an independently-measured width, to route around the
/// iPad problem above) to fix the AX5 overflow bug, but that introduced a *third*, separate
/// `.containerRelativeFrame` unreliability: after rotating an iPhone to landscape and back to
/// portrait, the whole readable-content column can get stuck reporting the landscape width, with
/// nothing to prompt a fresh measurement (reported live on a real device, confirmed by direct
/// bisection against this exact modifier -- not a simulator artifact, and not fixed by routing the
/// measurement through an independently-measured value instead of trusting `.containerRelativeFrame`'s
/// own `length` -- the unreliability is in `.containerRelativeFrame` itself, not in how its input is
/// sourced). This modifier governs the *entire* readable-content column on every screen, so it's not
/// the place to accept that risk. `.containerRelativeFrame` was then tried scoped narrowly instead,
/// just to `ChallengeView.answerCard` (the actual source of the AX5 overflow this used to guard
/// against), on the theory that a single-card, single-screen usage wouldn't share the same rotation
/// bug -- confirmed wrong by the user on a real device: rotating the Challenge tab reproduced the
/// identical staleness, and because that card's own reported size fed back into its shared parent
/// `VStack`'s width, the stale size poisoned every sibling right along with it, exactly like the
/// original AX5 leak. `.containerRelativeFrame` is retired from this app entirely; the AX5 leak is
/// now stopped at its actual source -- see `ChallengeView.answerCard`'s own doc comment -- by capping
/// the *effective* Dynamic Type scale its oversized content responds to, so it can never report an
/// oversized ideal size in the first place, and this modifier no longer needs a hard cap of its own.
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

/// Centers short content vertically within a `ScrollView` on iPad, instead of leaving it stranded
/// at the top with a wall of empty space below -- a no-op on iPhone (where content already tends
/// to fill the screen), and a no-op whenever content is actually taller than the screen (more
/// results, bigger Dynamic Type, the keyboard up), since `minHeight` only ever raises the frame's
/// floor, never caps its growth, so normal top-anchored scrolling still takes over once needed.
private struct VerticallyCenteredWhenRegularModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    var containerHeight: CGFloat

    func body(content: Content) -> some View {
        content.frame(
            minHeight: horizontalSizeClass == .regular ? containerHeight : nil,
            alignment: .center
        )
    }
}

private struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

extension View {
    func readableContentWidth(_ maxWidth: CGFloat = NBMetrics.readableContentMaxWidth) -> some View {
        modifier(ReadableContentWidthModifier(maxWidth: maxWidth))
    }

    func verticallyCenteredWhenRegular(containerHeight: CGFloat) -> some View {
        modifier(VerticallyCenteredWhenRegularModifier(containerHeight: containerHeight))
    }

    /// Reads this view's own height into `binding` passively via an overlay, instead of wrapping
    /// it in a `GeometryReader` that becomes a structural parent in the layout pass -- that
    /// approach caused a real, shipped bug: at extreme Dynamic Type sizes, the very first layout
    /// pass of a `GeometryReader`-wrapped screen could render with stale width math (content
    /// overflowing the screen edge entirely) until *any* subsequent state change forced a fresh
    /// layout pass to correct it.
    ///
    /// This uses `.overlay`, not `.background` -- a real, confirmed difference, not a stylistic
    /// choice. An earlier version used `.background(GeometryReader{...})`, matching the pattern
    /// most SwiftUI writeups show; attached directly to a `ScrollView`, that combination's
    /// `.onPreferenceChange` never actually fired -- confirmed by displaying the bound value live
    /// and watching it sit at `0` indefinitely, no matter how long the screen had to settle,
    /// which silently broke every feature that depended on it (`verticallyCenteredWhenRegular` on
    /// iPad, and an attempted fix elsewhere that measured a card's width the same way). Swapping
    /// to `.overlay` on the exact same call site immediately produced a real, correct value.
    /// `Color.clear` inside the overlay means there's nothing to visually disrupt either way.
    func measuringHeight(into binding: Binding<CGFloat>) -> some View {
        overlay(
            GeometryReader { proxy in
                Color.clear.preference(key: HeightPreferenceKey.self, value: proxy.size.height)
            }
        )
        .onPreferenceChange(HeightPreferenceKey.self) { binding.wrappedValue = $0 }
    }
}
