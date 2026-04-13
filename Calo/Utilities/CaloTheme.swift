import SwiftUI

enum CaloTheme {
    static let coral = Color(red: 0.886, green: 0.427, blue: 0.353)
    static let background = Color.black
    static let cardBackground = Color(white: 0.12)
    static let subtleText = Color(white: 0.5)
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
