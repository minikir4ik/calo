import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var premiumManager: PremiumManager
    @Query private var allSettings: [UserSettings]
    @Query(sort: \FoodEntry.timestamp, order: .reverse) private var allEntries: [FoodEntry]

    var onSeeAllMeals: (() -> Void)?

    @State private var showScanSheet = false
    @State private var showPaywall = false
    @State private var showWaterSheet = false
    @State private var showAISuggestSheet = false
    @State private var ringAnimated = false
    @State private var insightExpanded = false

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
            name: settings?.firstName,
            calorieGoal: settings?.dailyCalorieGoal ?? 2000,
            proteinGoal: settings?.dailyProteinGoal ?? 150,
            carbsGoal: settings?.dailyCarbsGoal ?? 250,
            fatGoal: settings?.dailyFatGoal ?? 65
        )
    }

    private var streak: Int {
        DashboardIntelligenceService.getStreakCount(entries: Array(allEntries))
    }

    private var weeklyData: [DayCalories] {
        DashboardIntelligenceService.getWeeklyData(entries: Array(allEntries))
    }

    private var weeklyAvgCal: Double {
        let total = weeklyData.reduce(0.0) { $0 + $1.calories }
        let daysWithData = weeklyData.filter { $0.calories > 0 }.count
        return daysWithData > 0 ? total / Double(daysWithData) : 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    intelligenceCard
                    macroRingsGrid
                    quickActionsRow
                    todayMealsSection
                    streakAndWeekSection
                    Spacer().frame(height: 20)
                }
                .padding(.horizontal, 20)
            }
            .scrollIndicators(.hidden)
            .background(CaloTheme.background.ignoresSafeArea())
            .preferredColorScheme(.dark)
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showScanSheet) { ScanSheet() }
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .sheet(isPresented: $showWaterSheet) { WaterLogSheet() }
        .sheet(isPresented: $showAISuggestSheet) { AISuggestSheet() }
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
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                    .font(.caption)
                    .foregroundStyle(CaloTheme.subtleText)
            }

            Spacer()

            // Avatar with initial
            ZStack {
                Circle()
                    .fill(CaloTheme.coral.opacity(0.15))
                    .frame(width: 38, height: 38)
                Text(String((settings?.firstName ?? "C").prefix(1)).uppercased())
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(CaloTheme.coral)
            }
        }
        .padding(.top, 12)
    }

    // MARK: - Intelligence Card

    private var intelligenceCard: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                insightExpanded.toggle()
            }
        } label: {
            VStack(alignment: .leading, spacing: insightExpanded ? 16 : 0) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(insight.message)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer(minLength: 12)

                    Image(systemName: insight.icon)
                        .font(.system(size: 22))
                        .foregroundStyle(.white.opacity(0.8))
                }

                if insightExpanded {
                    Divider().background(.white.opacity(0.2))

                    HStack(spacing: 16) {
                        InsightMacro(label: "Cal", value: totalCal.wholeOrOne, goal: Int(calGoal), color: .white)
                        InsightMacro(label: "Protein", value: "\(totalProtein.wholeOrOne)g", goal: Int(proteinGoal), color: CaloTheme.accentGreen)
                        InsightMacro(label: "Carbs", value: "\(totalCarbs.wholeOrOne)g", goal: Int(carbsGoal), color: CaloTheme.accentBlue)
                        InsightMacro(label: "Fat", value: "\(totalFat.wholeOrOne)g", goal: Int(fatGoal), color: CaloTheme.accentPurple)
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [CaloTheme.coral, CaloTheme.coral.opacity(0.65)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .shadow(color: CaloTheme.coral.opacity(0.3), radius: 16, y: 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Macro Rings (2x2 Grid)

    private var macroRingsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            CircularProgressCard(
                progress: ringAnimated ? totalCal / max(calGoal, 1) : 0,
                color: CaloTheme.coral,
                current: totalCal.wholeOrOne,
                label: "Calories",
                subtitle: "/ \(Int(calGoal)) cal"
            )
            CircularProgressCard(
                progress: ringAnimated ? totalProtein / max(proteinGoal, 1) : 0,
                color: CaloTheme.accentGreen,
                current: "\(totalProtein.wholeOrOne)g",
                label: "Protein",
                subtitle: "/ \(Int(proteinGoal))g"
            )
            CircularProgressCard(
                progress: ringAnimated ? totalCarbs / max(carbsGoal, 1) : 0,
                color: CaloTheme.accentBlue,
                current: "\(totalCarbs.wholeOrOne)g",
                label: "Carbs",
                subtitle: "/ \(Int(carbsGoal))g"
            )
            CircularProgressCard(
                progress: ringAnimated ? totalFat / max(fatGoal, 1) : 0,
                color: CaloTheme.accentPurple,
                current: "\(totalFat.wholeOrOne)g",
                label: "Fat",
                subtitle: "/ \(Int(fatGoal))g"
            )
        }
    }

    // MARK: - Quick Actions

    private var quickActionsRow: some View {
        HStack(spacing: 12) {
            QuickActionButton(icon: "camera.viewfinder", label: "Scan Meal", badge: nil) {
                HapticManager.mediumImpact()
                if premiumManager.canScan() {
                    showScanSheet = true
                } else {
                    showPaywall = true
                }
            }

            QuickActionButton(icon: "sparkles", label: "What to eat?", badge: nil) {
                HapticManager.mediumImpact()
                showAISuggestSheet = true
            }

            let waterText = "\(settings?.waterGlassesToday ?? 0)/\(settings?.waterGoal ?? 8)"
            QuickActionButton(icon: "drop.fill", label: "Log Water", badge: waterText) {
                HapticManager.mediumImpact()
                showWaterSheet = true
            }
        }
    }

    // MARK: - Today's Meals

    private var todayMealsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today's Meals")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                if !todayEntries.isEmpty {
                    Button {
                        HapticManager.lightImpact()
                        onSeeAllMeals?()
                    } label: {
                        Text("See All")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(CaloTheme.coral)
                    }
                    .buttonStyle(.plain)
                }
            }

            if todayEntries.isEmpty {
                // Empty state with dashed border
                Button {
                    HapticManager.lightImpact()
                    if premiumManager.canScan() {
                        showScanSheet = true
                    } else {
                        showPaywall = true
                    }
                } label: {
                    VStack(spacing: 10) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 28))
                            .foregroundStyle(CaloTheme.coral.opacity(0.6))
                        Text("Scan your first meal")
                            .font(.caption)
                            .foregroundStyle(CaloTheme.subtleText)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(CaloTheme.cardBorder, style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(todayEntries.sorted(by: { $0.timestamp > $1.timestamp })) { entry in
                            DashboardMealCard(entry: entry)
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
                                    .font(.title3)
                                    .foregroundStyle(CaloTheme.coral)
                                Text("Add")
                                    .font(.caption2)
                                    .foregroundStyle(CaloTheme.subtleText)
                            }
                            .frame(width: 120, height: 140)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(CaloTheme.cardBorder, style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Streak + Weekly

    private var streakAndWeekSection: some View {
        VStack(spacing: 16) {
            // Streak
            HStack(spacing: 8) {
                if streak >= 1 {
                    Text("\u{1F525}")
                    Text("\(streak) day streak")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.orange)
                } else {
                    Text("Start your streak today")
                        .font(.subheadline)
                        .foregroundStyle(CaloTheme.subtleText)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(CaloTheme.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(CaloTheme.cardBorder, lineWidth: 0.5)
            )

            // Weekly dots
            HStack(spacing: 8) {
                ForEach(weeklyData) { day in
                    VStack(spacing: 6) {
                        Circle()
                            .fill(day.calories > 0 ? CaloTheme.coral : CaloTheme.cardBorder)
                            .frame(width: 10, height: 10)
                        Text(day.weekday)
                            .font(.system(size: 9))
                            .foregroundStyle(CaloTheme.subtleText)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(14)
            .background(CaloTheme.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(CaloTheme.cardBorder, lineWidth: 0.5)
            )

            // Weekly mini preview
            if weeklyAvgCal > 0 {
                VStack(alignment: .leading, spacing: 10) {
                    Text("This Week")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)

                    // Mini bar chart
                    HStack(alignment: .bottom, spacing: 6) {
                        ForEach(weeklyData) { day in
                            let maxCal = weeklyData.map(\.calories).max() ?? 1
                            let height = day.calories > 0 ? max(day.calories / maxCal * 50, 4) : 4

                            VStack(spacing: 4) {
                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                    .fill(day.calories > 0 ? CaloTheme.coral : CaloTheme.cardBorder)
                                    .frame(height: height)

                                Text(day.weekday)
                                    .font(.system(size: 8))
                                    .foregroundStyle(CaloTheme.subtleText)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(height: 70)

                    Text("\(weeklyAvgCal.wholeOrOne) cal daily avg")
                        .font(.caption)
                        .foregroundStyle(CaloTheme.subtleText)
                }
                .padding(16)
                .background(CaloTheme.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(CaloTheme.cardBorder, lineWidth: 0.5)
                )
            }
        }
    }
}

// MARK: - Subviews

private struct InsightMacro: View {
    let label: String
    let value: String
    let goal: Int
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }
}

private struct CircularProgressCard: View {
    let progress: Double
    let color: Color
    let current: String
    let label: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Background track
                Circle()
                    .stroke(color.opacity(0.15), lineWidth: 8)

                // Main progress (capped at 100%)
                Circle()
                    .trim(from: 0, to: min(progress, 1.0))
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.8, dampingFraction: 0.7), value: progress)

                // Overflow ring (past 100%)
                if progress > 1.0 {
                    Circle()
                        .trim(from: 0, to: min(progress - 1.0, 1.0))
                        .stroke(color.opacity(0.4), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.8, dampingFraction: 0.7), value: progress)
                }

                VStack(spacing: 2) {
                    Text(current)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(label)
                        .font(.system(size: 9))
                        .foregroundStyle(.gray)
                }
            }
            .frame(width: 80, height: 80)

            Text(subtitle)
                .font(.system(size: 10))
                .foregroundStyle(CaloTheme.subtleText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(CaloTheme.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(CaloTheme.cardBorder, lineWidth: 0.5)
        )
    }
}

private struct QuickActionButton: View {
    let icon: String
    let label: String
    let badge: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundStyle(CaloTheme.coral)

                    if let badge, !badge.isEmpty {
                        Text(badge)
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(CaloTheme.accentBlue)
                            .offset(x: 14, y: -6)
                    }
                }

                Text(label)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(white: 0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(CaloTheme.cardBorder, lineWidth: 0.5)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct DashboardMealCard: View {
    let entry: FoodEntry

    var body: some View {
        VStack(spacing: 8) {
            // Emoji
            if let emoji = entry.emoji, !emoji.isEmpty {
                Text(emoji)
                    .font(.system(size: 40))
            } else {
                Image(systemName: "fork.knife")
                    .font(.system(size: 28))
                    .foregroundStyle(CaloTheme.coral.opacity(0.5))
            }

            // Name
            Text(entry.foodName)
                .font(.caption.weight(.medium))
                .foregroundStyle(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            Spacer()

            // Calories
            Text("\(entry.calories.wholeOrOne) cal")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(CaloTheme.coral)
        }
        .frame(width: 120, height: 140)
        .padding(10)
        .background(CaloTheme.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(CaloTheme.cardBorder, lineWidth: 0.5)
        )
    }
}
