import Foundation
import SwiftData

enum LocalFoodDatabase {

    // MARK: - Lookup

    @MainActor
    static func lookup(query: String, context: ModelContext) -> CachedFood? {
        let normalized = query.lowercased().trimmingCharacters(in: .whitespaces)
        guard !normalized.isEmpty else { return nil }

        let descriptor = FetchDescriptor<CachedFood>()
        guard let allCached = try? context.fetch(descriptor) else { return nil }

        // Exact match first
        if let exact = allCached.first(where: { $0.foodName == normalized }) {
            // Check if cache is fresh (30 days)
            if exact.cachedAt.timeIntervalSinceNow > -30 * 24 * 3600 {
                exact.lookupCount += 1
                return exact
            }
        }

        // Fuzzy: check if query contains or is contained by a cached name
        if let fuzzy = allCached.first(where: {
            $0.foodName.contains(normalized) || normalized.contains($0.foodName)
        }) {
            if fuzzy.cachedAt.timeIntervalSinceNow > -30 * 24 * 3600 {
                fuzzy.lookupCount += 1
                return fuzzy
            }
        }

        return nil
    }

    // MARK: - Cache Result

    @MainActor
    static func cache(name: String, calories: Double, protein: Double, carbs: Double, fat: Double, grams: Double, emoji: String, verified: Bool, context: ModelContext) {
        let normalized = name.lowercased().trimmingCharacters(in: .whitespaces)

        let descriptor = FetchDescriptor<CachedFood>()
        if let allCached = try? context.fetch(descriptor),
           let existing = allCached.first(where: { $0.foodName == normalized }) {
            // Update existing
            existing.calories = calories
            existing.protein = protein
            existing.carbs = carbs
            existing.fat = fat
            existing.grams = grams
            existing.emoji = emoji
            existing.verified = verified
            existing.cachedAt = .now
        } else {
            // Create new
            let cached = CachedFood(
                foodName: normalized,
                calories: calories,
                protein: protein,
                carbs: carbs,
                fat: fat,
                grams: grams,
                emoji: emoji,
                verified: verified
            )
            context.insert(cached)
        }
    }

    // MARK: - Preload Common Foods

    @MainActor
    static func preloadIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<CachedFood>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count < 10 else { return } // Already seeded

        for food in commonFoods {
            let cached = CachedFood(
                foodName: food.name,
                calories: food.cal,
                protein: food.protein,
                carbs: food.carbs,
                fat: food.fat,
                grams: food.grams,
                emoji: food.emoji,
                verified: true,
                cachedAt: .now
            )
            context.insert(cached)
        }

        try? context.save()
    }

    // MARK: - Common Foods (USDA-accurate values)

    private static let commonFoods: [(name: String, cal: Double, protein: Double, carbs: Double, fat: Double, grams: Double, emoji: String)] = [
        ("apple", 95, 0.5, 25, 0.3, 182, "🍎"),
        ("banana", 105, 1.3, 27, 0.4, 118, "🍌"),
        ("chicken breast grilled", 165, 31, 0, 3.6, 100, "🍗"),
        ("white rice cooked", 206, 4.3, 45, 0.4, 158, "🍚"),
        ("pasta cooked", 220, 8, 43, 1.3, 140, "🍝"),
        ("scrambled eggs", 182, 12, 2, 14, 122, "🍳"),
        ("oatmeal", 158, 6, 27, 3.2, 234, "🥣"),
        ("whole wheat bread slice", 79, 3.6, 15, 1.1, 30, "🍞"),
        ("milk", 149, 8, 12, 8, 244, "🥛"),
        ("greek yogurt", 100, 17, 6, 0.7, 170, "🫙"),
        ("salmon fillet", 208, 20, 0, 13, 100, "🐟"),
        ("broccoli", 55, 3.7, 11, 0.6, 156, "🥦"),
        ("pizza slice", 285, 12, 36, 10, 107, "🍕"),
        ("cheeseburger", 535, 28, 40, 29, 227, "🍔"),
        ("black coffee", 2, 0.3, 0, 0, 237, "☕"),
        ("orange juice", 112, 1.7, 26, 0.5, 248, "🍊"),
        ("avocado", 120, 1.5, 6, 11, 68, "🥑"),
        ("almonds", 164, 6, 6, 14, 28, "🥜"),
        ("cheddar cheese", 113, 7, 0.4, 9, 28, "🧀"),
        ("ribeye steak", 291, 24, 0, 21, 100, "🥩"),
        ("sweet potato", 103, 2.3, 24, 0.1, 130, "🍠"),
        ("spinach", 7, 0.9, 1.1, 0.1, 30, "🥬"),
        ("lentils cooked", 230, 18, 40, 0.8, 198, "🫘"),
        ("quinoa cooked", 222, 8, 39, 3.6, 185, "🌾"),
        ("tofu", 76, 8, 2, 4.2, 100, "⬜"),
        ("coca cola", 139, 0, 35, 0, 330, "🥤"),
        ("orange", 62, 1.2, 15, 0.2, 131, "🍊"),
        ("strawberries", 49, 1, 12, 0.5, 152, "🍓"),
        ("tuna canned", 128, 28, 0, 0.6, 100, "🐟"),
        ("peanut butter", 188, 8, 7, 16, 32, "🥜"),
        ("brown rice cooked", 216, 5, 45, 1.8, 202, "🍚"),
        ("blueberries", 84, 1.1, 21, 0.5, 148, "🫐"),
        ("watermelon", 46, 0.9, 11, 0.2, 152, "🍉"),
        ("mango", 135, 1, 35, 0.6, 165, "🥭"),
        ("corn", 132, 5, 29, 1.8, 164, "🌽"),
        ("carrot", 25, 0.6, 6, 0.1, 61, "🥕"),
        ("cucumber", 16, 0.7, 3.6, 0.1, 104, "🥒"),
        ("tomato", 22, 1.1, 4.8, 0.2, 123, "🍅"),
        ("french fries", 365, 4, 48, 17, 117, "🍟"),
        ("hot dog", 290, 10, 2, 26, 98, "🌭"),
        ("bagel", 270, 10, 53, 1.5, 105, "🥯"),
        ("croissant", 231, 5, 26, 12, 67, "🥐"),
        ("chocolate bar", 210, 3, 24, 12, 40, "🍫"),
        ("ice cream", 137, 2.3, 16, 7, 66, "🍦"),
        ("beer", 153, 1.3, 13, 0, 330, "🍺"),
        ("wine", 125, 0.1, 4, 0, 150, "🍷"),
        ("protein shake", 150, 25, 8, 3, 350, "🥤"),
        ("granola bar", 193, 4, 29, 7, 42, "🍫"),
        ("caesar salad", 290, 7, 18, 22, 200, "🥗"),
        ("sushi roll", 280, 9, 44, 6, 200, "🍱"),
    ]
}
