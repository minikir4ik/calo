import SwiftUI
import SwiftData
import RevenueCat

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allSettings: [UserSettings]
    @Query private var allOnboarding: [OnboardingData]
    @EnvironmentObject private var premiumManager: PremiumManager
    @State private var showPaywall = false
    @State private var isRestoring = false
    @State private var showRestoreAlert = false
    @State private var restoreMessage = ""

    private var settings: UserSettings? { allSettings.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Account Section
                    VStack(alignment: .leading, spacing: 0) {
                        Text("ACCOUNT")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(CaloTheme.subtleText)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 8)

                        VStack(spacing: 0) {
                            // Premium status
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
                                                .foregroundStyle(.white)
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.caption)
                                                .foregroundStyle(CaloTheme.accentGreen)
                                        }
                                    } else {
                                        Text("Free Plan")
                                            .font(.body.weight(.medium))
                                            .foregroundStyle(.white)
                                        Text("\(premiumManager.dailyScansRemaining)/\(PremiumManager.maxFreeScans) scans today")
                                            .font(.caption)
                                            .foregroundStyle(CaloTheme.subtleText)
                                    }
                                }

                                Spacer()
                            }
                            .padding(16)

                            if !premiumManager.isPremium {
                                Divider().background(CaloTheme.cardBorder)

                                Button {
                                    HapticManager.mediumImpact()
                                    showPaywall = true
                                } label: {
                                    HStack {
                                        Image(systemName: "crown.fill")
                                            .foregroundStyle(CaloTheme.coral)
                                        Text("Upgrade to Premium")
                                            .foregroundStyle(.white)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundStyle(CaloTheme.subtleText)
                                    }
                                    .padding(16)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }

                            Divider().background(CaloTheme.cardBorder)

                            Button {
                                restorePurchases()
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                        .foregroundStyle(CaloTheme.coral)
                                    Text("Restore Purchases")
                                        .foregroundStyle(.white)
                                    Spacer()
                                    if isRestoring {
                                        ProgressView()
                                            .tint(CaloTheme.subtleText)
                                    } else {
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundStyle(CaloTheme.subtleText)
                                    }
                                }
                                .padding(16)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .disabled(isRestoring)
                        }
                        .background(CaloTheme.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(CaloTheme.cardBorder, lineWidth: 0.5)
                        )
                        .padding(.horizontal, 16)
                    }

                    // Goals Section
                    if let settings {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("DAILY GOALS")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(CaloTheme.subtleText)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 8)

                            VStack(spacing: 0) {
                                GoalRow(label: "Calories", value: Binding(
                                    get: { settings.dailyCalorieGoal },
                                    set: { settings.dailyCalorieGoal = $0 }
                                ), unit: "cal", color: CaloTheme.coral)

                                Divider().background(CaloTheme.cardBorder).padding(.leading, 16)

                                GoalRow(label: "Protein", value: Binding(
                                    get: { settings.dailyProteinGoal },
                                    set: { settings.dailyProteinGoal = $0 }
                                ), unit: "g", color: CaloTheme.accentGreen)

                                Divider().background(CaloTheme.cardBorder).padding(.leading, 16)

                                GoalRow(label: "Carbs", value: Binding(
                                    get: { settings.dailyCarbsGoal },
                                    set: { settings.dailyCarbsGoal = $0 }
                                ), unit: "g", color: CaloTheme.accentBlue)

                                Divider().background(CaloTheme.cardBorder).padding(.leading, 16)

                                GoalRow(label: "Fat", value: Binding(
                                    get: { settings.dailyFatGoal },
                                    set: { settings.dailyFatGoal = $0 }
                                ), unit: "g", color: CaloTheme.accentPurple)
                            }
                            .background(CaloTheme.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(CaloTheme.cardBorder, lineWidth: 0.5)
                            )
                            .padding(.horizontal, 16)
                        }
                    }

                    // Support Section
                    VStack(alignment: .leading, spacing: 0) {
                        Text("SUPPORT")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(CaloTheme.subtleText)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 8)

                        VStack(spacing: 0) {
                            Button {
                                if let url = URL(string: "https://minilabs.dev/calo/privacy") {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "hand.raised")
                                        .foregroundStyle(CaloTheme.coral)
                                    Text("Privacy Policy")
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .font(.caption)
                                        .foregroundStyle(CaloTheme.subtleText)
                                }
                                .padding(16)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            Divider().background(CaloTheme.cardBorder).padding(.leading, 16)

                            Button {
                                if let url = URL(string: "https://minilabs.dev/calo/terms") {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "doc.text")
                                        .foregroundStyle(CaloTheme.coral)
                                    Text("Terms of Service")
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .font(.caption)
                                        .foregroundStyle(CaloTheme.subtleText)
                                }
                                .padding(16)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            Divider().background(CaloTheme.cardBorder).padding(.leading, 16)

                            Button {
                                if let url = URL(string: "mailto:support@minilabs.dev") {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "envelope")
                                        .foregroundStyle(CaloTheme.coral)
                                    Text("Contact Us")
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .font(.caption)
                                        .foregroundStyle(CaloTheme.subtleText)
                                }
                                .padding(16)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                        .background(CaloTheme.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(CaloTheme.cardBorder, lineWidth: 0.5)
                        )
                        .padding(.horizontal, 16)
                    }

                    // About Section
                    VStack(alignment: .leading, spacing: 0) {
                        Text("ABOUT")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(CaloTheme.subtleText)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 8)

                        VStack(spacing: 0) {
                            HStack {
                                Text("Version")
                                    .foregroundStyle(.white)
                                Spacer()
                                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                                    .foregroundStyle(CaloTheme.subtleText)
                            }
                            .padding(16)

                            Divider().background(CaloTheme.cardBorder).padding(.leading, 16)

                            HStack {
                                Text("Build")
                                    .foregroundStyle(.white)
                                Spacer()
                                Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                                    .foregroundStyle(CaloTheme.subtleText)
                            }
                            .padding(16)
                        }
                        .background(CaloTheme.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(CaloTheme.cardBorder, lineWidth: 0.5)
                        )
                        .padding(.horizontal, 16)
                    }

                    #if DEBUG
                    // Debug Section
                    VStack(alignment: .leading, spacing: 0) {
                        Text("DEBUG")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(CaloTheme.subtleText)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 8)

                        VStack(spacing: 0) {
                            Button {
                                if let onboarding = allOnboarding.first {
                                    onboarding.hasCompletedOnboarding = false
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.counterclockwise")
                                        .foregroundStyle(.yellow)
                                    Text("Reset Onboarding")
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(CaloTheme.subtleText)
                                }
                                .padding(16)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                        .background(CaloTheme.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(CaloTheme.cardBorder, lineWidth: 0.5)
                        )
                        .padding(.horizontal, 16)
                    }
                    #endif

                    Text("Calo v1.0 · Made by Mini Labs")
                        .font(.caption2)
                        .foregroundStyle(CaloTheme.subtleText)
                        .padding(.top, 4)
                        .padding(.bottom, 20)
                }
                .padding(.top, 8)
            }
            .scrollIndicators(.hidden)
            .background(CaloTheme.background.ignoresSafeArea())
            .navigationTitle("Settings")
            .preferredColorScheme(.dark)
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .alert("Restore Purchases", isPresented: $showRestoreAlert) {
                Button("OK") {}
            } message: {
                Text(restoreMessage)
            }
        }
    }

    private func restorePurchases() {
        isRestoring = true

        Task {
            do {
                _ = try await Purchases.shared.restorePurchases()
                await premiumManager.checkPremiumStatus()
                restoreMessage = premiumManager.isPremium ? "Premium restored!" : "No active purchases found."
            } catch {
                restoreMessage = "Restore failed: \(error.localizedDescription)"
            }
            isRestoring = false
            showRestoreAlert = true
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
                .foregroundStyle(.white)
            Spacer()
            TextField("", text: $text)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(.white)
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
        .padding(16)
    }
}
