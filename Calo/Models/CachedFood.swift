import Foundation
import SwiftData

@Model
final class CachedFood {
    @Attribute(.unique) var foodName: String
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var grams: Double
    var emoji: String
    var verified: Bool
    var cachedAt: Date
    var lookupCount: Int

    init(
        foodName: String,
        calories: Double,
        protein: Double,
        carbs: Double,
        fat: Double,
        grams: Double = 100,
        emoji: String = "",
        verified: Bool = true,
        cachedAt: Date = .now,
        lookupCount: Int = 0
    ) {
        self.foodName = foodName.lowercased().trimmingCharacters(in: .whitespaces)
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.grams = grams
        self.emoji = emoji
        self.verified = verified
        self.cachedAt = cachedAt
        self.lookupCount = lookupCount
    }
}
