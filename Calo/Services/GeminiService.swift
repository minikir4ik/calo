import Foundation

struct GeminiMealResponse: Decodable {
    let meal_name: String
    let emoji: String
    let total_grams: Double
    let total_calories: Double
    let total_protein: Double
    let total_carbs: Double
    let total_fat: Double
    let confidence: Double
    let components: [GeminiComponent]
}

struct GeminiComponent: Decodable {
    let name: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let grams: Double
}

enum GeminiError: LocalizedError {
    case noApiKey
    case invalidResponse
    case httpError(Int)

    var errorDescription: String? {
        switch self {
        case .noApiKey: return "Gemini API key not configured"
        case .invalidResponse: return "Could not parse Gemini response"
        case .httpError(let code): return "Gemini API error (HTTP \(code))"
        }
    }
}

struct GeminiService {
    private static let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"

    private static let imagePrompt = """
    You are a precise food identification system. Analyze the food photo and description.

    IMPORTANT: If the photo shows a composed meal, plate, or combo — return it as ONE meal with a descriptive name (e.g. "Big Mac Combo", "Caesar Salad with Grilled Chicken", "Breakfast Plate"). List the individual components inside the "components" array with their individual macros.

    Return ONLY valid JSON with this exact structure:
    {"meal_name": "Grilled Chicken Salad", "emoji": "🥗", "total_grams": 350, "total_calories": 420, "total_protein": 38, "total_carbs": 12, "total_fat": 24, "confidence": 0.92, "components": [{"name": "Grilled Chicken Breast", "calories": 280, "protein": 32, "carbs": 0, "fat": 12, "grams": 180}, {"name": "Mixed Greens", "calories": 15, "protein": 1, "carbs": 3, "fat": 0, "grams": 80}]}

    Rules:
    - "meal_name": a short, human-readable name like a restaurant menu item (NOT technical USDA names). Examples: "Grilled Chicken", "Pepperoni Pizza", "Açaí Bowl"
    - "emoji": a single food emoji that best represents the meal
    - total_* fields: total macros for the entire meal (sum of components)
    - "components": individual items that make up the meal, each with their own macros
    - "confidence": 0-1 confidence in identification
    - Be precise with portion/weight estimates
    - Use natural, appetizing names people would recognize
    """

    private static let textPrompt = """
    You are a precise food nutrition estimation system. Estimate the nutritional content of the described food.

    Return ONLY valid JSON with this exact structure:
    {"meal_name": "Grilled Chicken Breast", "emoji": "🍗", "total_grams": 180, "total_calories": 280, "total_protein": 32, "total_carbs": 0, "total_fat": 12, "confidence": 0.85, "components": [{"name": "Grilled Chicken Breast", "calories": 280, "protein": 32, "carbs": 0, "fat": 12, "grams": 180}]}

    Rules:
    - "meal_name": a short, human-readable name like a restaurant menu item. Examples: "Grilled Chicken", "Pepperoni Pizza", "Açaí Bowl"
    - "emoji": a single food emoji that best represents the meal
    - total_* fields: total macros for the entire meal
    - "components": individual items (can be just one item for simple foods)
    - "confidence": 0-1 confidence in your estimate
    - Be precise with portion/weight estimates for a typical serving
    - Use natural, appetizing names people would recognize
    """

    static func analyze(description: String, imageData: Data?) async throws -> GeminiMealResponse {
        guard let apiKey = Bundle.main.infoDictionary?["GEMINI_API_KEY"] as? String,
              !apiKey.isEmpty else {
            throw GeminiError.noApiKey
        }

        var parts: [[String: Any]] = []

        if let imageData {
            parts.append([
                "inline_data": [
                    "mime_type": "image/jpeg",
                    "data": imageData.base64EncodedString()
                ]
            ])
            parts.append(["text": "\(imagePrompt)\n\nFood: \(description)"])
        } else {
            parts.append(["text": "\(textPrompt)\n\nEstimate the nutritional content of: \(description)"])
        }

        let body: [String: Any] = [
            "contents": [["parts": parts]],
            "generationConfig": [
                "responseMimeType": "application/json",
                "temperature": 0.1
            ]
        ]

        var request = URLRequest(url: URL(string: "\(endpoint)?key=\(apiKey)")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw GeminiError.httpError(httpResponse.statusCode)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let candidates = json?["candidates"] as? [[String: Any]],
              let content = candidates.first?["content"] as? [String: Any],
              let responseParts = content["parts"] as? [[String: Any]],
              let text = responseParts.first?["text"] as? String else {
            throw GeminiError.invalidResponse
        }

        guard let textData = text.data(using: .utf8) else {
            throw GeminiError.invalidResponse
        }

        return try JSONDecoder().decode(GeminiMealResponse.self, from: textData)
    }

    // MARK: - AI Meal Suggestions

    struct MealSuggestion: Decodable, Identifiable {
        let name: String
        let description: String
        let estimated_calories: Int
        let estimated_protein: Int
        let emoji: String

        var id: String { name }
    }

    struct SuggestionsResponse: Decodable {
        let suggestions: [MealSuggestion]
    }

    static func suggestMeals(
        currentCalories: Double,
        currentProtein: Double,
        currentCarbs: Double,
        currentFat: Double,
        targetCalories: Int,
        targetProtein: Int,
        targetCarbs: Int,
        targetFat: Int
    ) async throws -> [MealSuggestion] {
        guard let apiKey = Bundle.main.infoDictionary?["GEMINI_API_KEY"] as? String,
              !apiKey.isEmpty else {
            throw GeminiError.noApiKey
        }

        let prompt = """
        Based on today's intake so far: \(Int(currentCalories)) calories, \(Int(currentProtein))g protein, \(Int(currentCarbs))g carbs, \(Int(currentFat))g fat.
        Daily goals: \(targetCalories) calories, \(targetProtein)g protein, \(targetCarbs)g carbs, \(targetFat)g fat.

        Suggest 3 specific, practical meal ideas for their next meal that would help balance their remaining macros. Be specific (e.g. "Grilled Salmon with Quinoa" not just "fish").

        Return ONLY valid JSON:
        {"suggestions": [{"name": "Grilled Salmon Bowl", "description": "Salmon fillet over quinoa with steamed broccoli", "estimated_calories": 480, "estimated_protein": 38, "emoji": "🐟"}]}
        """

        let body: [String: Any] = [
            "contents": [["parts": [["text": prompt]]]],
            "generationConfig": [
                "responseMimeType": "application/json",
                "temperature": 0.7
            ]
        ]

        var request = URLRequest(url: URL(string: "\(endpoint)?key=\(apiKey)")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw GeminiError.invalidResponse
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let candidates = json?["candidates"] as? [[String: Any]],
              let content = candidates.first?["content"] as? [String: Any],
              let responseParts = content["parts"] as? [[String: Any]],
              let text = responseParts.first?["text"] as? String,
              let textData = text.data(using: .utf8) else {
            throw GeminiError.invalidResponse
        }

        let suggestionsResponse = try JSONDecoder().decode(SuggestionsResponse.self, from: textData)
        return suggestionsResponse.suggestions
    }
}
