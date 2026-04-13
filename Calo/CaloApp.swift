import SwiftUI
import SwiftData

@main
struct CaloApp: App {
    let container: ModelContainer

    init() {
        do {
            let schema = Schema([FoodEntry.self, UserSettings.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("SwiftData container failed to initialize: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
