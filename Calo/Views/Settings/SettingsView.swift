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
                // Account
                Section {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(premiumManager.isPremium ? Color.yellow.opacity(0.15) : CaloTheme.cardBackground)
                                .frame(width: 36, height: 36)
                            Image(systemName: premiumManager.isPremium ? "crown.fill" : "person.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(premiumManager.isPremium ? .yellow : CaloTheme.subtleText)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            if premiumManager.isPremium {
                                HStack(spacing: 6) {
                                    Text("Premium Active")
                                        .font(.body.weight(.medium))
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(CaloTheme.accentGreen)
                                }
                            } else {
                                Text("Free Plan")
                                    .font(.body.weight(.medium))
                                Text("\(premiumManager.dailyScansRemaining)/\(PremiumManager.maxFreeScans) scans today")
                                    .font(.caption)
                                    .foregroundStyle(CaloTheme.subtleText)
                            }
                        }

                        Spacer()

                        if !premiumManager.isPremium {
                            Button("Upgrade") {
                                showPaywall = true
                            }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(CaloTheme.coral, in: Capsule())
                        }
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
                            .foregroundStyle(CaloTheme.subtleText)
                    }
                } header: {
                    Text("Account")
                }

                // Goals
                Section {
                    if let settings {
                        GoalRow(label: "Calories", value: Binding(
                            get: { settings.dailyCalorieGoal },
                            set: { settings.dailyCalorieGoal = $0 }
                        ), unit: "cal", color: CaloTheme.coral)

                        GoalRow(label: "Protein", value: Binding(
                            get: { settings.dailyProteinGoal },
                            set: { settings.dailyProteinGoal = $0 }
                        ), unit: "g", color: CaloTheme.accentGreen)

                        GoalRow(label: "Carbs", value: Binding(
                            get: { settings.dailyCarbsGoal },
                            set: { settings.dailyCarbsGoal = $0 }
                        ), unit: "g", color: CaloTheme.accentBlue)

                        GoalRow(label: "Fat", value: Binding(
                            get: { settings.dailyFatGoal },
                            set: { settings.dailyFatGoal = $0 }
                        ), unit: "g", color: CaloTheme.accentPurple)
                    }
                } header: {
                    Text("Goals")
                }

                // Support
                Section {
                    Link(destination: URL(string: "https://minilabs.dev/calo/privacy")!) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }
                    Link(destination: URL(string: "https://minilabs.dev/calo/terms")!) {
                        Label("Terms of Service", systemImage: "doc.text")
                    }
                    Link(destination: URL(string: "mailto:support@minilabs.dev")!) {
                        Label("Contact Us", systemImage: "envelope")
                    }
                } header: {
                    Text("Support")
                }

                // About
                Section {
                    LabeledContent("Version") {
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                            .foregroundStyle(CaloTheme.subtleText)
                    }
                    LabeledContent("Build") {
                        Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                            .foregroundStyle(CaloTheme.subtleText)
                    }
                } footer: {
                    Text("Calo v1.0 · Made by Mini Labs")
                        .font(.caption2)
                        .foregroundStyle(CaloTheme.subtleText)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 12)
                }
            }
            .navigationTitle("Settings")
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { hideKeyboard() }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
        .onTapGesture { hideKeyboard() }
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
                .foregroundStyle(CaloTheme.subtleText)
                .frame(width: 30)
        }
    }
}
