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
    let foods: [AnalyzedFood]

    var totalCalories: Double { foods.reduce(0) { $0 + $1.calories } }
    var totalProtein: Double { foods.reduce(0) { $0 + $1.protein } }
    var totalCarbs: Double { foods.reduce(0) { $0 + $1.carbs } }
    var totalFat: Double { foods.reduce(0) { $0 + $1.fat } }
}

struct FoodAnalysisService {
    /// Full pipeline: Gemini identification → USDA verification → final nutrients
    static func analyze(description: String, imageData: Data?) async throws -> AnalysisResult {
        let geminiItems = try await GeminiService.analyze(description: description, imageData: imageData)

        var foods: [AnalyzedFood] = []

        for item in geminiItems {
            let multiplier = item.grams / 100.0

            // Try USDA lookup
            if let usda = try? await USDAService.lookup(foodName: item.name) {
                foods.append(AnalyzedFood(
                    name: item.name,
                    calories: (usda.calories * multiplier).rounded(to: 1),
                    protein: (usda.protein * multiplier).rounded(to: 1),
                    carbs: (usda.carbs * multiplier).rounded(to: 1),
                    fat: (usda.fat * multiplier).rounded(to: 1),
                    grams: item.grams,
                    confidence: item.confidence,
                    verified: true
                ))
            } else {
                // Fallback to Gemini estimates
                foods.append(AnalyzedFood(
                    name: item.name,
                    calories: (item.est_cal_per100g * multiplier).rounded(to: 1),
                    protein: (item.est_protein_per100g * multiplier).rounded(to: 1),
                    carbs: (item.est_carbs_per100g * multiplier).rounded(to: 1),
                    fat: (item.est_fat_per100g * multiplier).rounded(to: 1),
                    grams: item.grams,
                    confidence: item.confidence,
                    verified: false
                ))
            }
        }

        return AnalysisResult(foods: foods)
    }
}
