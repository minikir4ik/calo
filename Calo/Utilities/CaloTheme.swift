import SwiftUI

enum CaloTheme {
    static let coral = Color(red: 0.886, green: 0.427, blue: 0.353)
    static let background = Color(red: 0.05, green: 0.05, blue: 0.07)
    static let cardBackground = Color(red: 0.10, green: 0.10, blue: 0.12)
    static let cardBorder = Color(white: 0.15)
    static let subtleText = Color(white: 0.45)
    static let separator = Color(white: 0.15)

    static let accentGreen = Color(red: 0.35, green: 0.78, blue: 0.48)
    static let accentBlue = Color(red: 0.35, green: 0.55, blue: 0.95)
    static let accentPurple = Color(red: 0.65, green: 0.40, blue: 0.85)

    static let springAnimation = Animation.spring(duration: 0.4, bounce: 0.2)

    static func macroColor(for macro: String) -> Color {
        switch macro.lowercased() {
        case "protein": return accentGreen
        case "carbs": return accentBlue
        case "fat": return accentPurple
        case "calories": return coral
        default: return .gray
        }
    }
}
