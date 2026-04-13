import Foundation

struct GeminiFoodItem: Decodable {
    let name: String
    let grams: Double
    let confidence: Double
    let est_cal_per100g: Double
    let est_protein_per100g: Double
    let est_carbs_per100g: Double
    let est_fat_per100g: Double
}

struct GeminiResponse: Decodable {
    let foods: [GeminiFoodItem]
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

    private static let prompt = """
    You are a precise food identification system. Analyze the food photo and/or description and identify each distinct food item.

    Return ONLY valid JSON with this exact structure:
    {"foods": [{"name": "specific food name", "grams": 150, "confidence": 0.92, "est_cal_per100g": 165, "est_protein_per100g": 31, "est_carbs_per100g": 0, "est_fat_per100g": 3.6}]}

    Rules:
    - "name": use a specific, USDA-searchable food name (e.g. "chicken breast, grilled" not just "chicken")
    - "grams": estimated total weight of that item in grams
    - "confidence": 0-1 confidence in identification
    - "est_*_per100g": your best nutrient estimates per 100g (used as fallback if USDA lookup fails)
    - List each food item separately
    - Be precise with portion/weight estimates
    """

    static func analyze(description: String, imageData: Data?) async throws -> [GeminiFoodItem] {
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
        }

        parts.append(["text": "\(prompt)\n\nFood: \(description)"])

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

        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: textData)
        return geminiResponse.foods
    }
}
