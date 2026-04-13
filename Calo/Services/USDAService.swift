import Foundation

struct USDANutrients {
    var calories: Double = 0
    var protein: Double = 0
    var carbs: Double = 0
    var fat: Double = 0
}

enum USDAError: LocalizedError {
    case noApiKey
    case noResults

    var errorDescription: String? {
        switch self {
        case .noApiKey: return "USDA API key not configured"
        case .noResults: return "No USDA match found"
        }
    }
}

struct USDAService {
    private static let endpoint = "https://api.nal.usda.gov/fdc/v1/foods/search"

    static func lookup(foodName: String) async throws -> USDANutrients {
        guard let apiKey = Bundle.main.infoDictionary?["USDA_API_KEY"] as? String,
              !apiKey.isEmpty else {
            throw USDAError.noApiKey
        }

        var components = URLComponents(string: endpoint)!
        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "query", value: foodName),
            URLQueryItem(name: "pageSize", value: "1"),
            URLQueryItem(name: "dataType", value: "SR Legacy,Foundation"),
        ]

        var request = URLRequest(url: components.url!)
        request.timeoutInterval = 15

        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        guard let foods = json?["foods"] as? [[String: Any]],
              let food = foods.first,
              let foodNutrients = food["foodNutrients"] as? [[String: Any]] else {
            throw USDAError.noResults
        }

        var nutrients = USDANutrients()

        for nutrient in foodNutrients {
            let name = nutrient["nutrientName"] as? String ?? ""
            let value = nutrient["value"] as? Double ?? 0

            if name.contains("Energy"), (nutrient["unitName"] as? String) == "KCAL" {
                nutrients.calories = value
            } else if name == "Protein" {
                nutrients.protein = value
            } else if name.contains("Carbohydrate") {
                nutrients.carbs = value
            } else if name.contains("Total lipid") {
                nutrients.fat = value
            }
        }

        guard nutrients.calories > 0 else {
            throw USDAError.noResults
        }

        return nutrients
    }
}
