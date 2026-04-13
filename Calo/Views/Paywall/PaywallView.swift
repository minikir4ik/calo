import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Hero
                    VStack(spacing: 12) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(.yellow)

                        Text("Unlock Calo Premium")
                            .font(.title.bold())

                        Text("Get unlimited scans and exclusive features")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)

                    // Benefits
                    VStack(alignment: .leading, spacing: 16) {
                        BenefitRow(icon: "infinity", title: "Unlimited Scans", subtitle: "No daily limits")
                        BenefitRow(icon: "chart.bar.fill", title: "Advanced Analytics", subtitle: "Detailed macro tracking")
                        BenefitRow(icon: "square.and.arrow.up", title: "Clean Sharing", subtitle: "No watermark on shared results")
                        BenefitRow(icon: "icloud.fill", title: "Cloud Sync", subtitle: "Access data across devices")
                        BenefitRow(icon: "star.fill", title: "Priority Support", subtitle: "Get help when you need it")
                    }
                    .padding(.horizontal)

                    // Pricing options
                    VStack(spacing: 12) {
                        // Weekly
                        PricingButton(
                            title: "Weekly",
                            price: "$4.99",
                            period: "per week",
                            isPopular: false
                        ) {
                            // TODO: RevenueCat Phase 3
                        }

                        // Lifetime
                        PricingButton(
                            title: "Lifetime",
                            price: "$29.99",
                            period: "one-time purchase",
                            isPopular: true
                        ) {
                            // TODO: RevenueCat Phase 3
                        }
                    }
                    .padding(.horizontal)

                    // Restore
                    Button("Restore Purchases") {
                        // TODO: RevenueCat Phase 3
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    // Legal
                    Text("Payment will be charged to your Apple ID account at confirmation of purchase. Subscription automatically renews unless it is canceled at least 24 hours before the end of the current period. Your account will be charged for renewal within 24 hours prior to the end of the current period. You can manage and cancel your subscriptions in your App Store account settings.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

struct BenefitRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(CaloTheme.coral)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct PricingButton: View {
    let title: String
    let price: String
    let period: String
    let isPopular: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(title)
                            .font(.headline)
                        if isPopular {
                            Text("BEST VALUE")
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(CaloTheme.coral)
                                .clipShape(Capsule())
                        }
                    }
                    Text(period)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(price)
                    .font(.title3.bold())
                    .foregroundStyle(CaloTheme.coral)
            }
            .padding()
            .background(isPopular ? CaloTheme.coral.opacity(0.08) : Color(.tertiarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isPopular ? CaloTheme.coral : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
