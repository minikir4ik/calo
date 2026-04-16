import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allSettings: [UserSettings]
    @Query private var allOnboarding: [OnboardingData]

    private var hasCompletedOnboarding: Bool {
        allOnboarding.first?.hasCompletedOnboarding == true
    }

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                mainTabView
            } else {
                OnboardingFlowView {
                    // SwiftData @Query reactivity handles the transition
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { ensureData() }
    }

    private var mainTabView: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Home", systemImage: "house.fill") }
            DailyLogView()
                .tabItem { Label("Log", systemImage: "list.bullet") }
            WeeklyChartView()
                .tabItem { Label("Insights", systemImage: "chart.bar.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(CaloTheme.coral)
    }

    private func ensureData() {
        if allSettings.isEmpty {
            modelContext.insert(UserSettings())
        }
        if allOnboarding.isEmpty {
            modelContext.insert(OnboardingData())
        }
    }
}
