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
            VStack(spacing: 0) {
                // Date chips — outside List for reliable tapping
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(last7Days, id: \.self) { date in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedDate = date
                                }
                            } label: {
                                DateChip(
                                    date: date,
                                    isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }

                // Summary row
                HStack(spacing: 0) {
                    VStack(spacing: 2) {
                        Text(totalCalories.wholeOrOne)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(CaloTheme.coral)
                        Text("cal")
                            .font(.caption2)
                            .foregroundStyle(CaloTheme.subtleText)
                    }
                    .frame(maxWidth: .infinity)

                    Rectangle().fill(CaloTheme.separator).frame(width: 0.5, height: 28)

                    VStack(spacing: 2) {
                        Text("\(totalProtein.wholeOrOne)g")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(.blue)
                        Text("protein")
                            .font(.caption2)
                            .foregroundStyle(CaloTheme.subtleText)
                    }
                    .frame(maxWidth: .infinity)

                    Rectangle().fill(CaloTheme.separator).frame(width: 0.5, height: 28)

                    VStack(spacing: 2) {
                        Text("\(totalCarbs.wholeOrOne)g")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(.orange)
                        Text("carbs")
                            .font(.caption2)
                            .foregroundStyle(CaloTheme.subtleText)
                    }
                    .frame(maxWidth: .infinity)

                    Rectangle().fill(CaloTheme.separator).frame(width: 0.5, height: 28)

                    VStack(spacing: 2) {
                        Text("\(totalFat.wholeOrOne)g")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(.purple)
                        Text("fat")
                            .font(.caption2)
                            .foregroundStyle(CaloTheme.subtleText)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)

                Rectangle().fill(CaloTheme.separator).frame(height: 0.5)

                // Food entries — plain List fills remaining space
                if entriesForDate.isEmpty {
                    Spacer()
                    Text("No entries today")
                        .font(.subheadline)
                        .foregroundStyle(CaloTheme.subtleText)
                    Spacer()
                } else {
                    List {
                        ForEach(entriesForDate.sorted(by: { $0.timestamp > $1.timestamp })) { entry in
                            FoodEntryRow(entry: entry)
                                .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                        }
                        .onDelete(perform: deleteEntries)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Log")
            .navigationBarTitleDisplayMode(.large)
            .preferredColorScheme(.dark)
        }
    }

    private func deleteEntries(at offsets: IndexSet) {
        let sorted = entriesForDate.sorted(by: { $0.timestamp > $1.timestamp })
        for index in offsets {
            modelContext.delete(sorted[index])
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
                .foregroundStyle(isSelected ? .white : CaloTheme.subtleText)
            Text(dayNumber)
                .font(.system(size: 17, weight: isSelected ? .bold : .medium, design: .rounded))
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .frame(width: 44, height: 56)
        .background(isSelected ? CaloTheme.coral : CaloTheme.cardBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
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
            VStack(alignment: .leading, spacing: 3) {
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
                    .foregroundStyle(CaloTheme.subtleText)
            }
            Spacer()
            Text("\(entry.calories.wholeOrOne) cal")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(CaloTheme.coral)
        }
        .contentShape(Rectangle())
    }
}
