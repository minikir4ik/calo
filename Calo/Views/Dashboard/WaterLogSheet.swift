import SwiftUI
import SwiftData

struct WaterLogSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var allSettings: [UserSettings]

    private var settings: UserSettings? { allSettings.first }
    private var glasses: Int { settings?.waterGlassesToday ?? 0 }
    private var goal: Int { settings?.waterGoal ?? 8 }
    private var progress: Double { min(Double(glasses) / max(Double(goal), 1), 1.0) }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer().frame(height: 12)

                // Water icon
                ZStack {
                    Circle()
                        .stroke(CaloTheme.accentBlue.opacity(0.15), lineWidth: 8)
                        .frame(width: 140, height: 140)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(CaloTheme.accentBlue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 140, height: 140)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: glasses)

                    VStack(spacing: 4) {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(CaloTheme.accentBlue)
                        Text("\(glasses)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("of \(goal) glasses")
                            .font(.caption)
                            .foregroundStyle(CaloTheme.subtleText)
                    }
                }

                // +/- buttons
                HStack(spacing: 40) {
                    Button {
                        HapticManager.lightImpact()
                        settings?.removeWater()
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(CaloTheme.subtleText)
                    }
                    .buttonStyle(.plain)
                    .disabled(glasses <= 0)

                    Button {
                        HapticManager.mediumImpact()
                        settings?.addWater()
                        if (settings?.waterGlassesToday ?? 0) >= goal {
                            HapticManager.success()
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(CaloTheme.accentBlue)
                    }
                    .buttonStyle(.plain)
                }

                Text("Each glass = ~250 ml")
                    .font(.caption)
                    .foregroundStyle(CaloTheme.subtleText)

                Spacer()
            }
            .navigationTitle("Water")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(CaloTheme.coral)
                }
            }
        }
    }
}
