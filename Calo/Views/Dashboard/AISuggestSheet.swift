import SwiftUI
import SwiftData

struct AISuggestSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var allSettings: [UserSettings]
    @Query(sort: \FoodEntry.timestamp, order: .reverse) private var allEntries: [FoodEntry]

    @State private var suggestions: [GeminiService.MealSuggestion] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    private var settings: UserSettings? { allSettings.first }

    private var todayEntries: [FoodEntry] {
        let start = Calendar.current.startOfDay(for: .now)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        return allEntries.filter { $0.timestamp >= start && $0.timestamp < end }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CaloTheme.background.ignoresSafeArea()

                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(CaloTheme.coral)
                            .scaleEffect(1.2)
                        Text("Thinking about what you should eat...")
                            .font(.subheadline)
                            .foregroundStyle(CaloTheme.subtleText)
                    }
                } else if let errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.title)
                            .foregroundStyle(.yellow)
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundStyle(CaloTheme.subtleText)
                            .multilineTextAlignment(.center)
                        Button("Try Again") { loadSuggestions() }
                            .foregroundStyle(CaloTheme.coral)
                    }
                    .padding(.horizontal, 32)
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            Text("Based on your macros today")
                                .font(.subheadline)
                                .foregroundStyle(CaloTheme.subtleText)
                                .padding(.top, 8)

                            ForEach(suggestions) { suggestion in
                                SuggestionCard(suggestion: suggestion) {
                                    logSuggestion(suggestion)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .navigationTitle("Meal Ideas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(CaloTheme.coral)
                }
            }
        }
        .task { loadSuggestions() }
    }

    private func loadSuggestions() {
        isLoading = true
        errorMessage = nil

        let currentCal = todayEntries.reduce(0.0) { $0 + $1.calories }
        let currentProtein = todayEntries.reduce(0.0) { $0 + $1.protein }
        let currentCarbs = todayEntries.reduce(0.0) { $0 + $1.carbs }
        let currentFat = todayEntries.reduce(0.0) { $0 + $1.fat }

        Task {
            do {
                suggestions = try await GeminiService.suggestMeals(
                    currentCalories: currentCal,
                    currentProtein: currentProtein,
                    currentCarbs: currentCarbs,
                    currentFat: currentFat,
                    targetCalories: settings?.dailyCalorieGoal ?? 2000,
                    targetProtein: settings?.dailyProteinGoal ?? 150,
                    targetCarbs: settings?.dailyCarbsGoal ?? 250,
                    targetFat: settings?.dailyFatGoal ?? 65
                )
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    private func logSuggestion(_ suggestion: GeminiService.MealSuggestion) {
        let entry = FoodEntry(
            foodName: suggestion.name,
            emoji: suggestion.emoji,
            calories: Double(suggestion.estimated_calories),
            protein: Double(suggestion.estimated_protein),
            carbs: 0,
            fat: 0,
            grams: 0,
            confidence: 0.7,
            verified: false
        )
        modelContext.insert(entry)
        HapticManager.success()
        dismiss()
    }
}

private struct SuggestionCard: View {
    let suggestion: GeminiService.MealSuggestion
    let onLog: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(suggestion.emoji)
                    .font(.system(size: 28))

                VStack(alignment: .leading, spacing: 2) {
                    Text(suggestion.name)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(suggestion.description)
                        .font(.caption)
                        .foregroundStyle(CaloTheme.subtleText)
                        .lineLimit(2)
                }
                Spacer()
            }

            HStack {
                Text("\(suggestion.estimated_calories) cal")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CaloTheme.coral)
                Text("·")
                    .foregroundStyle(CaloTheme.subtleText)
                Text("\(suggestion.estimated_protein)g protein")
                    .font(.subheadline)
                    .foregroundStyle(CaloTheme.accentGreen)

                Spacer()

                Button {
                    HapticManager.mediumImpact()
                    onLog()
                } label: {
                    Text("Log it")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(CaloTheme.coral, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(CaloTheme.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(CaloTheme.cardBorder, lineWidth: 0.5)
        )
    }
}
