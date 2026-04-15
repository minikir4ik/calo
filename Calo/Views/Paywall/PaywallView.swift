import SwiftUI
import RevenueCat

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var premiumManager: PremiumManager

    @State private var offerings: Offerings?
    @State private var isPurchasing = false
    @State private var errorMessage: String?
    @State private var selectedPackageID: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Title
                    VStack(spacing: 10) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(CaloTheme.coral)

                        Text("Calo Premium")
                            .font(.title.bold())
                            .foregroundStyle(.white)

                        Text("Unlimited scans and exclusive features")
                            .font(.subheadline)
                            .foregroundStyle(CaloTheme.subtleText)
                    }
                    .padding(.top, 32)

                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        FeatureRow(text: "30 daily scans")
                        FeatureRow(text: "Advanced macro analytics")
                        FeatureRow(text: "Clean sharing (no watermark)")
                        FeatureRow(text: "Cloud sync across devices")
                        FeatureRow(text: "Priority support")
                    }
                    .padding(.horizontal, 24)

                    // Pricing buttons
                    if let offering = offerings?.current {
                        VStack(spacing: 12) {
                            // Weekly
                            if let weekly = offering.package(identifier: "$rc_weekly") ?? offering.weekly {
                                PackageButton(
                                    title: "Weekly",
                                    subtitle: "3-day free trial",
                                    price: weekly.storeProduct.localizedPriceString,
                                    badge: nil,
                                    isSelected: selectedPackageID == weekly.identifier,
                                    isPurchasing: isPurchasing
                                ) {
                                    purchasePackage(weekly)
                                }
                            }

                            // Annual
                            if let annual = offering.package(identifier: "$rc_annual") ?? offering.annual {
                                PackageButton(
                                    title: "Annual",
                                    subtitle: "7-day free trial",
                                    price: annual.storeProduct.localizedPriceString,
                                    badge: "MOST POPULAR",
                                    isSelected: selectedPackageID == annual.identifier,
                                    isPurchasing: isPurchasing
                                ) {
                                    purchasePackage(annual)
                                }
                            }

                            // Lifetime
                            if let lifetime = offering.package(identifier: "$rc_lifetime") ?? offering.lifetime {
                                PackageButton(
                                    title: "Lifetime",
                                    subtitle: "One-time purchase",
                                    price: lifetime.storeProduct.localizedPriceString,
                                    badge: "BEST VALUE",
                                    isSelected: selectedPackageID == lifetime.identifier,
                                    isPurchasing: isPurchasing
                                ) {
                                    purchasePackage(lifetime)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    } else {
                        ProgressView()
                            .tint(.white)
                            .padding(.vertical, 20)
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal, 24)
                    }

                    // Restore
                    Button {
                        restorePurchases()
                    } label: {
                        if isPurchasing {
                            ProgressView().tint(CaloTheme.subtleText)
                        } else {
                            Text("Restore Purchases")
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(CaloTheme.subtleText)
                    .disabled(isPurchasing)

                    // Terms
                    VStack(spacing: 8) {
                        Text("Payment will be charged to your Apple ID account at confirmation of purchase. Subscription automatically renews unless it is canceled at least 24 hours before the end of the current period. Your account will be charged for renewal within 24 hours prior to the end of the current period. You can manage and cancel your subscriptions by going to your account settings on the App Store after purchase.")
                            .font(.caption2)
                            .foregroundStyle(Color(white: 0.35))
                            .multilineTextAlignment(.center)

                        HStack(spacing: 16) {
                            Link("Privacy Policy", destination: URL(string: "https://minilabs.dev/calo/privacy")!)
                            Link("Terms of Service", destination: URL(string: "https://minilabs.dev/calo/terms")!)
                        }
                        .font(.caption2)
                        .foregroundStyle(CaloTheme.subtleText)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(CaloTheme.subtleText)
                    }
                }
            }
            .task {
                await loadOfferings()
            }
        }
    }

    private func loadOfferings() async {
        do {
            offerings = try await Purchases.shared.offerings()
        } catch {
            errorMessage = "Could not load offerings."
        }
    }

    private func purchasePackage(_ package: Package) {
        guard !isPurchasing else { return }
        isPurchasing = true
        selectedPackageID = package.identifier
        errorMessage = nil

        Task {
            do {
                let result = try await Purchases.shared.purchase(package: package)
                if !result.userCancelled {
                    await premiumManager.checkPremiumStatus()
                    dismiss()
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isPurchasing = false
            selectedPackageID = nil
        }
    }

    private func restorePurchases() {
        guard !isPurchasing else { return }
        isPurchasing = true
        errorMessage = nil

        Task {
            do {
                _ = try await Purchases.shared.restorePurchases()
                await premiumManager.checkPremiumStatus()
                if premiumManager.isPremium {
                    dismiss()
                } else {
                    errorMessage = "No active purchases found."
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isPurchasing = false
        }
    }
}

// MARK: - Subviews

private struct PackageButton: View {
    let title: String
    let subtitle: String
    let price: String
    let badge: String?
    let isSelected: Bool
    let isPurchasing: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.headline)
                        if let badge {
                            Text(badge)
                                .font(.caption2.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.white.opacity(0.2), in: Capsule())
                        }
                    }
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                Spacer()
                if isSelected && isPurchasing {
                    ProgressView().tint(.white)
                } else {
                    Text(price)
                        .font(.title3.bold())
                }
            }
            .foregroundStyle(.white)
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(CaloTheme.coral, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: CaloTheme.coral.opacity(0.4), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(isPurchasing)
    }
}

struct FeatureRow: View {
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
