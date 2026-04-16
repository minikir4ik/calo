import SwiftUI

struct PaceView: View {
    @Binding var weeklyRate: Double
    let currentWeight: Double
    let targetWeight: Double
    let onContinue: () -> Void

    private let paceOptions: [(rate: Double, label: String)] = [
        (0.25, "Slow"),
        (0.5, "Balanced"),
        (0.75, "Fast"),
        (1.0, "Aggressive")
    ]

    private var selectedIndex: Int {
        paceOptions.firstIndex(where: { $0.rate == weeklyRate }) ?? 1
    }

    private var weeks: Int {
        TDEECalculator.weeksToGoal(currentWeight: currentWeight, targetWeight: targetWeight, weeklyRate: weeklyRate)
    }

    private var estimatedDate: String {
        guard weeks > 0 else { return "Already there!" }
        let date = Calendar.current.date(byAdding: .weekOfYear, value: weeks, to: .now) ?? .now
        return date.formatted(.dateTime.month(.wide).year())
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 20)

            Text("How fast do you want\nto see results?")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Spacer().frame(height: 40)

            // Pace cards
            VStack(spacing: 10) {
                ForEach(Array(paceOptions.enumerated()), id: \.offset) { index, pace in
                    PaceCard(
                        label: pace.label,
                        rate: pace.rate,
                        isSelected: weeklyRate == pace.rate
                    ) {
                        HapticManager.selection()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            weeklyRate = pace.rate
                        }
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer().frame(height: 28)

            // Estimate
            VStack(spacing: 8) {
                Text("Estimated timeline")
                    .font(.caption)
                    .foregroundStyle(CaloTheme.subtleText)

                Text(estimatedDate)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)

                if weeks > 0 {
                    Text("\(weeks) weeks at \(String(format: "%.2f", weeklyRate)) kg/week")
                        .font(.caption)
                        .foregroundStyle(CaloTheme.subtleText)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(CaloTheme.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(CaloTheme.cardBorder, lineWidth: 0.5)
            )
            .padding(.horizontal, 24)

            // Warning for aggressive
            if weeklyRate >= 1.0 {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                    Text("Fast results may be harder to sustain")
                        .font(.caption)
                        .foregroundStyle(.yellow.opacity(0.8))
                }
                .padding(.top, 12)
                .transition(.opacity)
            }

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
        .animation(.easeInOut(duration: 0.35), value: weeklyRate)
        .background(Color.black.ignoresSafeArea())
    }
}

private struct PaceCard: View {
    let label: String
    let rate: Double
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("\(String(format: "%.2f", rate)) kg/week")
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
