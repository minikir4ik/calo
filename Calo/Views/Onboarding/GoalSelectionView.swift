import SwiftUI

struct GoalSelectionView: View {
    @Binding var selectedGoal: String
    let onContinue: () -> Void

    private let goals: [(id: String, title: String, subtitle: String, icon: String)] = [
        ("lose_fat", "Lose fat", "Burn fat, keep muscle", "arrow.down.circle.fill"),
        ("build_muscle", "Build muscle", "Gain strength and size", "figure.strengthtraining.traditional"),
        ("maintain", "Stay healthy", "Maintain your physique", "heart.fill"),
        ("performance", "Peak performance", "Fuel your training", "bolt.fill")
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 20)

            Text("What's your goal?")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)

            Spacer().frame(height: 32)

            VStack(spacing: 12) {
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
                    .font(.system(size: 24))
                    .foregroundStyle(isSelected ? CaloTheme.coral : .white.opacity(0.5))
                    .frame(width: 44, height: 44)
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
            .padding(16)
            .background(CaloTheme.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? CaloTheme.coral : CaloTheme.cardBorder, lineWidth: isSelected ? 1.5 : 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}
