import SwiftUI
import SwiftData
import Charts

struct DayCalories: Identifiable {
    let id = UUID()
    let date: Date
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let weekday: String
}

struct WeeklyChartView: View {
    @Query(sort: \FoodEntry.timestamp) private var allEntries: [FoodEntry]
    @Query private var allSettings: [UserSettings]

    @State private var selectedDay: DayCalories?

    private var settings: UserSettings? { allSettings.first }

    private var weekData: [DayCalories] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        return (0..<7).reversed().map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let nextDay = calendar.date(byAdding: .day, value: 1, to: date)!
            let dayEntries = allEntries.filter { $0.timestamp >= date && $0.timestamp < nextDay }
            return DayCalories(
                date: date,
                calories: dayEntries.reduce(0.0) { $0 + $1.calories },
                protein: dayEntries.reduce(0.0) { $0 + $1.protein },
                carbs: dayEntries.reduce(0.0) { $0 + $1.carbs },
                fat: dayEntries.reduce(0.0) { $0 + $1.fat },
                weekday: date.shortWeekday
            )
        }
    }

    private var totalWeek: Double { weekData.reduce(0.0) { $0 + $1.calories } }
    private var avgDaily: Double { totalWeek / 7 }
    private var bestDay: DayCalories? { weekData.max(by: { $0.calories < $1.calories }) }
    private var daysWithData: Int { weekData.filter { $0.calories > 0 }.count }

    private var avgProtein: Double { weekData.reduce(0.0) { $0 + $1.protein } / 7 }
    private var avgCarbs: Double { weekData.reduce(0.0) { $0 + $1.carbs } / 7 }
    private var avgFat: Double { weekData.reduce(0.0) { $0 + $1.fat } / 7 }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if totalWeek == 0 {
                        // Empty state
                        VStack(spacing: 14) {
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: 44, weight: .thin))
                                .foregroundStyle(.white.opacity(0.12))
                            Text("Your first week starts\nwith one scan")
                                .font(.subheadline)
                                .foregroundStyle(CaloTheme.subtleText)
                                .multilineTextAlignment(.center)
                        }
                        .frame(height: 220)
                        .frame(maxWidth: .infinity)
                    } else {
                        // Summary card
                        HStack(spacing: 0) {
                            SummaryItem(value: totalWeek.wholeOrOne, label: "Total", unit: "cal")
                            SummaryItem(value: avgDaily.wholeOrOne, label: "Daily Avg", unit: "cal")
                            SummaryItem(value: "\(daysWithData)", label: "Active", unit: "days")
                        }
                        .padding(.vertical, 14)
                        .background(CaloTheme.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(CaloTheme.cardBorder, lineWidth: 0.5)
                        )
                        .padding(.horizontal, 20)
                    }

                    // Chart
                    Chart(weekData) { day in
                        BarMark(
                            x: .value("Day", day.weekday),
                            y: .value("Calories", day.calories)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: day.date == selectedDay?.date
                                    ? [CaloTheme.coral, CaloTheme.coral.opacity(0.8)]
                                    : [CaloTheme.coral.opacity(0.7), CaloTheme.coral.opacity(0.35)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

                        if let goal = settings?.dailyCalorieGoal {
                            RuleMark(y: .value("Goal", goal))
                                .foregroundStyle(.white.opacity(0.25))
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 4]))
                                .annotation(position: .trailing, alignment: .trailing) {
                                    Text("Goal")
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundStyle(.white.opacity(0.3))
                                }
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { _ in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                                .foregroundStyle(Color.white.opacity(0.06))
                            AxisValueLabel()
                                .foregroundStyle(CaloTheme.subtleText)
                                .font(.system(size: 10))
                        }
                    }
                    .chartXAxis {
                        AxisMarks { _ in
                            AxisValueLabel()
                                .foregroundStyle(CaloTheme.subtleText)
                                .font(.system(size: 10))
                        }
                    }
                    .chartOverlay { proxy in
                        GeometryReader { _ in
                            Color.clear
                                .contentShape(Rectangle())
                                .onTapGesture { location in
                                    if let weekday: String = proxy.value(atX: location.x) {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedDay = weekData.first { $0.weekday == weekday }
                                        }
                                    }
                                }
                        }
                    }
                    .frame(height: 200)
                    .padding(.horizontal, 20)

                    // Selected day detail
                    if let selected = selectedDay, selected.calories > 0 {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(selected.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)

                            HStack(spacing: 14) {
                                MiniMacro(label: "Cal", value: selected.calories.wholeOrOne, color: CaloTheme.coral)
                                MiniMacro(label: "P", value: "\(selected.protein.wholeOrOne)g", color: CaloTheme.accentGreen)
                                MiniMacro(label: "C", value: "\(selected.carbs.wholeOrOne)g", color: CaloTheme.accentBlue)
                                MiniMacro(label: "F", value: "\(selected.fat.wholeOrOne)g", color: CaloTheme.accentPurple)
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(CaloTheme.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(CaloTheme.cardBorder, lineWidth: 0.5)
                        )
                        .padding(.horizontal, 20)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    // Macro weekly averages
                    if totalWeek > 0 {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Weekly Averages")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)

                            MacroProgressBar(
                                label: "Protein",
                                value: avgProtein,
                                goal: Double(settings?.dailyProteinGoal ?? 150),
                                color: CaloTheme.accentGreen
                            )
                            MacroProgressBar(
                                label: "Carbs",
                                value: avgCarbs,
                                goal: Double(settings?.dailyCarbsGoal ?? 250),
                                color: CaloTheme.accentBlue
                            )
                            MacroProgressBar(
                                label: "Fat",
                                value: avgFat,
                                goal: Double(settings?.dailyFatGoal ?? 65),
                                color: CaloTheme.accentPurple
                            )
                        }
                        .padding(14)
                        .background(CaloTheme.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(CaloTheme.cardBorder, lineWidth: 0.5)
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
                .padding(.top, 8)
            }
            .background(CaloTheme.background)
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
            .preferredColorScheme(.dark)
        }
    }
}

// MARK: - Subviews

private struct SummaryItem: View {
    let value: String
    let label: String
    let unit: String

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(CaloTheme.subtleText)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct MiniMacro: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(CaloTheme.subtleText)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct MacroProgressBar: View {
    let label: String
    let value: Double
    let goal: Double
    let color: Color

    private var progress: Double { min(value / max(goal, 1), 1.0) }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(label)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.8))
                Spacer()
                Text("\(value.wholeOrOne)g / \(goal.wholeOrOne)g")
                    .font(.caption2)
                    .foregroundStyle(CaloTheme.subtleText)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(color.opacity(0.12))
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * progress)
                        .animation(.easeOut(duration: 0.5), value: progress)
                }
            }
            .frame(height: 5)
        }
    }
}
