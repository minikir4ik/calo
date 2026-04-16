import SwiftUI

struct ResultView: View {
    let result: AnalysisResult
    let image: UIImage?
    let isPremium: Bool
    let onAddToLog: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 240)
                            .clipped()
                    }

                    // Total summary
                    VStack(spacing: 10) {
                        Text("\(result.totalCalories.wholeOrOne)")
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundStyle(CaloTheme.coral)
                        Text("calories")
                            .font(.subheadline)
                            .foregroundStyle(CaloTheme.subtleText)

                        HStack(spacing: 24) {
                            MacroPill(label: "Protein", value: result.totalProtein, color: CaloTheme.accentGreen)
                            MacroPill(label: "Carbs", value: result.totalCarbs, color: CaloTheme.accentBlue)
                            MacroPill(label: "Fat", value: result.totalFat, color: CaloTheme.accentPurple)
                        }
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 16)

                    Rectangle().fill(CaloTheme.separator).frame(height: 0.5).padding(.horizontal, 16)

                    // Individual foods
                    VStack(spacing: 12) {
                        ForEach(result.foods) { food in
                            FoodResultCard(food: food)
                        }
                    }
                    .padding(.horizontal, 16)

                    // Share
                    ShareLink(
                        item: shareText,
                        subject: Text("My meal from Calo"),
                        message: Text(shareText)
                    ) {
                        Label(
                            isPremium ? "Share" : "Share (with watermark)",
                            systemImage: "square.and.arrow.up"
                        )
                        .font(.subheadline)
                        .foregroundStyle(CaloTheme.subtleText)
                    }

                    // Add to Log
                    Button(action: {
                        HapticManager.success()
                        onAddToLog()
                    }) {
                        Text("Add to Log")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(CaloTheme.coral, in: Capsule())
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(CaloTheme.coral)
                }
            }
        }
    }

    private var shareText: String {
        var text = result.foods.map { "\($0.name): \($0.calories.wholeOrOne) cal" }.joined(separator: "\n")
        text += "\nTotal: \(result.totalCalories.wholeOrOne) cal"
        if !isPremium {
            text += "\n\nTracked with Calo"
        }
        return text
    }
}

struct MacroPill: View {
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(value.wholeOrOne)g")
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(CaloTheme.subtleText)
        }
    }
}

struct FoodResultCard: View {
    let food: AnalyzedFood

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(food.name.capitalized)
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                if food.verified {
                    Label("USDA", systemImage: "checkmark.seal.fill")
                        .font(.caption2)
                        .foregroundStyle(.green)
                } else {
                    Label("AI", systemImage: "sparkles")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }

            HStack {
                Text("\(food.grams.wholeOrOne)g")
                    .font(.subheadline)
                    .foregroundStyle(CaloTheme.subtleText)
                Spacer()
                Text("\(food.calories.wholeOrOne) cal")
                    .font(.subheadline.bold())
                    .foregroundStyle(CaloTheme.coral)
            }

            // Confidence
            HStack(spacing: 4) {
                Text("Confidence")
                    .font(.caption2)
                    .foregroundStyle(CaloTheme.subtleText)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.08))
                        Capsule()
                            .fill(food.confidence > 0.8 ? .green : food.confidence > 0.5 ? .orange : .red)
                            .frame(width: geo.size.width * food.confidence)
                    }
                }
                .frame(height: 4)

                Text("\(Int(food.confidence * 100))%")
                    .font(.caption2)
                    .foregroundStyle(CaloTheme.subtleText)
            }
        }
        .padding(14)
        .background(CaloTheme.cardBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
