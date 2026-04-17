import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allSettings: [UserSettings]
    @Query private var allOnboarding: [OnboardingData]

    @State private var selectedTab: Tab = .home
    @State private var showScanSheet = false

    @EnvironmentObject private var premiumManager: PremiumManager

    private var hasCompletedOnboarding: Bool {
        allOnboarding.first?.hasCompletedOnboarding == true
    }

    enum Tab: Int {
        case home, log, scan, charts, settings
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
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .onAppear { ensureData() }
    }

    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            DashboardView(onSeeAllMeals: { selectedTab = .log })
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(Tab.home)

            DailyLogView()
                .tabItem { Label("Log", systemImage: "list.bullet") }
                .tag(Tab.log)

            // Placeholder for center scan tab — the actual action opens a sheet
            Color.clear
                .tabItem { Label("Scan", systemImage: "camera.fill") }
                .tag(Tab.scan)

            WeeklyChartView()
                .tabItem { Label("Charts", systemImage: "chart.bar.fill") }
                .tag(Tab.charts)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(Tab.settings)
        }
        .tint(CaloTheme.coral)
        .onChange(of: selectedTab) { _, newTab in
            if newTab == .scan {
                HapticManager.mediumImpact()
                // Revert tab selection, open sheet instead
                selectedTab = .home
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if premiumManager.canScan() {
                        showScanSheet = true
                    }
                }
            } else {
                HapticManager.lightImpact()
            }
        }
        .sheet(isPresented: $showScanSheet) {
            ScanSheet()
        }
    }

    private func ensureData() {
        if allSettings.isEmpty {
            modelContext.insert(UserSettings())
        }
        if allOnboarding.isEmpty {
            modelContext.insert(OnboardingData())
        }
        LocalFoodDatabase.preloadIfNeeded(context: modelContext)
    }
}
