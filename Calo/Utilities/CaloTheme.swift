import SwiftUI

enum CaloTheme {
    static let coral = Color(red: 226/255, green: 109/255, blue: 90/255)
    static let background = Color.black
    static let surfacePrimary = Color(white: 0.08)
    static let surfaceSecondary = Color(white: 0.12)
    static let separator = Color(white: 0.18)

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
