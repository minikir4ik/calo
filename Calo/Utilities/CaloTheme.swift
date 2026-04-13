import SwiftUI

enum CaloTheme {
    static let coral = Color("CoralColor")

    static let cardBackground = Color(.secondarySystemBackground)
    static let cardRadius: CGFloat = 16
    static let cardShadow: CGFloat = 4

    static let springAnimation = Animation.spring(duration: 0.4, bounce: 0.2)

    static func macroColor(for macro: String) -> Color {
        switch macro.lowercased() {
        case "protein": return .blue
        case "carbs": return .orange
        case "fat": return .purple
        case "calories": return coral
        default: return .gray
        }
    }
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(CaloTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: CaloTheme.cardRadius, style: .continuous))
            .shadow(color: .black.opacity(0.08), radius: CaloTheme.cardShadow, y: 2)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}
