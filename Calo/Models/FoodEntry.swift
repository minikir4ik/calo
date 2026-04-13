import Foundation
import SwiftData

@Model
final class FoodEntry {
    var id: UUID
    var foodName: String
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var grams: Double
    var confidence: Double
    var verified: Bool
    @Attribute(.externalStorage) var imageData: Data?
    var timestamp: Date
    var mealType: String

    init(
        foodName: String,
        calories: Double,
        protein: Double,
        carbs: Double,
        fat: Double,
        grams: Double,
        confidence: Double,
        verified: Bool,
        imageData: Data? = nil,
        timestamp: Date = .now,
        mealType: String = "other"
    ) {
        self.id = UUID()
        self.foodName = foodName
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.grams = grams
        self.confidence = confidence
        self.verified = verified
        self.imageData = imageData
        self.timestamp = timestamp
        self.mealType = mealType
    }
}

extension FoodEntry {
    var dateString: String {
        timestamp.formatted(date: .abbreviated, time: .omitted)
    }

    var timeString: String {
        timestamp.formatted(date: .omitted, time: .shortened)
    }

    static var today: Date {
        Calendar.current.startOfDay(for: .now)
    }

    static var sevenDaysAgo: Date {
        Calendar.current.date(byAdding: .day, value: -6, to: today)!
    }
}
