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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Chart
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Weekly Calories")
                            .font(.headline)

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
                            .cornerRadius(6)

                            if let goal = settings?.dailyCalorieGoal {
                                RuleMark(y: .value("Goal", goal))
                                    .foregroundStyle(.secondary.opacity(0.5))
                                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                                    .annotation(position: .trailing, alignment: .leading) {
                                        Text("Goal")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading)
                        }
                        .chartOverlay { proxy in
                            GeometryReader { geo in
                                Rectangle()
                                    .fill(Color.clear)
                                    .contentShape(Rectangle())
                                    .onTapGesture { location in
                                        if let weekday: String = proxy.value(atX: location.x) {
                                            selectedDay = weekData.first { $0.weekday == weekday }
                                        }
                                    }
                            }
                        }
                        .frame(height: 220)
                    }
                    .padding()
                    .cardStyle()
                    .padding(.horizontal)

                    // Selected day detail
                    if let selected = selectedDay {
                        DayDetailCard(day: selected, entries: entriesForDay(selected.date))
                            .padding(.horizontal)
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .opacity
                            ))
                    }

                    // Weekly summary
                    let totalWeek = weekData.reduce(0.0) { $0 + $1.calories }
                    let avgDaily = totalWeek / 7

                    VStack(spacing: 8) {
                        HStack {
                            SummaryItem(title: "Weekly Total", value: "\(totalWeek.wholeOrOne) cal")
                            SummaryItem(title: "Daily Avg", value: "\(avgDaily.wholeOrOne) cal")
                        }
                    }
                    .padding()
                    .cardStyle()
                    .padding(.horizontal)
                }
                .padding(.top)
            }
            .navigationTitle("Weekly")
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

struct DayDetailCard: View {
    let day: DayCalories
    let entries: [FoodEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(day.date.formatted(date: .abbreviated, time: .omitted))
                .font(.headline)

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

                Divider()

                ForEach(entries) { entry in
                    HStack {
                        Text(entry.foodName.capitalized)
                            .font(.subheadline)
                        Spacer()
                        Text("\(entry.calories.wholeOrOne) cal")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .cardStyle()
    }
}

struct SummaryItem: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.title3, design: .rounded, weight: .semibold))
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
