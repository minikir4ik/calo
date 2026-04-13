import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var allSettings: [UserSettings]
    @State private var showPaywall = false

    private var settings: UserSettings? { allSettings.first }

    var body: some View {
        NavigationStack {
            List {
                // Account
                Section("Account") {
                    HStack {
                        Image(systemName: settings?.isPremium == true ? "crown.fill" : "person.fill")
                            .foregroundStyle(settings?.isPremium == true ? .yellow : CaloTheme.subtleText)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(settings?.isPremium == true ? "Premium" : "Free Plan")
                                .font(.body.weight(.medium))
                            if let settings, !settings.isPremium {
                                Text("\(settings.dailyScanCount)/\(UserSettings.maxFreeScans) scans today")
                                    .font(.caption)
                                    .foregroundStyle(CaloTheme.subtleText)
                            }
                        }

                        Spacer()

                        if settings?.isPremium != true {
                            Button("Upgrade") { showPaywall = true }
                                .font(.subheadline.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(CaloTheme.coral)
                                .clipShape(Capsule())
                        }
                    }
                    .listRowBackground(CaloTheme.cardBackground)
                }

                // Goals
                Section("Daily Goals") {
                    if let settings {
                        GoalRow(label: "Calories", value: Binding(
                            get: { settings.dailyCalorieGoal },
                            set: { settings.dailyCalorieGoal = $0 }
                        ), unit: "cal", color: CaloTheme.coral)

                        GoalRow(label: "Protein", value: Binding(
                            get: { settings.dailyProteinGoal },
                            set: { settings.dailyProteinGoal = $0 }
                        ), unit: "g", color: .blue)

                        GoalRow(label: "Carbs", value: Binding(
                            get: { settings.dailyCarbsGoal },
                            set: { settings.dailyCarbsGoal = $0 }
                        ), unit: "g", color: .orange)

                        GoalRow(label: "Fat", value: Binding(
                            get: { settings.dailyFatGoal },
                            set: { settings.dailyFatGoal = $0 }
                        ), unit: "g", color: .purple)
                    }
                }

                // Appearance
                Section("Appearance") {
                    HStack {
                        Text("Theme")
                        Spacer()
                        Text("Dark")
                            .foregroundStyle(CaloTheme.subtleText)
                    }
                    .listRowBackground(CaloTheme.cardBackground)
                }

                // About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                            .foregroundStyle(CaloTheme.subtleText)
                    }
                    HStack {
                        Text("Build")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                            .foregroundStyle(CaloTheme.subtleText)
                    }
                    Link(destination: URL(string: "https://minilabs.dev/calo/privacy")!) {
                        HStack {
                            Text("Privacy Policy")
                                .foregroundStyle(.white)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(CaloTheme.subtleText)
                        }
                    }
                    Link(destination: URL(string: "https://minilabs.dev/calo/terms")!) {
                        HStack {
                            Text("Terms of Service")
                                .foregroundStyle(.white)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(CaloTheme.subtleText)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }
}

struct GoalRow: View {
    let label: String
    @Binding var value: Int
    let unit: String
    let color: Color

    @State private var text: String = ""

    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
            Spacer()
            TextField("", text: $text)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
                .foregroundStyle(CaloTheme.subtleText)
                .onAppear { text = "\(value)" }
                .onChange(of: text) { _, newValue in
                    if let num = Int(newValue) {
                        value = num
                    }
                }
            Text(unit)
                .foregroundStyle(CaloTheme.subtleText)
                .frame(width: 30)
        }
        .listRowBackground(CaloTheme.cardBackground)
    }
}
