import SwiftUI
import SwiftData
import RevenueCat

struct SettingsView: View {
    @Query private var allSettings: [UserSettings]
    @EnvironmentObject private var premiumManager: PremiumManager
    @State private var showPaywall = false
    @State private var isRestoring = false
    @State private var restoreMessage: String?

    private var settings: UserSettings? { allSettings.first }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Image(systemName: premiumManager.isPremium ? "crown.fill" : "person.fill")
                            .foregroundStyle(premiumManager.isPremium ? .yellow : .secondary)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(premiumManager.isPremium ? "Premium" : "Free Plan")
                                .font(.body.weight(.medium))
                            if !premiumManager.isPremium {
                                Text("\(premiumManager.dailyScansRemaining)/\(PremiumManager.maxFreeScans) scans today")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    if !premiumManager.isPremium {
                        Button("Upgrade to Premium") {
                            showPaywall = true
                        }
                        .foregroundStyle(CaloTheme.coral)
                    }

                    Button {
                        restorePurchases()
                    } label: {
                        HStack {
                            Text("Restore Purchases")
                            Spacer()
                            if isRestoring {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isRestoring)

                    if let restoreMessage {
                        Text(restoreMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Account").foregroundStyle(CaloTheme.coral)
                }

                Section {
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
                } header: {
                    Text("Daily Goals").foregroundStyle(CaloTheme.coral)
                }

                Section {
                    LabeledContent("Version") {
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                    }
                    LabeledContent("Build") {
                        Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                    }
                    Link("Privacy Policy", destination: URL(string: "https://minilabs.dev/calo/privacy")!)
                    Link("Terms of Service", destination: URL(string: "https://minilabs.dev/calo/terms")!)
                } header: {
                    Text("About").foregroundStyle(CaloTheme.coral)
                }
            }
            .navigationTitle("Settings")
            .preferredColorScheme(.dark)
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    private func restorePurchases() {
        isRestoring = true
        restoreMessage = nil
        Task {
            do {
                _ = try await Purchases.shared.restorePurchases()
                await premiumManager.checkPremiumStatus()
                restoreMessage = premiumManager.isPremium ? "Premium restored!" : "No active purchases found."
            } catch {
                restoreMessage = error.localizedDescription
            }
            isRestoring = false
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
                .onAppear { text = "\(value)" }
                .onChange(of: text) { _, newValue in
                    if let num = Int(newValue) {
                        value = num
                    }
                }
            Text(unit)
                .foregroundStyle(.secondary)
                .frame(width: 30)
        }
    }
}
