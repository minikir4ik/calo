import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var allSettings: [UserSettings]
    @AppStorage("appearance") private var appearance: String = "system"
    @State private var showPaywall = false

    private var settings: UserSettings? { allSettings.first }

    var body: some View {
        NavigationStack {
            List {
                // Account
                Section("Account") {
                    HStack {
                        Label(
                            settings?.isPremium == true ? "Premium" : "Free Plan",
                            systemImage: settings?.isPremium == true ? "crown.fill" : "person.fill"
                        )
                        .foregroundStyle(settings?.isPremium == true ? .yellow : .primary)

                        Spacer()

                        if settings?.isPremium != true {
                            Button("Upgrade") { showPaywall = true }
                                .font(.subheadline.bold())
                                .foregroundStyle(CaloTheme.coral)
                        }
                    }

                    if let settings, !settings.isPremium {
                        HStack {
                            Text("Scans today")
                            Spacer()
                            Text("\(settings.dailyScanCount)/\(UserSettings.maxFreeScans)")
                                .foregroundStyle(.secondary)
                        }
                    }
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
                    Picker("Theme", selection: $appearance) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                }

                // Legal
                Section("Legal") {
                    Link("Privacy Policy", destination: URL(string: "https://minilabs.dev/calo/privacy")!)
                    Link("Terms of Service", destination: URL(string: "https://minilabs.dev/calo/terms")!)
                }

                // About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Build")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .preferredColorScheme(colorScheme)
        }
    }

    private var colorScheme: ColorScheme? {
        switch appearance {
        case "light": return .light
        case "dark": return .dark
        default: return nil
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
                .foregroundStyle(.secondary)
                .onAppear { text = "\(value)" }
                .onChange(of: text) { _, newValue in
                    if let num = Int(newValue) {
                        value = num
                    }
                }
            Text(unit)
                .foregroundStyle(.tertiary)
                .frame(width: 30)
        }
    }
}
