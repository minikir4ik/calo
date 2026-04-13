import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allSettings: [UserSettings]

    var body: some View {
        TabView {
            ScanView()
                .tabItem { Label("Scan", systemImage: "camera.fill") }
            DailyLogView()
                .tabItem { Label("Log", systemImage: "list.bullet") }
            WeeklyChartView()
                .tabItem { Label("Charts", systemImage: "chart.bar.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(CaloTheme.coral)
        .onAppear { ensureSettings() }
    }

    private func ensureSettings() {
        if allSettings.isEmpty {
            modelContext.insert(UserSettings())
        }
    }
}
