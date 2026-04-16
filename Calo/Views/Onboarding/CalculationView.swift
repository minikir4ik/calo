import SwiftUI

struct CalculationView: View {
    let calories: Int
    let protein: Int
    let carbs: Int
    let fat: Int
    let onContinue: () -> Void

    @State private var isCalculating = true
    @State private var showResults = false
    @State private var shimmerPhase: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            if isCalculating {
                // Calculating animation
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .stroke(CaloTheme.cardBorder, lineWidth: 4)
                            .frame(width: 80, height: 80)
                        Circle()
                            .trim(from: 0, to: 0.3)
                            .stroke(CaloTheme.coral, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(shimmerPhase))
                    }

                    Text("Calculating your\npersonalized plan...")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                }
                .transition(.opacity)
            } else {
                // Results
                VStack(spacing: 28) {
                    Text("Your daily targets")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)

                    // Main calorie number
                    VStack(spacing: 4) {
                        Text("\(calories)")
                            .font(.system(size: 64, weight: .bold, design: .rounded))
                            .foregroundStyle(CaloTheme.coral)
                        Text("calories per day")
                            .font(.subheadline)
                            .foregroundStyle(CaloTheme.subtleText)
                    }
                    .scaleEffect(showResults ? 1 : 0.5)
                    .opacity(showResults ? 1 : 0)

                    // Macro breakdown
                    HStack(spacing: 16) {
                        MacroTarget(label: "Protein", value: "\(protein)g", color: CaloTheme.accentGreen)
                        MacroTarget(label: "Carbs", value: "\(carbs)g", color: CaloTheme.accentBlue)
                        MacroTarget(label: "Fat", value: "\(fat)g", color: CaloTheme.accentPurple)
                    }
                    .padding(.horizontal, 24)
                    .scaleEffect(showResults ? 1 : 0.8)
                    .opacity(showResults ? 1 : 0)

                    Text("Based on your body composition, activity level, and goals")
                        .font(.caption)
                        .foregroundStyle(CaloTheme.subtleText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .opacity(showResults ? 1 : 0)
                }
                .transition(.opacity)
            }

            Spacer()

            if !isCalculating {
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
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            Spacer().frame(height: 50)
        }
        .onAppear {
            withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                shimmerPhase = 360
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                HapticManager.success()
                withAnimation(.easeInOut(duration: 0.4)) {
                    isCalculating = false
                }
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.15)) {
                    showResults = true
                }
            }
        }
    }
}

private struct MacroTarget: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: 48, height: 48)
                .overlay(
                    Text(value)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(color)
                )

            Text(label)
                .font(.caption)
                .foregroundStyle(CaloTheme.subtleText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(CaloTheme.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(CaloTheme.cardBorder, lineWidth: 0.5)
        )
    }
}
