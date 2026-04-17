import SwiftUI
import SwiftData

struct DailyLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FoodEntry.timestamp, order: .reverse) private var allEntries: [FoodEntry]
    @Query private var allSettings: [UserSettings]

    @State private var selectedDate: Date = Calendar.current.startOfDay(for: .now)
    @State private var expandedEntryID: UUID?

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

    private var calorieGoal: Double { Double(settings?.dailyCalorieGoal ?? 2000) }
    private var calorieProgress: Double { min(totalCalories / max(calorieGoal, 1), 1.0) }

    private var last7Days: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        return (0..<7).reversed().map { calendar.date(byAdding: .day, value: -$0, to: today)! }
    }

    private func hasEntries(for date: Date) -> Bool {
        let start = Calendar.current.startOfDay(for: date)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        return allEntries.contains { $0.timestamp >= start && $0.timestamp < end }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CaloTheme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Date selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(last7Days, id: \.self) { date in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedDate = date
                                    }
                                    HapticManager.lightImpact()
                                } label: {
                                    DateCircle(
                                        date: date,
                                        isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                                        hasData: hasEntries(for: date)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                    }

                    // Summary card
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .stroke(CaloTheme.cardBorder, lineWidth: 6)
                                .frame(width: 100, height: 100)
                            Circle()
                                .trim(from: 0, to: calorieProgress)
                                .stroke(CaloTheme.coral, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                                .frame(width: 100, height: 100)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeOut(duration: 0.6), value: calorieProgress)
                            VStack(spacing: 1) {
                                Text(totalCalories.wholeOrOne)
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                Text("cal")
                                    .font(.caption2)
                                    .foregroundStyle(CaloTheme.subtleText)
                            }
                        }

                        HStack(spacing: 10) {
                            MacroPillCompact(label: "P", value: totalProtein, color: CaloTheme.accentGreen)
                            MacroPillCompact(label: "C", value: totalCarbs, color: CaloTheme.accentBlue)
                            MacroPillCompact(label: "F", value: totalFat, color: CaloTheme.accentPurple)
                        }
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity)
                    .background(CaloTheme.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(CaloTheme.cardBorder, lineWidth: 0.5)
                    )
                    .padding(.horizontal, 20)

                    Spacer().frame(height: 16)

                    // Food entries
                    if entriesForDate.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "fork.knife")
                                .font(.system(size: 40, weight: .thin))
                                .foregroundStyle(.white.opacity(0.15))
                            Text("Scan your first meal")
                                .font(.subheadline)
                                .foregroundStyle(CaloTheme.subtleText)
                        }
                        Spacer()
                    } else {
                        List {
                            ForEach(entriesForDate.sorted(by: { $0.timestamp > $1.timestamp })) { entry in
                                ExpandableFoodRow(
                                    entry: entry,
                                    isExpanded: expandedEntryID == entry.id,
                                    onTap: {
                                        withAnimation(.easeInOut(duration: 0.25)) {
                                            if expandedEntryID == entry.id {
                                                expandedEntryID = nil
                                            } else {
                                                expandedEntryID = entry.id
                                                HapticManager.lightImpact()
                                            }
                                        }
                                    }
                                )
                                .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                            }
                            .onDelete(perform: deleteEntries)
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
            .preferredColorScheme(.dark)
        }
    }

    private func deleteEntries(at offsets: IndexSet) {
        let sorted = entriesForDate.sorted(by: { $0.timestamp > $1.timestamp })
        for index in offsets {
            modelContext.delete(sorted[index])
        }
        HapticManager.lightImpact()
    }
}

// MARK: - Expandable Food Row

private struct ExpandableFoodRow: View {
    let entry: FoodEntry
    let isExpanded: Bool
    let onTap: () -> Void

    private var components: [FoodEntry.Component] { entry.components }
    private var hasComponents: Bool { components.count > 1 }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Main row
                HStack(spacing: 12) {
                    // Emoji
                    if let emoji = entry.emoji, !emoji.isEmpty {
                        Text(emoji)
                            .font(.system(size: 28))
                            .frame(width: 40, height: 40)
                    } else {
                        Circle()
                            .fill(CaloTheme.coral.opacity(0.15))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "fork.knife")
                                    .font(.system(size: 14))
                                    .foregroundStyle(CaloTheme.coral)
                            )
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(entry.foodName)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                            if entry.verified {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(CaloTheme.accentGreen)
                            }
                        }
                        HStack(spacing: 6) {
                            Text(entry.timeString)
                                .font(.caption2)
                                .foregroundStyle(CaloTheme.subtleText)
                            if hasComponents {
                                Text("·")
                                    .foregroundStyle(CaloTheme.subtleText)
                                Text("\(components.count) items")
                                    .font(.caption2)
                                    .foregroundStyle(CaloTheme.subtleText)
                            }
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(entry.calories.wholeOrOne)")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundStyle(CaloTheme.coral)
                        + Text(" cal")
                            .font(.system(.caption2, design: .rounded))
                            .foregroundStyle(CaloTheme.subtleText)

                        // Mini macro badges
                        HStack(spacing: 4) {
                            MicroBadge(text: "\(entry.protein.wholeOrOne)", color: CaloTheme.accentGreen)
                            MicroBadge(text: "\(entry.carbs.wholeOrOne)", color: CaloTheme.accentBlue)
                            MicroBadge(text: "\(entry.fat.wholeOrOne)", color: CaloTheme.accentPurple)
                        }
                    }
                }
                .padding(.vertical, 4)

                // Expanded: component breakdown
                if isExpanded && hasComponents {
                    Divider()
                        .background(CaloTheme.cardBorder)
                        .padding(.vertical, 8)

                    VStack(spacing: 6) {
                        ForEach(components) { comp in
                            HStack {
                                Text(comp.name)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.8))
                                Spacer()
                                Text("\(comp.calories.wholeOrOne) cal")
                                    .font(.caption)
                                    .foregroundStyle(CaloTheme.subtleText)
                                Text("\(comp.protein.wholeOrOne)g P")
                                    .font(.caption2)
                                    .foregroundStyle(CaloTheme.accentGreen.opacity(0.7))
                            }
                        }
                    }
                    .padding(.bottom, 4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(12)
            .background(
                CaloTheme.cardBackground,
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isExpanded ? CaloTheme.coral.opacity(0.3) : CaloTheme.cardBorder, lineWidth: 0.5)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct MicroBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 9, weight: .semibold, design: .rounded))
            .foregroundStyle(color)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 4))
    }
}

// MARK: - Shared Subviews

struct DateCircle: View {
    let date: Date
    let isSelected: Bool
    let hasData: Bool

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

    var body: some View {
        VStack(spacing: 6) {
            Text(dayName)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(isSelected ? .white : CaloTheme.subtleText)

            ZStack {
                Circle()
                    .fill(isSelected ? CaloTheme.coral : CaloTheme.cardBackground)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color.clear : CaloTheme.cardBorder, lineWidth: 0.5)
                    )

                Text(dayNumber)
                    .font(.system(size: 15, weight: isSelected ? .bold : .medium, design: .rounded))
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.7))
            }

            Circle()
                .fill(hasData ? CaloTheme.coral : Color.clear)
                .frame(width: 4, height: 4)
        }
    }
}

struct MacroPillCompact: View {
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text("\(label) \(value.wholeOrOne)g")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.12), in: Capsule())
    }
}
