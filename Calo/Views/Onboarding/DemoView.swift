import SwiftUI

struct DemoView: View {
    let onContinue: () -> Void

    @State private var animationPhase: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 20)

            Text("Scan anything,\ntrack effortlessly")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Spacer().frame(height: 40)

            // Animated demo
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(CaloTheme.cardBackground)
                    .frame(height: 280)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(CaloTheme.cardBorder, lineWidth: 0.5)
                    )

                VStack(spacing: 20) {
                    // Phone scanning animation
                    ZStack {
                        // Food plate
                        Circle()
                            .fill(Color(white: 0.15))
                            .frame(width: 100, height: 100)
                        Image(systemName: "fork.knife")
                            .font(.system(size: 36))
                            .foregroundStyle(.white.opacity(0.3))

                        // Scan line
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [CaloTheme.coral.opacity(0), CaloTheme.coral, CaloTheme.coral.opacity(0)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 120, height: 2)
                            .offset(y: animationPhase == 1 ? 50 : -50)

                        // Viewfinder corners
                        Image(systemName: "viewfinder")
                            .font(.system(size: 100, weight: .ultraLight))
                            .foregroundStyle(CaloTheme.coral.opacity(0.5))
                    }

                    // Result badges
                    if animationPhase >= 2 {
                        HStack(spacing: 8) {
                            ResultBadge(text: "425 cal", color: CaloTheme.coral)
                            ResultBadge(text: "32g protein", color: CaloTheme.accentGreen)
                            ResultBadge(text: "USDA verified", color: CaloTheme.accentBlue)
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer().frame(height: 36)

            // Feature bullets
            VStack(alignment: .leading, spacing: 16) {
                FeatureBullet(icon: "sparkles", text: "AI identifies your meal instantly")
                FeatureBullet(icon: "checkmark.seal.fill", text: "USDA-verified macro data")
                FeatureBullet(icon: "chart.line.uptrend.xyaxis", text: "Tracks all your daily goals")
            }
            .padding(.horizontal, 32)

            Spacer()

            Button {
                HapticManager.mediumImpact()
                onContinue()
            } label: {
                Text("Continue")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(CaloTheme.coral, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)

            Spacer().frame(height: 50)
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                animationPhase = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    animationPhase = 2
                }
            }
        }
    }
}

private struct ResultBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12), in: Capsule())
    }
}

private struct FeatureBullet: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(CaloTheme.coral)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white)
        }
    }
}
