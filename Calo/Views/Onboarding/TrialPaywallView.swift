import SwiftUI
import RevenueCat

struct TrialPaywallView: View {
    @EnvironmentObject private var premiumManager: PremiumManager
    let onContinue: () -> Void

    @State private var offerings: Offerings?
    @State private var isPurchasing = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer().frame(height: 20)

                // Crown icon
                ZStack {
                    Circle()
                        .fill(CaloTheme.coral.opacity(0.12))
                        .frame(width: 80, height: 80)
                    Image(systemName: "crown.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(CaloTheme.coral)
                }

                Spacer().frame(height: 16)

                Text("Try Calo Premium\nfree for 3 days")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Spacer().frame(height: 28)

                // Feature list
                VStack(alignment: .leading, spacing: 14) {
                    TrialFeatureRow(text: "30 daily AI-powered scans")
                    TrialFeatureRow(text: "Advanced macro analytics")
                    TrialFeatureRow(text: "Clean sharing without watermarks")
                    TrialFeatureRow(text: "Cloud sync across all devices")
                    TrialFeatureRow(text: "Priority support")
                }
                .padding(.horizontal, 32)

                Spacer().frame(height: 28)

                // Timeline
                HStack(spacing: 0) {
                    TimelineStep(day: "Today", label: "Free", isActive: true)
                    TimelineLine()
                    TimelineStep(day: "Day 2", label: "Reminder", isActive: false)
                    TimelineLine()
                    TimelineStep(day: "Day 3", label: "Trial ends", isActive: false)
                }
                .padding(.horizontal, 32)

                Spacer().frame(height: 28)

                // Price card
                if let offering = offerings?.current,
                   let weekly = offering.package(identifier: "$rc_weekly") ?? offering.weekly {
                    VStack(spacing: 4) {
                        Text("After trial: \(weekly.storeProduct.localizedPriceString)/week")
                            .font(.subheadline)
                            .foregroundStyle(CaloTheme.subtleText)
                    }

                    Spacer().frame(height: 16)

                    // Start trial button
                    Button {
                        HapticManager.mediumImpact()
                        purchasePackage(weekly)
                    } label: {
                        HStack {
                            if isPurchasing {
                                ProgressView().tint(.white)
                            } else {
                                Text("Start Free Trial")
                                    .font(.headline)
                            }
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(CaloTheme.coral, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: CaloTheme.coral.opacity(0.4), radius: 16, y: 6)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 24)
                    .disabled(isPurchasing)
                } else {
                    VStack(spacing: 4) {
                        Text("After trial: $3.99/week")
                            .font(.subheadline)
                            .foregroundStyle(CaloTheme.subtleText)
                    }

                    Spacer().frame(height: 16)

                    // Fallback button (no RevenueCat offerings loaded)
                    Button {
                        HapticManager.mediumImpact()
                        onContinue()
                    } label: {
                        Text("Start Free Trial")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(CaloTheme.coral, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: CaloTheme.coral.opacity(0.4), radius: 16, y: 6)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 24)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red.opacity(0.9))
                        .padding(.top, 8)
                }

                Spacer().frame(height: 16)

                // Skip
                Button {
                    HapticManager.lightImpact()
                    onContinue()
                } label: {
                    Text("Continue with Free")
                        .font(.subheadline)
                        .foregroundStyle(CaloTheme.subtleText)
                }
                .buttonStyle(.plain)

                Spacer().frame(height: 8)

                Text("3 free scans per day")
                    .font(.caption2)
                    .foregroundStyle(Color(white: 0.3))

                Spacer().frame(height: 40)
            }
        }
        .scrollIndicators(.hidden)
        .task {
            await loadOfferings()
        }
    }

    private func loadOfferings() async {
        do {
            offerings = try await Purchases.shared.offerings()
        } catch {
            // Silently fail — fallback UI shows static price
        }
    }

    private func purchasePackage(_ package: Package) {
        guard !isPurchasing else { return }
        isPurchasing = true
        errorMessage = nil

        Task {
            do {
                let result = try await Purchases.shared.purchase(package: package)
                if !result.userCancelled {
                    await premiumManager.checkPremiumStatus()
                    HapticManager.success()
                }
                onContinue()
            } catch {
                errorMessage = error.localizedDescription
            }
            isPurchasing = false
        }
    }
}

private struct TrialFeatureRow: View {
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark")
                .font(.caption.weight(.bold))
                .foregroundStyle(CaloTheme.coral)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white)
        }
    }
}

private struct TimelineStep: View {
    let day: String
    let label: String
    let isActive: Bool

    var body: some View {
        VStack(spacing: 6) {
            Circle()
                .fill(isActive ? CaloTheme.coral : CaloTheme.cardBackground)
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .stroke(isActive ? CaloTheme.coral : CaloTheme.cardBorder, lineWidth: 1)
                )
            Text(day)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(isActive ? .white : CaloTheme.subtleText)
            Text(label)
                .font(.caption2)
                .foregroundStyle(CaloTheme.subtleText)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct TimelineLine: View {
    var body: some View {
        Rectangle()
            .fill(CaloTheme.cardBorder)
            .frame(height: 1)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 32)
    }
}
