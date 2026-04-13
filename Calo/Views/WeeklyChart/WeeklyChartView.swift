import SwiftUI
import SwiftData
import Charts

struct DayCalories: Identifiable {
    let id = UUID()
    let date: Date
    let calories: Double
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
            let total = dayEntries.reduce(0.0) { $0 + $1.calories }
            return DayCalories(date: date, calories: total, weekday: date.shortWeekday)
        }
    }

    private var totalWeek: Double { weekData.reduce(0.0) { $0 + $1.calories } }
    private var avgDaily: Double { totalWeek / 7 }
    private var highestDay: Double { weekData.map(\.calories).max() ?? 0 }
    private var daysOnTarget: Int {
        guard let goal = settings?.dailyCalorieGoal else { return 0 }
        return weekData.filter { $0.calories <= Double(goal) && $0.calories > 0 }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Chart
                    VStack(alignment: .leading, spacing: 12) {
                        Chart(weekData) { day in
                            BarMark(
                                x: .value("Day", day.weekday),
                                y: .value("Calories", day.calories)
                            )
                            .foregroundStyle(
                                day.date == selectedDay?.date
                                    ? CaloTheme.coral
                                    : CaloTheme.coral.opacity(0.6)
                            )
                            .cornerRadius(4)

                            if let goal = settings?.dailyCalorieGoal {
                                RuleMark(y: .value("Goal", goal))
                                    .foregroundStyle(.white.opacity(0.3))
                                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                                    .annotation(position: .trailing, alignment: .leading) {
                                        Text("Goal")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading) { value in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                    .foregroundStyle(Color.white.opacity(0.08))
                                AxisValueLabel()
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .chartXAxis {
                            AxisMarks { value in
                                AxisValueLabel()
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .chartOverlay { proxy in
                            GeometryReader { geo in
                                Rectangle()
                                    .fill(Color.clear)
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
                        .frame(height: 220)
                    }
                    .padding(20)
                    .background(CaloTheme.surfacePrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal, 20)

                    // Selected day detail
                    if let selected = selectedDay {
                        DayDetailCard(day: selected, entries: entriesForDay(selected.date))
                            .padding(.horizontal, 20)
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .opacity
                            ))
                    }

                    // Summary stats
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        StatCard(title: "Weekly Total", value: "\(totalWeek.wholeOrOne)", unit: "cal")
                        StatCard(title: "Daily Average", value: "\(avgDaily.wholeOrOne)", unit: "cal")
                        StatCard(title: "Highest Day", value: "\(highestDay.wholeOrOne)", unit: "cal")
                        StatCard(title: "Days on Target", value: "\(daysOnTarget)", unit: "of 7")
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 8)
                .padding(.bottom, 20)
            }
            .background(Color.black)
            .navigationTitle("Weekly")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .animation(CaloTheme.springAnimation, value: selectedDay?.id)
        }
    }

    private func entriesForDay(_ date: Date) -> [FoodEntry] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        return allEntries.filter { $0.timestamp >= start && $0.timestamp < end }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let unit: String

    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white)
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(CaloTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct DayDetailCard: View {
    let day: DayCalories
    let entries: [FoodEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(day.date.formatted(date: .abbreviated, time: .omitted))
                .font(.headline)
                .foregroundStyle(.white)

            if entries.isEmpty {
                Text("No meals logged")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                let protein = entries.reduce(0.0) { $0 + $1.protein }
                let carbs = entries.reduce(0.0) { $0 + $1.carbs }
                let fat = entries.reduce(0.0) { $0 + $1.fat }

                HStack(spacing: 16) {
                    MacroColumn(label: "Calories", value: day.calories, color: CaloTheme.coral)
                    MacroColumn(label: "Protein", value: protein, color: .blue)
                    MacroColumn(label: "Carbs", value: carbs, color: .orange)
                    MacroColumn(label: "Fat", value: fat, color: .purple)
                }

                Rectangle()
                    .fill(CaloTheme.separator)
                    .frame(height: 0.5)

                ForEach(entries) { entry in
                    HStack {
                        Text(entry.foodName.capitalized)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                        Spacer()
                        Text("\(entry.calories.wholeOrOne) cal")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(16)
        .background(CaloTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct MacroColumn: View {
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text("\(value.wholeOrOne)g")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
