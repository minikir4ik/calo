import Foundation

enum TDEECalculator {
    struct MacroResult {
        let calories: Int
        let protein: Int
        let carbs: Int
        let fat: Int
    }

    /// Mifflin-St Jeor BMR
    static func bmr(weightKg: Double, heightCm: Double, age: Int, gender: String) -> Double {
        let base = (10.0 * weightKg) + (6.25 * heightCm) - (5.0 * Double(age))
        switch gender {
        case "male": return base + 5
        case "female": return base - 161
        default: return base - 78 // average
        }
    }

    static func activityMultiplier(for level: String) -> Double {
        switch level {
        case "sedentary": return 1.2
        case "light": return 1.375
        case "moderate": return 1.55
        case "very_active": return 1.725
        case "athlete": return 1.9
        default: return 1.55
        }
    }

    static func tdee(weightKg: Double, heightCm: Double, age: Int, gender: String, activityLevel: String) -> Double {
        bmr(weightKg: weightKg, heightCm: heightCm, age: age, gender: gender) * activityMultiplier(for: activityLevel)
    }

    static func calculate(
        weightKg: Double,
        heightCm: Double,
        age: Int,
        gender: String,
        activityLevel: String,
        goal: String,
        weeklyRate: Double
    ) -> MacroResult {
        let maintenanceTDEE = tdee(
            weightKg: weightKg,
            heightCm: heightCm,
            age: age,
            gender: gender,
            activityLevel: activityLevel
        )

        var targetCalories: Double
        switch goal {
        case "lose_fat":
            // weeklyRate kg/week × 7700 kcal/kg ÷ 7 days
            targetCalories = maintenanceTDEE - (weeklyRate * 7700.0 / 7.0)
        case "build_muscle":
            targetCalories = maintenanceTDEE + 300
        case "performance":
            targetCalories = maintenanceTDEE + 200
        default: // maintain
            targetCalories = maintenanceTDEE
        }

        // Floor at 1200 kcal for safety
        targetCalories = max(targetCalories, 1200)

        let proteinGrams: Double
        if goal == "build_muscle" {
            proteinGrams = weightKg * 2.2
        } else {
            proteinGrams = weightKg * 2.0
        }

        let fatCalories = targetCalories * 0.25
        let fatGrams = fatCalories / 9.0

        let proteinCalories = proteinGrams * 4.0
        let carbCalories = targetCalories - proteinCalories - fatCalories
        let carbGrams = max(carbCalories / 4.0, 50)

        return MacroResult(
            calories: Int(targetCalories.rounded()),
            protein: Int(proteinGrams.rounded()),
            carbs: Int(carbGrams.rounded()),
            fat: Int(fatGrams.rounded())
        )
    }

    /// Estimated weeks to reach target weight
    static func weeksToGoal(currentWeight: Double, targetWeight: Double, weeklyRate: Double) -> Int {
        guard weeklyRate > 0 else { return 0 }
        let diff = abs(currentWeight - targetWeight)
        return Int(ceil(diff / weeklyRate))
    }
}
