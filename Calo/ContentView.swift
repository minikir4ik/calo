import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allSettings: [UserSettings]

    var body: some View {
        TabView {
            ScanView()
                .tabItem { Label("Scan", systemImage: "viewfinder") }
            DailyLogView()
                .tabItem { Label("Log", systemImage: "list.bullet") }
            WeeklyChartView()
                .tabItem { Label("Insights", systemImage: "chart.bar.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(CaloTheme.coral)
        .preferredColorScheme(.dark)
        .onAppear { ensureSettings() }
    }

    private func ensureSettings() {
        if allSettings.isEmpty {
            modelContext.insert(UserSettings())
        }
    }
}
