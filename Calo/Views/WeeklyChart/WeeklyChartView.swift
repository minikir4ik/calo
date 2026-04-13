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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
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
                                .foregroundStyle(Color.gray.opacity(0.5))
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { _ in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(Color.white.opacity(0.08))
                            AxisValueLabel()
                                .foregroundStyle(CaloTheme.subtleText)
                        }
                    }
                    .chartXAxis {
                        AxisMarks { _ in
                            AxisValueLabel()
                                .foregroundStyle(CaloTheme.subtleText)
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
                    .frame(height: 220)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    if let selected = selectedDay {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(selected.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.headline)
                                .foregroundStyle(.white)

                            let dayEntries = entriesForDay(selected.date)
                            if dayEntries.isEmpty {
                                Text("No meals logged")
                                    .font(.subheadline)
                                    .foregroundStyle(CaloTheme.subtleText)
                            } else {
                                HStack(spacing: 16) {
                                    MacroColumn(label: "Calories", value: selected.calories, color: CaloTheme.coral)
                                    MacroColumn(label: "Protein", value: dayEntries.reduce(0) { $0 + $1.protein }, color: .blue)
                                    MacroColumn(label: "Carbs", value: dayEntries.reduce(0) { $0 + $1.carbs }, color: .orange)
                                    MacroColumn(label: "Fat", value: dayEntries.reduce(0) { $0 + $1.fat }, color: .purple)
                                }

                                Rectangle().fill(CaloTheme.separator).frame(height: 0.5)

                                ForEach(dayEntries) { entry in
                                    HStack {
                                        Text(entry.foodName.capitalized)
                                            .font(.subheadline)
                                            .foregroundStyle(.white)
                                        Spacer()
                                        Text("\(entry.calories.wholeOrOne) cal")
                                            .font(.subheadline)
                                            .foregroundStyle(CaloTheme.subtleText)
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .background(CaloTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .padding(.horizontal, 16)
                        .transition(.opacity)
                    }

                    HStack(spacing: 12) {
                        StatBlock(title: "Weekly Total", value: "\(totalWeek.wholeOrOne) cal")
                        StatBlock(title: "Daily Avg", value: "\(avgDaily.wholeOrOne) cal")
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
            .background(Color.black.ignoresSafeArea())
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

struct StatBlock: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(.white)
            Text(title)
                .font(.caption)
                .foregroundStyle(CaloTheme.subtleText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(CaloTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
                .foregroundStyle(CaloTheme.subtleText)
        }
        .frame(maxWidth: .infinity)
    }
}
