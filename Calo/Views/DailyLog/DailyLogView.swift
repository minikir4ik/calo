import SwiftUI
import SwiftData

struct DailyLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FoodEntry.timestamp, order: .reverse) private var allEntries: [FoodEntry]

    @State private var selectedDate: Date = .now

    private var entriesForDate: [FoodEntry] {
        let start = Calendar.current.startOfDay(for: selectedDate)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        return allEntries.filter { $0.timestamp >= start && $0.timestamp < end }
    }

    private var totalCalories: Double { entriesForDate.reduce(0) { $0 + $1.calories } }
    private var totalProtein: Double { entriesForDate.reduce(0) { $0 + $1.protein } }
    private var totalCarbs: Double { entriesForDate.reduce(0) { $0 + $1.carbs } }
    private var totalFat: Double { entriesForDate.reduce(0) { $0 + $1.fat } }

    var body: some View {
        NavigationStack {
            List {
                // Date picker
                Section {
                    DatePicker(
                        "Date",
                        selection: $selectedDate,
                        in: ...Date.now,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                }

                // Summary card
                Section {
                    VStack(spacing: 12) {
                        Text("\(totalCalories.wholeOrOne)")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundStyle(CaloTheme.coral)
                        Text("calories today")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 20) {
                            MacroColumn(label: "Protein", value: totalProtein, color: .blue)
                            MacroColumn(label: "Carbs", value: totalCarbs, color: .orange)
                            MacroColumn(label: "Fat", value: totalFat, color: .purple)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }

                // Entries
                Section(entriesForDate.isEmpty ? "" : "Meals") {
                    if entriesForDate.isEmpty {
                        ContentUnavailableView(
                            "No meals logged",
                            systemImage: "fork.knife",
                            description: Text("Scan food to start tracking")
                        )
                    } else {
                        ForEach(entriesForDate.sorted(by: { $0.timestamp > $1.timestamp })) { entry in
                            FoodEntryRow(entry: entry)
                        }
                        .onDelete(perform: deleteEntries)
                    }
                }
            }
            .navigationTitle("Daily Log")
        }
    }

    private func deleteEntries(at offsets: IndexSet) {
        let sorted = entriesForDate.sorted(by: { $0.timestamp > $1.timestamp })
        for index in offsets {
            modelContext.delete(sorted[index])
        }
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

struct FoodEntryRow: View {
    let entry: FoodEntry

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(entry.foodName.capitalized)
                        .font(.body.weight(.medium))

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
        .padding(.vertical, 2)
    }
}
