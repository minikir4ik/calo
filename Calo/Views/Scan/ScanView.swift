import SwiftUI
import SwiftData

struct ScanView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var premiumManager: PremiumManager
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
    @State private var pulseAmount: CGFloat = 1.0

    private var settings: UserSettings? { allSettings.first }

    var body: some View {
        ZStack {
            CaloTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Scan counter pill
                HStack {
                    if !premiumManager.isPremium {
                        Text("\(premiumManager.dailyScansRemaining) scans left")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.white.opacity(0.08), in: Capsule())
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                // Camera area
                GeometryReader { geo in
                    ZStack {
                        if let capturedImage {
                            Image(uiImage: capturedImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: geo.size.width, height: geo.size.height)
                                .clipped()
                        } else {
                            Color(white: 0.08)
                            VStack(spacing: 12) {
                                Image(systemName: "viewfinder")
                                    .font(.system(size: 56, weight: .thin))
                                    .foregroundStyle(.white.opacity(0.15))
                                Text("Tap to capture")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.2))
                            }
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(CaloTheme.cardBorder, lineWidth: 0.5)
                    )
                    .onTapGesture { showCamera = true }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                Spacer().frame(height: 16)

                // Error
                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red.opacity(0.9))
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                }

                // Text input
                HStack(spacing: 10) {
                    Image(systemName: "text.cursor")
                        .foregroundStyle(.white.opacity(0.25))
                        .font(.subheadline)
                    TextField("Describe your food...", text: $foodDescription)
                        .foregroundStyle(.white)
                        .font(.subheadline)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(CaloTheme.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(CaloTheme.cardBorder, lineWidth: 0.5)
                        )
                )
                .padding(.horizontal, 20)

                Spacer().frame(height: 20)

                // Bottom action area
                HStack(spacing: 20) {
                    // Text analyze button
                    if !foodDescription.isEmpty {
                        Button(action: { analyzeFood() }) {
                            Text("Analyze")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(CaloTheme.cardBackground, in: Capsule())
                                .overlay(Capsule().stroke(CaloTheme.cardBorder, lineWidth: 0.5))
                        }
                        .buttonStyle(.plain)
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    }

                    // Capture button
                    Button(action: { showCamera = true }) {
                        ZStack {
                            if isAnalyzing {
                                Circle()
                                    .stroke(CaloTheme.coral.opacity(0.3), lineWidth: 3)
                                    .frame(width: 76, height: 76)
                                Circle()
                                    .trim(from: 0, to: 0.3)
                                    .stroke(CaloTheme.coral, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                    .frame(width: 76, height: 76)
                                    .rotationEffect(.degrees(pulseAmount * 360))
                                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: pulseAmount)
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Circle()
                                    .fill(CaloTheme.coral)
                                    .frame(width: 64, height: 64)
                                    .shadow(color: CaloTheme.coral.opacity(0.4), radius: 12, y: 4)
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 24))
                                    .foregroundStyle(.white)
                                Circle()
                                    .stroke(.white.opacity(0.15), lineWidth: 2)
                                    .frame(width: 76, height: 76)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(isAnalyzing)

                    if !foodDescription.isEmpty {
                        // Spacer to balance
                        Color.clear
                            .frame(width: 80, height: 1)
                    }
                }
                .animation(CaloTheme.springAnimation, value: foodDescription.isEmpty)

                Spacer().frame(height: 16)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            if isAnalyzing { pulseAmount = 2.0 }
        }
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
                    isPremium: premiumManager.isPremium
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
        if !premiumManager.canScan() {
            showPaywall = true
            return
        }
        let description = foodDescription.isEmpty ? "Identify this food" : foodDescription
        isAnalyzing = true
        errorMessage = nil
        pulseAmount = 2.0
        Task {
            do {
                let result = try await FoodAnalysisService.analyze(
                    description: description,
                    imageData: imageData
                )
                await MainActor.run {
                    premiumManager.recordScan()
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
