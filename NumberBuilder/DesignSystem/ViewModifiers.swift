import SwiftUI
import UIKit

extension Color {
    static let numberBuilderAccent = Color("SlamRed")
    static let numberBuilderSurface = Color("BackgroundGray")
    static let numberBuilderHighlight = Color("AppCyan")
}

private struct CardShadow: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemBackground))
            )
            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
    }
}

extension View {
    func cardShadow() -> some View {
        modifier(CardShadow())
    }
}
