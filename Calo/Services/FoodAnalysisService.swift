import Foundation

struct AnalyzedFood: Identifiable {
    let id = UUID()
    let name: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let grams: Double
    let confidence: Double
    let verified: Bool
}

struct AnalysisResult {
    let mealName: String
    let emoji: String
    let foods: [AnalyzedFood]
    let confidence: Double
    let componentsJSON: String?

    var totalCalories: Double { foods.reduce(0) { $0 + $1.calories } }
    var totalProtein: Double { foods.reduce(0) { $0 + $1.protein } }
    var totalCarbs: Double { foods.reduce(0) { $0 + $1.carbs } }
    var totalFat: Double { foods.reduce(0) { $0 + $1.fat } }
    var totalGrams: Double { foods.reduce(0) { $0 + $1.grams } }
}

struct FoodAnalysisService {
    /// Full pipeline: Gemini identification → USDA verification → final nutrients
    static func analyze(description: String, imageData: Data?) async throws -> AnalysisResult {
        let geminiMeal = try await GeminiService.analyze(description: description, imageData: imageData)

        var foods: [AnalyzedFood] = []

        for component in geminiMeal.components {
            // Try USDA lookup for each component
            if let usda = try? await USDAService.lookup(foodName: component.name) {
                let multiplier = component.grams / 100.0
                foods.append(AnalyzedFood(
                    name: cleanFoodName(component.name),
                    calories: (usda.calories * multiplier).rounded(to: 1),
                    protein: (usda.protein * multiplier).rounded(to: 1),
                    carbs: (usda.carbs * multiplier).rounded(to: 1),
                    fat: (usda.fat * multiplier).rounded(to: 1),
                    grams: component.grams,
                    confidence: geminiMeal.confidence,
                    verified: true
                ))
            } else {
                // Fallback to Gemini estimates
                foods.append(AnalyzedFood(
                    name: cleanFoodName(component.name),
                    calories: component.calories,
                    protein: component.protein,
                    carbs: component.carbs,
                    fat: component.fat,
                    grams: component.grams,
                    confidence: geminiMeal.confidence,
                    verified: false
                ))
            }
        }

        // Build components JSON
        let componentData = foods.map {
            FoodEntry.Component(
                name: $0.name,
                calories: $0.calories,
                protein: $0.protein,
                carbs: $0.carbs,
                fat: $0.fat,
                grams: $0.grams
            )
        }
        let componentsJSON = try? String(data: JSONEncoder().encode(componentData), encoding: .utf8)

        return AnalysisResult(
            mealName: geminiMeal.meal_name,
            emoji: geminiMeal.emoji,
            foods: foods,
            confidence: geminiMeal.confidence,
            componentsJSON: componentsJSON
        )
    }

    /// Clean USDA-style technical names into human-readable form
    private static func cleanFoodName(_ name: String) -> String {
        var cleaned = name

        // Remove parenthetical content like "(raw)" or "(cooked)"
        cleaned = cleaned.replacingOccurrences(
            of: "\\s*\\([^)]*\\)",
            with: "",
            options: .regularExpression
        )

        // Remove colon-separated qualifiers: "chicken:breast:raw" → "Chicken Breast"
        if cleaned.contains(":") {
            cleaned = cleaned.split(separator: ":").map { String($0).trimmingCharacters(in: .whitespaces) }.joined(separator: " ")
        }

        // Remove trailing ", raw" or ", cooked" etc.
        let suffixes = [", raw", ", cooked", ", boiled", ", baked", ", fried", ", grilled", ", roasted", ", steamed"]
        for suffix in suffixes {
            if cleaned.lowercased().hasSuffix(suffix) {
                cleaned = String(cleaned.dropLast(suffix.count))
            }
        }

        // Capitalize properly
        return cleaned.split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
            .joined(separator: " ")
    }
}
