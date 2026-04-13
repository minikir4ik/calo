import SwiftUI
import SwiftData
import AVFoundation

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
        ZStack {
            // Camera preview / captured image / black background
            if let capturedImage {
                Image(uiImage: capturedImage)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .transition(.opacity)
            } else {
                Color.black
                    .ignoresSafeArea()

                // Camera placeholder
                VStack(spacing: 16) {
                    Image(systemName: "viewfinder")
                        .font(.system(size: 72, weight: .ultraLight))
                        .foregroundStyle(.white.opacity(0.2))
                }
            }

            // Dark gradient overlay at top and bottom for legibility
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [.black.opacity(0.7), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 120)

                Spacer()

                LinearGradient(
                    colors: [.clear, .black.opacity(0.85)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 260)
            }
            .ignoresSafeArea()

            // Content overlay
            VStack(spacing: 0) {
                // Top bar: scan counter
                HStack {
                    if let settings, !settings.isPremium {
                        Text("\(settings.scansRemainingToday) scans remaining")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.white.opacity(0.9))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial.opacity(0.6))
                            .clipShape(Capsule())
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                Spacer()

                // Analyzing indicator
                if isAnalyzing {
                    VStack(spacing: 10) {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.2)
                        Text("Analyzing...")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    .padding(20)
                    .background(.ultraThinMaterial.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }

                Spacer()

                // Bottom controls
                VStack(spacing: 16) {
                    // Text field
                    HStack(spacing: 10) {
                        Image(systemName: "pencil")
                            .foregroundStyle(.white.opacity(0.5))
                        TextField("Or describe your food...", text: $foodDescription)
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .padding(.horizontal, 20)

                    // Buttons row
                    HStack(spacing: 20) {
                        // Analyze text button (left)
                        if !foodDescription.isEmpty {
                            Button {
                                analyzeFood()
                            } label: {
                                Text("Analyze")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .frame(height: 44)
                                    .frame(maxWidth: .infinity)
                                    .background(CaloTheme.coral.opacity(0.9))
                                    .clipShape(Capsule())
                            }
                            .transition(.scale.combined(with: .opacity))
                        }

                        // Capture button (center)
                        Button {
                            showCamera = true
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(CaloTheme.coral)
                                    .frame(width: 72, height: 72)
                                Circle()
                                    .stroke(.white.opacity(0.3), lineWidth: 3)
                                    .frame(width: 82, height: 82)
                            }
                        }

                        // Spacer to keep capture button centered when analyze button is hidden
                        if !foodDescription.isEmpty {
                            Color.clear
                                .frame(height: 44)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, 20)
                    .animation(CaloTheme.springAnimation, value: foodDescription.isEmpty)
                }
                .padding(.bottom, 16)
            }
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
