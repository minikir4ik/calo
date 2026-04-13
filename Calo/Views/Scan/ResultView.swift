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
                    // Food image
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 250)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .padding(.horizontal)
                    }

                    // Total summary card
                    VStack(spacing: 16) {
                        Text("\(result.totalCalories.wholeOrOne)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(CaloTheme.coral)
                        Text("calories")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 24) {
                            MacroPill(label: "Protein", value: result.totalProtein, color: .blue)
                            MacroPill(label: "Carbs", value: result.totalCarbs, color: .orange)
                            MacroPill(label: "Fat", value: result.totalFat, color: .purple)
                        }
                    }
                    .padding()
                    .cardStyle()
                    .padding(.horizontal)

                    // Individual foods
                    ForEach(result.foods) { food in
                        FoodResultCard(food: food)
                            .padding(.horizontal)
                    }

                    // Share button
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
                        .foregroundStyle(.secondary)
                    }
                    .padding(.top, 4)

                    // Add to Log button
                    Button(action: onAddToLog) {
                        Text("Add to Log")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(CaloTheme.coral)
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                .padding(.top)
            }
            .navigationTitle("Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
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
                .foregroundStyle(.secondary)
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

                Spacer()

                if food.verified {
                    Label("USDA Verified", systemImage: "checkmark.seal.fill")
                        .font(.caption2)
                        .foregroundStyle(.green)
                } else {
                    Label("AI Estimate", systemImage: "sparkles")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }

            HStack {
                Text("\(food.grams.wholeOrOne)g")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(food.calories.wholeOrOne) cal")
                    .font(.subheadline.bold())
                    .foregroundStyle(CaloTheme.coral)
            }

            // Confidence bar
            HStack(spacing: 4) {
                Text("Confidence")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(.tertiarySystemFill))
                        Capsule()
                            .fill(confidenceColor)
                            .frame(width: geo.size.width * food.confidence)
                    }
                }
                .frame(height: 4)

                Text("\(Int(food.confidence * 100))%")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .cardStyle()
    }

    private var confidenceColor: Color {
        food.confidence > 0.8 ? .green : food.confidence > 0.5 ? .orange : .red
    }
}
