import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss

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
                        FeatureRow(text: "Unlimited daily scans")
                        FeatureRow(text: "Advanced macro analytics")
                        FeatureRow(text: "Clean sharing (no watermark)")
                        FeatureRow(text: "Cloud sync across devices")
                        FeatureRow(text: "Priority support")
                    }
                    .padding(.horizontal, 24)

                    // Pricing buttons
                    VStack(spacing: 12) {
                        Button {
                            // TODO: RevenueCat
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Weekly")
                                        .font(.headline)
                                    Text("per week")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.7))
                                }
                                Spacer()
                                Text("$4.99")
                                    .font(.title3.bold())
                            }
                            .foregroundStyle(.white)
                            .padding(16)
                            .frame(maxWidth: .infinity)
                            .background(CaloTheme.coral, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .shadow(color: CaloTheme.coral.opacity(0.4), radius: 8, y: 4)
                        }
                        .buttonStyle(.plain)

                        Button {
                            // TODO: RevenueCat
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 6) {
                                        Text("Lifetime")
                                            .font(.headline)
                                        Text("BEST VALUE")
                                            .font(.caption2.bold())
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(.white.opacity(0.2), in: Capsule())
                                    }
                                    Text("one-time purchase")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.7))
                                }
                                Spacer()
                                Text("$29.99")
                                    .font(.title3.bold())
                            }
                            .foregroundStyle(.white)
                            .padding(16)
                            .frame(maxWidth: .infinity)
                            .background(CaloTheme.coral, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .shadow(color: CaloTheme.coral.opacity(0.4), radius: 8, y: 4)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)

                    // Restore
                    Button("Restore Purchases") {
                        // TODO: RevenueCat
                    }
                    .font(.subheadline)
                    .foregroundStyle(CaloTheme.subtleText)

                    // Terms
                    Text("Payment will be charged to your Apple ID account at confirmation of purchase. Subscription automatically renews unless it is canceled at least 24 hours before the end of the current period.")
                        .font(.caption2)
                        .foregroundStyle(Color(white: 0.35))
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
                            .foregroundStyle(CaloTheme.subtleText)
                    }
                }
            }
        }
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
