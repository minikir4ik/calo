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
    case serverBusy

    var errorDescription: String? {
        switch self {
        case .noApiKey: return "Gemini API key not configured"
        case .invalidResponse: return "Could not parse Gemini response"
        case .httpError(let code): return "Gemini API error (HTTP \(code))"
        case .serverBusy: return "AI is temporarily unavailable — tap to retry"
        }
    }
}

struct GeminiService {
    // 2.5-flash for food analysis (needs vision + reasoning)
    private static let analysisEndpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"
    // 2.5-flash-lite for text-only suggestions (fast, cheap)
    private static let suggestEndpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent"

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

        let text = try await sendRequest(body: body, apiKey: apiKey, endpoint: analysisEndpoint, timeout: 30)

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

        let remaining = targetCalories - Int(currentCalories)
        let remainingP = targetProtein - Int(currentProtein)

        let prompt = "Eaten: \(Int(currentCalories))cal \(Int(currentProtein))p \(Int(currentCarbs))c \(Int(currentFat))f. Goal: \(targetCalories)cal \(targetProtein)p. Need ~\(remaining)cal \(remainingP)p more. Suggest 3 meals. JSON only: {\"suggestions\":[{\"name\":\"...\",\"description\":\"short\",\"estimated_calories\":0,\"estimated_protein\":0,\"emoji\":\"🍽\"}]}"

        let keyPrefix = String(apiKey.prefix(10))
        print("🤖 AI Suggest: key=\(keyPrefix)..., prompt=\(prompt.count) chars, starting at \(Date())")

        let body: [String: Any] = [
            "contents": [["parts": [["text": prompt]]]],
            "generationConfig": [
                "responseMimeType": "application/json",
                "temperature": 0.8
            ]
        ]

        let text = try await sendRequest(body: body, apiKey: apiKey, endpoint: suggestEndpoint, timeout: 15)
        print("🤖 AI Suggest: response received at \(Date())")

        guard let textData = text.data(using: .utf8) else {
            throw GeminiError.invalidResponse
        }

        let suggestionsResponse = try JSONDecoder().decode(SuggestionsResponse.self, from: textData)
        return suggestionsResponse.suggestions
    }

    // MARK: - Shared Request with Retry

    private static func sendRequest(body: [String: Any], apiKey: String, endpoint: String? = nil, timeout: TimeInterval = 30, maxRetries: Int = 3) async throws -> String {
        let url = endpoint ?? analysisEndpoint
        var lastError: Error = GeminiError.invalidResponse

        for attempt in 0..<maxRetries {
            if attempt > 0 {
                // Exponential backoff: 1s, 2s
                let delay = UInt64(pow(2.0, Double(attempt - 1))) * 1_000_000_000
                try await Task.sleep(nanoseconds: delay)
            }

            var request = URLRequest(url: URL(string: "\(url)?key=\(apiKey)")!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            request.timeoutInterval = timeout

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw GeminiError.invalidResponse
            }

            // Retry on 503 (overloaded), 429 (rate limit), 500 (server error)
            if [503, 429, 500].contains(httpResponse.statusCode) {
                lastError = GeminiError.serverBusy
                continue
            }

            guard httpResponse.statusCode == 200 else {
                let errorBody = String(data: data, encoding: .utf8) ?? "no body"
                print("⚠️ Gemini HTTP \(httpResponse.statusCode): \(errorBody)")
                throw GeminiError.httpError(httpResponse.statusCode)
            }

            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let candidates = json?["candidates"] as? [[String: Any]],
                  let content = candidates.first?["content"] as? [String: Any],
                  let responseParts = content["parts"] as? [[String: Any]],
                  let text = responseParts.first?["text"] as? String else {
                throw GeminiError.invalidResponse
            }

            return text
        }

        throw lastError
    }
}
