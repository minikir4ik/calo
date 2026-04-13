import SwiftUI
import SwiftData

struct DailyLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FoodEntry.timestamp, order: .reverse) private var allEntries: [FoodEntry]
    @Query private var allSettings: [UserSettings]

    @State private var selectedDate: Date = .now

    private var settings: UserSettings? { allSettings.first }

    private var entriesForDate: [FoodEntry] {
        let start = Calendar.current.startOfDay(for: selectedDate)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        return allEntries.filter { $0.timestamp >= start && $0.timestamp < end }
    }

    private var totalCalories: Double { entriesForDate.reduce(0) { $0 + $1.calories } }
    private var totalProtein: Double { entriesForDate.reduce(0) { $0 + $1.protein } }
    private var totalCarbs: Double { entriesForDate.reduce(0) { $0 + $1.carbs } }
    private var totalFat: Double { entriesForDate.reduce(0) { $0 + $1.fat } }

    private var last7Days: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        return (0..<7).reversed().map { calendar.date(byAdding: .day, value: -$0, to: today)! }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Horizontal date picker
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(last7Days, id: \.self) { date in
                                    DateChip(
                                        date: date,
                                        isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate)
                                    )
                                    .id(date)
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedDate = date
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                        }
                        .onAppear {
                            if let today = last7Days.last {
                                proxy.scrollTo(today, anchor: .trailing)
                            }
                        }
                    }

                    // Summary row
                    HStack(spacing: 0) {
                        // Calories
                        VStack(spacing: 2) {
                            Text(totalCalories.wholeOrOne)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(CaloTheme.coral)
                            Text("cal")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)

                        Divider()
                            .frame(height: 32)

                        // Protein
                        VStack(spacing: 2) {
                            Text("\(totalProtein.wholeOrOne)g")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundStyle(.blue)
                            Text("protein")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)

                        Divider()
                            .frame(height: 32)

                        // Carbs
                        VStack(spacing: 2) {
                            Text("\(totalCarbs.wholeOrOne)g")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundStyle(.orange)
                            Text("carbs")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)

                        Divider()
                            .frame(height: 32)

                        // Fat
                        VStack(spacing: 2) {
                            Text("\(totalFat.wholeOrOne)g")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundStyle(.purple)
                            Text("fat")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 20)
                    .background(CaloTheme.surfacePrimary)

                    // Goal progress
                    if let settings {
                        let progress = min(totalCalories / Double(settings.dailyCalorieGoal), 1.0)
                        VStack(spacing: 6) {
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.white.opacity(0.08))
                                    Capsule()
                                        .fill(CaloTheme.coral)
                                        .frame(width: geo.size.width * progress)
                                }
                            }
                            .frame(height: 4)

                            HStack {
                                Text("\(totalCalories.wholeOrOne) / \(settings.dailyCalorieGoal) cal goal")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("\(Int(progress * 100))%")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(CaloTheme.coral)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                    }

                    // Separator
                    Rectangle()
                        .fill(CaloTheme.separator)
                        .frame(height: 0.5)

                    // Food entries
                    if entriesForDate.isEmpty {
                        VStack(spacing: 8) {
                            Text("No meals logged")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("Scan food to start tracking")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                    } else {
                        LazyVStack(spacing: 0) {
                            ForEach(entriesForDate.sorted(by: { $0.timestamp > $1.timestamp })) { entry in
                                FoodEntryRow(entry: entry)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            modelContext.delete(entry)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }

                                Rectangle()
                                    .fill(CaloTheme.separator)
                                    .frame(height: 0.5)
                                    .padding(.leading, 20)
                            }
                        }
                    }
                }
            }
            .background(Color.black)
            .navigationTitle("Daily Log")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

struct DateChip: View {
    let date: Date
    let isSelected: Bool

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(dayName)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(isSelected ? .white : .secondary)
            Text(dayNumber)
                .font(.system(size: 17, weight: isSelected ? .bold : .medium, design: .rounded))
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .frame(width: 44, height: 56)
        .background(isSelected ? CaloTheme.coral : CaloTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isToday && !isSelected ? CaloTheme.coral.opacity(0.5) : .clear, lineWidth: 1)
        )
    }
}

struct FoodEntryRow: View {
    let entry: FoodEntry

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(entry.foodName.capitalized)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.white)

                    if entry.verified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }
                }

                Text(entry.timeString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(entry.calories.wholeOrOne) cal")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(CaloTheme.coral)
        }
    }
}
