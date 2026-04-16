import SwiftUI

struct ActivityLevelView: View {
    @Binding var selectedLevel: String
    let onContinue: () -> Void

    private let levels: [(id: String, title: String, description: String, icon: String)] = [
        ("sedentary", "Sedentary", "Desk job, little exercise", "figure.seated.seatbelt"),
        ("light", "Light", "Walks, 1-2 workouts/week", "figure.walk"),
        ("moderate", "Moderate", "3-5 workouts/week", "figure.run"),
        ("very_active", "Very Active", "6+ workouts/week", "figure.highintensity.intervaltraining"),
        ("athlete", "Athlete", "Daily training, competitive", "medal.fill")
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 20)

            Text("How active are you?")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)

            Spacer().frame(height: 32)

            VStack(spacing: 10) {
                ForEach(levels, id: \.id) { level in
                    ActivityCard(
                        title: level.title,
                        description: level.description,
                        icon: level.icon,
                        isSelected: selectedLevel == level.id
                    ) {
                        HapticManager.selection()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedLevel = level.id
                        }
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            if !selectedLevel.isEmpty {
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
        .animation(.easeInOut(duration: 0.35), value: selectedLevel)
    }
}

private struct ActivityCard: View {
    let title: String
    let description: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(isSelected ? CaloTheme.coral : .white.opacity(0.5))
                    .frame(width: 38, height: 38)
                    .background(
                        Circle()
                            .fill(isSelected ? CaloTheme.coral.opacity(0.15) : CaloTheme.cardBackground)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(CaloTheme.subtleText)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(CaloTheme.coral)
                }
            }
            .padding(14)
            .background(CaloTheme.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? CaloTheme.coral : CaloTheme.cardBorder, lineWidth: isSelected ? 1.5 : 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}
