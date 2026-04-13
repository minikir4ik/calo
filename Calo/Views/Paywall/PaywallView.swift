import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Hero
                    VStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [CaloTheme.coral, CaloTheme.coral.opacity(0.6)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                            Image(systemName: "crown.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(.white)
                        }

                        Text("Unlock Calo Premium")
                            .font(.title2.bold())
                            .foregroundStyle(.white)

                        Text("Get unlimited scans and exclusive features")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 24)

                    // Benefits
                    VStack(spacing: 0) {
                        BenefitRow(icon: "infinity", title: "Unlimited Scans", subtitle: "No daily limits")
                        Rectangle().fill(CaloTheme.separator).frame(height: 0.5).padding(.leading, 52)
                        BenefitRow(icon: "chart.bar.fill", title: "Advanced Analytics", subtitle: "Detailed macro tracking")
                        Rectangle().fill(CaloTheme.separator).frame(height: 0.5).padding(.leading, 52)
                        BenefitRow(icon: "square.and.arrow.up", title: "Clean Sharing", subtitle: "No watermark on shared results")
                        Rectangle().fill(CaloTheme.separator).frame(height: 0.5).padding(.leading, 52)
                        BenefitRow(icon: "icloud.fill", title: "Cloud Sync", subtitle: "Access data across devices")
                        Rectangle().fill(CaloTheme.separator).frame(height: 0.5).padding(.leading, 52)
                        BenefitRow(icon: "star.fill", title: "Priority Support", subtitle: "Get help when you need it")
                    }
                    .padding(.vertical, 4)
                    .background(CaloTheme.surfacePrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal, 20)

                    // Pricing
                    VStack(spacing: 12) {
                        // Weekly
                        Button {
                            // TODO: RevenueCat Phase 3
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Weekly")
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                    Text("per week")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("$4.99")
                                    .font(.title3.bold())
                                    .foregroundStyle(.white)
                            }
                            .padding(16)
                            .background(CaloTheme.surfaceSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)

                        // Lifetime
                        Button {
                            // TODO: RevenueCat Phase 3
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 6) {
                                        Text("Lifetime")
                                            .font(.headline)
                                            .foregroundStyle(.white)
                                        Text("BEST VALUE")
                                            .font(.caption2.bold())
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(.white.opacity(0.2))
                                            .clipShape(Capsule())
                                    }
                                    Text("one-time purchase")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.7))
                                }
                                Spacer()
                                Text("$29.99")
                                    .font(.title3.bold())
                                    .foregroundStyle(.white)
                            }
                            .padding(16)
                            .background(
                                LinearGradient(
                                    colors: [CaloTheme.coral, CaloTheme.coral.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)

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
            .background(
                LinearGradient(
                    colors: [Color(white: 0.06), .black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
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
            Image(systemName: "checkmark")
                .font(.caption.weight(.bold))
                .foregroundStyle(CaloTheme.coral)
                .frame(width: 24, height: 24)
                .background(CaloTheme.coral.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
