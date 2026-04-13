import SwiftUI
import SwiftData

struct ScanView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allSettings: [UserSettings]

    @State private var capturedImage: UIImage?
    @State private var imageData: Data?
    @State private var analysisResult: AnalysisResult?
    @State private var isAnalyzing = false
    @State private var errorMessage: String?
    @State private var showCamera = false
    @State private var showResult = false
    @State private var showPaywall = false
    @State private var foodDescription = ""

    private var settings: UserSettings? { allSettings.first }

    var body: some View {
        VStack(spacing: 0) {
            // Scan counter pill
            HStack {
                if let settings, !settings.isPremium {
                    Text("\(settings.scansRemainingToday) scans remaining")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Capsule())
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            // Camera area
            ZStack {
                if let capturedImage {
                    Image(uiImage: capturedImage)
                        .resizable()
                        .scaledToFill()
                        .clipped()
                } else {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(white: 0.1))
                        .allowsHitTesting(false)
                    Image(systemName: "viewfinder")
                        .font(.system(size: 60, weight: .ultraLight))
                        .foregroundStyle(.white.opacity(0.15))
                        .allowsHitTesting(false)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.horizontal, 16)
            .padding(.top, 12)

            Spacer().frame(height: 16)

            // Analyzing state
            if isAnalyzing {
                HStack(spacing: 10) {
                    ProgressView()
                        .tint(.white)
                    Text("Analyzing...")
                        .font(.subheadline)
                        .foregroundStyle(CaloTheme.subtleText)
                }
                .padding(.bottom, 8)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 4)
            }

            // Text input
            TextField("Or describe your food...", text: $foodDescription)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(CaloTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)

            Spacer().frame(height: 16)

            // Bottom buttons
            HStack(spacing: 16) {
                if !foodDescription.isEmpty {
                    Button {
                        analyzeFood()
                    } label: {
                        Text("Analyze")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(height: 44)
                            .frame(maxWidth: .infinity)
                            .background(CaloTheme.coral)
                            .clipShape(Capsule())
                            .contentShape(Capsule())
                    }
                    .transition(.scale.combined(with: .opacity))
                }

                Button {
                    showCamera = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(CaloTheme.coral)
                            .frame(width: 70, height: 70)
                        Circle()
                            .stroke(Color.white.opacity(0.25), lineWidth: 3)
                            .frame(width: 80, height: 80)
                    }
                    .contentShape(Circle())
                }

                if !foodDescription.isEmpty {
                    Color.clear
                        .frame(height: 44)
                        .frame(maxWidth: .infinity)
                        .allowsHitTesting(false)
                }
            }
            .padding(.horizontal, 16)
            .animation(CaloTheme.springAnimation, value: foodDescription.isEmpty)

            Spacer().frame(height: 12)
        }
        .background(Color.black.ignoresSafeArea())
        .fullScreenCover(isPresented: $showCamera) {
            CameraView { image in
                withAnimation(CaloTheme.springAnimation) {
                    capturedImage = image
                    imageData = image.compressed(maxKB: 500)
                }
                showCamera = false
                analyzeFood()
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showResult) {
            if let result = analysisResult {
                ResultView(
                    result: result,
                    image: capturedImage,
                    isPremium: settings?.isPremium ?? false
                ) {
                    addToLog(result: result)
                    showResult = false
                    resetState()
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    private func analyzeFood() {
        guard let settings else { return }

        if !settings.canScan {
            showPaywall = true
            return
        }

        let description = foodDescription.isEmpty ? "Identify this food" : foodDescription
        isAnalyzing = true
        errorMessage = nil

        Task {
            do {
                let result = try await FoodAnalysisService.analyze(
                    description: description,
                    imageData: imageData
                )
                await MainActor.run {
                    settings.recordScan()
                    analysisResult = result
                    isAnalyzing = false
                    showResult = true
                }
            } catch {
                await MainActor.run {
                    isAnalyzing = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func addToLog(result: AnalysisResult) {
        for food in result.foods {
            let entry = FoodEntry(
                foodName: food.name,
                calories: food.calories,
                protein: food.protein,
                carbs: food.carbs,
                fat: food.fat,
                grams: food.grams,
                confidence: food.confidence,
                verified: food.verified,
                imageData: imageData
            )
            modelContext.insert(entry)
        }
    }

    private func resetState() {
        capturedImage = nil
        imageData = nil
        analysisResult = nil
        foodDescription = ""
        errorMessage = nil
    }
}
