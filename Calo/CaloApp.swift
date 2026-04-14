import SwiftUI
import SwiftData
import RevenueCat

@main
struct CaloApp: App {
    let container: ModelContainer
    @StateObject private var premiumManager = PremiumManager()

    init() {
        do {
            let schema = Schema([FoodEntry.self, UserSettings.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("SwiftData container failed to initialize: \(error.localizedDescription)")
        }

        if let apiKey = Bundle.main.infoDictionary?["RevenueCatAPIKey"] as? String, !apiKey.isEmpty {
            Purchases.logLevel = .debug
            Purchases.configure(withAPIKey: apiKey)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(premiumManager)
        }
        .modelContainer(container)
    }
}
