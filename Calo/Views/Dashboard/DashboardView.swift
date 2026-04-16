import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var premiumManager: PremiumManager
    @Query private var allSettings: [UserSettings]
    @Query(sort: \FoodEntry.timestamp, order: .reverse) private var allEntries: [FoodEntry]

    @State private var showScanSheet = false
    @State private var showPaywall = false
    @State private var showWaterSheet = false
    @State private var showAISuggestSheet = false
    @State private var ringAnimated = false

    private var settings: UserSettings? { allSettings.first }

    private var todayEntries: [FoodEntry] {
        let start = Calendar.current.startOfDay(for: .now)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        return allEntries.filter { $0.timestamp >= start && $0.timestamp < end }
    }

    private var totalCal: Double { todayEntries.reduce(0) { $0 + $1.calories } }
    private var totalProtein: Double { todayEntries.reduce(0) { $0 + $1.protein } }
    private var totalCarbs: Double { todayEntries.reduce(0) { $0 + $1.carbs } }
    private var totalFat: Double { todayEntries.reduce(0) { $0 + $1.fat } }

    private var calGoal: Double { Double(settings?.dailyCalorieGoal ?? 2000) }
    private var proteinGoal: Double { Double(settings?.dailyProteinGoal ?? 150) }
    private var carbsGoal: Double { Double(settings?.dailyCarbsGoal ?? 250) }
    private var fatGoal: Double { Double(settings?.dailyFatGoal ?? 65) }

    private var insight: DashboardIntelligenceService.Insight {
        DashboardIntelligenceService.getDailyInsight(
            entries: todayEntries,
            calorieGoal: settings?.dailyCalorieGoal ?? 2000,
            proteinGoal: settings?.dailyProteinGoal ?? 150,
            carbsGoal: settings?.dailyCarbsGoal ?? 250,
            fatGoal: settings?.dailyFatGoal ?? 65
        )
    }

    private var streak: Int {
        DashboardIntelligenceService.getStreakCount(entries: Array(allEntries))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerSection

                    // Daily Intelligence Card
                    intelligenceCard

                    // Macro Progress Rings
                    macroRingsSection

                    // Quick Actions
                    quickActionsRow

                    // Today's Meals
                    todayMealsSection

                    // Streak badge
                    if streak > 1 {
                        streakBadge
                    }

                    Spacer().frame(height: 20)
                }
                .padding(.horizontal, 20)
            }
            .scrollIndicators(.hidden)
            .background(CaloTheme.background)
            .preferredColorScheme(.dark)
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showScanSheet) {
            ScanSheet()
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .sheet(isPresented: $showWaterSheet) {
            WaterLogSheet()
        }
        .sheet(isPresented: $showAISuggestSheet) {
            AISuggestSheet()
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.3)) {
                ringAnimated = true
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(DashboardIntelligenceService.greeting(name: settings?.firstName))
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                    .font(.subheadline)
                    .foregroundStyle(CaloTheme.subtleText)
            }

            Spacer()

            if !premiumManager.isPremium {
                Text("\(premiumManager.dailyScansRemaining) scans")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.white.opacity(0.08), in: Capsule())
            }
        }
        .padding(.top, 12)
    }

    // MARK: - Intelligence Card

    private var intelligenceCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(insight.title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)

            Text(insight.subtitle)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [CaloTheme.coral, CaloTheme.coral.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .shadow(color: CaloTheme.coral.opacity(0.3), radius: 16, y: 6)
    }

    // MARK: - Macro Rings

    private var macroRingsSection: some View {
        VStack(spacing: 16) {
            // Main calorie ring
            ZStack {
                ProgressRing(
                    progress: ringAnimated ? min(totalCal / max(calGoal, 1), 1.0) : 0,
                    lineWidth: 10,
                    color: CaloTheme.coral,
                    size: 140
                )

                VStack(spacing: 2) {
                    Text(totalCal.wholeOrOne)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("/ \(Int(calGoal)) cal")
                        .font(.caption)
                        .foregroundStyle(CaloTheme.subtleText)
                }
            }

            // Macro rings row
            HStack(spacing: 16) {
                MacroRingCard(
                    label: "Protein",
                    current: totalProtein,
                    goal: proteinGoal,
                    unit: "g",
                    color: CaloTheme.accentGreen,
                    animated: ringAnimated
                )
                MacroRingCard(
                    label: "Carbs",
                    current: totalCarbs,
                    goal: carbsGoal,
                    unit: "g",
                    color: CaloTheme.accentBlue,
                    animated: ringAnimated
                )
                MacroRingCard(
                    label: "Fat",
                    current: totalFat,
                    goal: fatGoal,
                    unit: "g",
                    color: CaloTheme.accentPurple,
                    animated: ringAnimated
                )
            }
        }
        .padding(20)
        .background(CaloTheme.cardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(CaloTheme.cardBorder, lineWidth: 0.5)
        )
    }

    // MARK: - Quick Actions

    private var quickActionsRow: some View {
        HStack(spacing: 12) {
            QuickActionButton(icon: "camera.fill", label: "Scan Meal") {
                HapticManager.mediumImpact()
                if premiumManager.canScan() {
                    showScanSheet = true
                } else {
                    showPaywall = true
                }
            }

            QuickActionButton(icon: "sparkles", label: "AI Suggest") {
                HapticManager.mediumImpact()
                showAISuggestSheet = true
            }

            QuickActionButton(icon: "drop.fill", label: "Log Water") {
                HapticManager.mediumImpact()
                showWaterSheet = true
            }
        }
    }

    // MARK: - Today's Meals

    private var todayMealsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's meals")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)

            if todayEntries.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "fork.knife")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.15))
                        Text("Your meals will appear here")
                            .font(.caption)
                            .foregroundStyle(CaloTheme.subtleText)
                    }
                    .padding(.vertical, 20)
                    Spacer()
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(todayEntries.sorted(by: { $0.timestamp > $1.timestamp })) { entry in
                            MealCard(entry: entry)
                        }

                        // Add card
                        Button {
                            HapticManager.lightImpact()
                            if premiumManager.canScan() {
                                showScanSheet = true
                            } else {
                                showPaywall = true
                            }
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: "plus")
                                    .font(.title2)
                                    .foregroundStyle(CaloTheme.coral)
                                Text("Scan")
                                    .font(.caption2)
                                    .foregroundStyle(CaloTheme.subtleText)
                            }
                            .frame(width: 100, height: 110)
                            .background(CaloTheme.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(CaloTheme.cardBorder, lineWidth: 0.5)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Streak Badge

    private var streakBadge: some View {
        HStack(spacing: 6) {
            Text("\u{1F525}")
            Text("\(streak) day streak")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(CaloTheme.cardBackground, in: Capsule())
        .overlay(Capsule().stroke(CaloTheme.cardBorder, lineWidth: 0.5))
    }
}

// MARK: - Subviews

private struct ProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat
    let color: Color
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: lineWidth)
                .frame(width: size, height: size)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.8, dampingFraction: 0.7), value: progress)
        }
    }
}

private struct MacroRingCard: View {
    let label: String
    let current: Double
    let goal: Double
    let unit: String
    let color: Color
    let animated: Bool

    private var progress: Double {
        animated ? min(current / max(goal, 1), 1.0) : 0
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                ProgressRing(progress: progress, lineWidth: 5, color: color, size: 56)
                Text(current.wholeOrOne)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            Text(label)
                .font(.caption2)
                .foregroundStyle(CaloTheme.subtleText)

            Text("\(Int(goal))\(unit)")
                .font(.caption2)
                .foregroundStyle(Color(white: 0.3))
        }
        .frame(maxWidth: .infinity)
    }
}

private struct QuickActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(CaloTheme.coral)
                Text(label)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(CaloTheme.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(CaloTheme.cardBorder, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct MealCard: View {
    let entry: FoodEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Icon or image
            ZStack {
                if let imageData = entry.imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                } else if !entry.emoji.isEmpty {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(CaloTheme.coral.opacity(0.1))
                        .frame(width: 100, height: 56)
                        .overlay(
                            Text(entry.emoji).font(.system(size: 28))
                        )
                } else {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(CaloTheme.coral.opacity(0.1))
                        .frame(width: 100, height: 56)
                        .overlay(
                            Image(systemName: "fork.knife")
                                .foregroundStyle(CaloTheme.coral.opacity(0.5))
                        )
                }
            }

            Text(entry.foodName)
                .font(.caption.weight(.medium))
                .foregroundStyle(.white)
                .lineLimit(1)

            Text("\(entry.calories.wholeOrOne) cal")
                .font(.caption2)
                .foregroundStyle(CaloTheme.subtleText)
        }
        .frame(width: 100)
        .padding(8)
        .background(CaloTheme.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(CaloTheme.cardBorder, lineWidth: 0.5)
        )
    }
}
