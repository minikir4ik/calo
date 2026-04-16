import Foundation
import SwiftData

@Model
final class OnboardingData {
    var hasCompletedOnboarding: Bool
    var goal: String
    var activityLevel: String
    var age: Int
    var heightCm: Double
    var weightKg: Double
    var gender: String
    var targetWeightKg: Double
    var weeklyRate: Double
    var calculatedCalories: Int
    var calculatedProtein: Int
    var calculatedCarbs: Int
    var calculatedFat: Int

    init(
        hasCompletedOnboarding: Bool = false,
        goal: String = "maintain",
        activityLevel: String = "moderate",
        age: Int = 25,
        heightCm: Double = 170,
        weightKg: Double = 70,
        gender: String = "male",
        targetWeightKg: Double = 70,
        weeklyRate: Double = 0.5,
        calculatedCalories: Int = 2000,
        calculatedProtein: Int = 150,
        calculatedCarbs: Int = 250,
        calculatedFat: Int = 65
    ) {
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.goal = goal
        self.activityLevel = activityLevel
        self.age = age
        self.heightCm = heightCm
        self.weightKg = weightKg
        self.gender = gender
        self.targetWeightKg = targetWeightKg
        self.weeklyRate = weeklyRate
        self.calculatedCalories = calculatedCalories
        self.calculatedProtein = calculatedProtein
        self.calculatedCarbs = calculatedCarbs
        self.calculatedFat = calculatedFat
    }
}
