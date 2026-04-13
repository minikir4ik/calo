import SwiftUI
import SwiftData

@main
struct CaloApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [FoodEntry.self, UserSettings.self])
    }
}
