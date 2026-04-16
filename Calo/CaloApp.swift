import SwiftUI
import SwiftData
import RevenueCat
import Sentry

@main
struct CaloApp: App {
    let container: ModelContainer
    @StateObject private var premiumManager: PremiumManager

    init() {
        do {
            let schema = Schema([FoodEntry.self, UserSettings.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("SwiftData container failed to initialize: \(error.localizedDescription)")
        }

        // Sentry
        if let dsn = Bundle.main.infoDictionary?["SentryDSN"] as? String, !dsn.isEmpty {
            SentrySDK.start { options in
                options.dsn = dsn
                options.tracesSampleRate = 0.2
                options.enableAutoSessionTracking = true
            }
            #if DEBUG
            SentrySDK.capture(message: "Calo launched successfully")
            #endif
        }

        // RevenueCat
        if let apiKey = Bundle.main.infoDictionary?["RevenueCatAPIKey"] as? String, !apiKey.isEmpty {
            Purchases.logLevel = .debug
            Purchases.configure(withAPIKey: apiKey)
        }

        _premiumManager = StateObject(wrappedValue: PremiumManager())
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(premiumManager)
        }
        .modelContainer(container)
    }
}
