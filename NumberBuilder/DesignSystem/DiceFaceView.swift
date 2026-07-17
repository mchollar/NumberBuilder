import SwiftUI
import NumberBuilderKit

/// A vector-drawn die face -- replaces the fixed PNG dice art (`Assets.xcassets/Dice`) with
/// something that can pick up the app's own color tokens and adapt to the player's chosen
/// appearance (`DebugResettableFlag`-style shared `@AppStorage` keys live in
/// `DiceAppearanceSettings`, set from `DiceAppearanceView`, reached from `AboutView`).
struct DiceFaceView: View {
    let value: Int
    var colorScheme: DiceColorScheme = .primary
    var style: DiceRenderStyle = .filledColoredBackground
    /// Which of the three tray positions this is, 0-based -- only used by `.rainbow` (rotates
    /// through red/yellow/blue); `.tierColored` doesn't need it since tier is a single app-wide
    /// value, not per-die.
    var index: Int = 0
    /// The active `SolutionTier`, when there is one -- only Practice has a tier concept; Solve
    /// mode passes `nil` and `.tierColored` falls back to `.basic`'s color there.
    var tier: SolutionTier?

    private var background: Color {
        switch style {
        case .filledColoredBackground: return colorScheme.color(forIndex: index, tier: tier)
        case .filledWhiteBackground, .minimalOutline: return Color(.systemBackground)
        }
    }

    private var pip: Color {
        switch style {
        case .filledColoredBackground:
            // `.plain`'s "color" is `Color.primary`, which is white in dark mode -- the same
            // white a hardcoded pip color would be, making pips vanish against their own
            // background. `.systemBackground` is `.primary`'s adaptive opposite in both
            // appearances, so it stays a real background/pip contrast either way. Every other
            // scheme is a fixed saturated hue that already contrasts fine against white.
            return colorScheme == .plain ? Color(.systemBackground) : .white
        case .filledWhiteBackground: return colorScheme.color(forIndex: index, tier: tier)
        case .minimalOutline: return colorScheme.color(forIndex: index, tier: tier)
        }
    }

    /// Always at least a faint neutral outline, not just for `.minimalOutline` -- `.plain` on
    /// `.filledColoredBackground`/`.filledWhiteBackground` is white-on-white with nothing else to
    /// separate it from the card surface it sits on, so it needs a border regardless of style.
    private var border: Color {
        switch style {
        case .minimalOutline: return colorScheme.color(forIndex: index, tier: tier)
        case .filledColoredBackground, .filledWhiteBackground: return Color.primary.opacity(0.08)
        }
    }

    /// Fraction of the die's *rendered* side length, not a fixed point value -- at a fixed 16pt,
    /// the radius ate a bigger share of the shape as the die got smaller (a 44pt die and a 64pt
    /// die both got the same 16pt corner, so the smaller one looked proportionally more rounded,
    /// pill-like, and cramped for pips). Scaling by size keeps the look this project settled on
    /// at 64pt consistent at every size the app actually renders dice.
    private static let cornerRadiusRatio: CGFloat = 16 / 64
    /// Same reasoning as `cornerRadiusRatio`, for the padding around the pip grid.
    private static let pipInsetRatio: CGFloat = 12 / 64

    private var borderWidth: CGFloat {
        style == .minimalOutline ? 2 : 1
    }

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let cornerRadius = side * Self.cornerRadiusRatio
            let inset = side * Self.pipInsetRatio
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(background)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(border, lineWidth: borderWidth)
                )
                .overlay(pipGrid.padding(inset))
        }
        .aspectRatio(1, contentMode: .fit)
        .shadow(color: .black.opacity(0.10), radius: 6, y: 2)
    }

    /// Standard 3x3 die-pip layout, same positions real dice use.
    private var pipGrid: some View {
        let positions: Set<GridPosition>
        switch value {
        case 1: positions = [.center]
        case 2: positions = [.topRight, .bottomLeft]
        case 3: positions = [.topRight, .center, .bottomLeft]
        case 4: positions = [.topLeft, .topRight, .bottomLeft, .bottomRight]
        case 5: positions = [.topLeft, .topRight, .center, .bottomLeft, .bottomRight]
        case 6: positions = [.topLeft, .midLeft, .bottomLeft, .topRight, .midRight, .bottomRight]
        default: positions = []
        }
        return GeometryReader { proxy in
            ForEach(GridPosition.allCases, id: \.self) { position in
                if positions.contains(position) {
                    Circle()
                        .fill(pip)
                        .frame(width: proxy.size.width / 4, height: proxy.size.width / 4)
                        .position(position.point(in: proxy.size))
                }
            }
        }
    }

    private enum GridPosition: CaseIterable {
        case topLeft, topRight, midLeft, midRight, bottomLeft, bottomRight, center

        func point(in size: CGSize) -> CGPoint {
            let x: CGFloat
            let y: CGFloat
            switch self {
            case .topLeft, .midLeft, .bottomLeft: x = size.width * 0.16
            case .topRight, .midRight, .bottomRight: x = size.width * 0.84
            case .center: x = size.width * 0.5
            }
            switch self {
            case .topLeft, .topRight: y = size.height * 0.16
            case .midLeft, .midRight, .center: y = size.height * 0.5
            case .bottomLeft, .bottomRight: y = size.height * 0.84
            }
            return CGPoint(x: x, y: y)
        }
    }
}

/// Where the die's accent color comes from. `String` raw values so it can back an `@AppStorage`
/// selection directly. Labels are written for the app's kid audience -- plain color/behavior
/// words instead of the internal scheme names.
enum DiceColorScheme: String, CaseIterable, Identifiable {
    var id: Self { self }

    /// Single consistent color (the app's own primary accent), regardless of context.
    case primary
    /// The active `SolutionTier`'s color in Practice; falls back to `.basic`'s color wherever
    /// there's no real tier to read (Solve mode).
    case tierColored
    /// Rotates through red/yellow/blue by tray position -- a fixed, kid-recognizable primary-color
    /// set, independent of `MathOperation.accentColor` (which stays green/orange/blue/pink for
    /// operator symbols elsewhere; this scheme just needed its own distinct palette).
    case rainbow
    /// Neutral/plain -- no color at all, just ink-on-surface.
    case plain

    func color(forIndex index: Int, tier: SolutionTier?) -> Color {
        switch self {
        case .primary: return .nbAccent
        case .tierColored: return (tier ?? .basic).accentColor
        case .rainbow:
            let colors: [Color] = [.red, .yellow, .blue]
            return colors[index % colors.count]
        case .plain: return Color.primary
        }
    }

    var label: String {
        switch self {
        case .primary: return "Red"
        case .tierColored: return "By Difficulty"
        case .rainbow: return "Rainbow"
        case .plain: return "Plain"
        }
    }
}

enum DiceRenderStyle: String, CaseIterable, Identifiable {
    var id: Self { self }

    case filledColoredBackground
    case filledWhiteBackground
    case minimalOutline

    var label: String {
        switch self {
        case .filledColoredBackground: return "Colored bg, white pips"
        case .filledWhiteBackground: return "White bg, colored pips"
        case .minimalOutline: return "Minimal outline"
        }
    }
}

#Preview("Dice Comparison") {
    ScrollView {
        VStack(alignment: .leading, spacing: 28) {
            Text("Color schemes (colored-bg style)")
                .font(.headline)
            ForEach(DiceColorScheme.allCases, id: \.self) { scheme in
                VStack(alignment: .leading, spacing: 8) {
                    Text(scheme.label).font(.subheadline).foregroundStyle(.secondary)
                    HStack(spacing: 12) {
                        ForEach(0..<3) { index in
                            DiceFaceView(value: [1, 4, 6][index], colorScheme: scheme, style: .filledColoredBackground, index: index, tier: .exponents)
                                .frame(width: 64, height: 64)
                        }
                    }
                }
            }

            Divider()

            Text("Render styles (primary-accent color)")
                .font(.headline)
            ForEach(DiceRenderStyle.allCases, id: \.self) { style in
                VStack(alignment: .leading, spacing: 8) {
                    Text(style.label).font(.subheadline).foregroundStyle(.secondary)
                    HStack(spacing: 12) {
                        ForEach(0..<3) { index in
                            DiceFaceView(value: [1, 4, 6][index], colorScheme: .primary, style: style, index: index, tier: nil)
                                .frame(width: 64, height: 64)
                        }
                    }
                }
            }
        }
        .padding(24)
    }
    .background(Color.nbBackground)
}
