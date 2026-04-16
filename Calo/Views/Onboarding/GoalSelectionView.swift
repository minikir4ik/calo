import SwiftUI

struct GoalSelectionView: View {
    @Binding var selectedGoal: String
    let onContinue: () -> Void

    private let goals: [(id: String, title: String, subtitle: String, icon: String)] = [
        ("lose_fat", "Lose Fat", "Shed body fat while preserving muscle", "flame.fill"),
        ("build_muscle", "Build Muscle", "Gain lean mass and strength", "dumbbell.fill"),
        ("eat_healthier", "Eat Healthier", "Improve nutrition and energy", "leaf.fill"),
        ("maintain", "Stay Fit", "Maintain your current shape", "heart.fill"),
        ("performance", "Boost Performance", "Fuel athletic performance", "bolt.fill")
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 20)

            Text("What\u{2019}s your goal?")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)

            Spacer().frame(height: 28)

            VStack(spacing: 10) {
                ForEach(goals, id: \.id) { goal in
                    GoalCard(
                        title: goal.title,
                        subtitle: goal.subtitle,
                        icon: goal.icon,
                        isSelected: selectedGoal == goal.id
                    ) {
                        HapticManager.selection()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedGoal = goal.id
                        }
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            if !selectedGoal.isEmpty {
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
        .animation(.easeInOut(duration: 0.35), value: selectedGoal)
        .background(Color.black.ignoresSafeArea())
    }
}

private struct GoalCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? CaloTheme.coral : .white.opacity(0.5))
                    .frame(width: 42, height: 42)
                    .background(
                        Circle()
                            .fill(isSelected ? CaloTheme.coral.opacity(0.15) : CaloTheme.cardBackground)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(CaloTheme.subtleText)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(CaloTheme.coral)
                        .font(.title3)
                }
            }
            .padding(14)
            .background(CaloTheme.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? CaloTheme.coral : CaloTheme.cardBorder, lineWidth: isSelected ? 1.5 : 0.5)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
