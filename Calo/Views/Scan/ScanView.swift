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
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer()

                    // Preview area
                    if let capturedImage {
                        Image(uiImage: capturedImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 350)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "fork.knife.circle.fill")
                                .font(.system(size: 80))
                                .foregroundStyle(CaloTheme.coral.opacity(0.3))
                            Text("Take a photo of your food")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }
                        .frame(height: 350)
                    }

                    // Text input
                    TextField("Or describe your food...", text: $foodDescription)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)

                    // Analyzing state
                    if isAnalyzing {
                        VStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Analyzing with AI...")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .cardStyle()
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundStyle(.red)
                            .padding(.horizontal)
                    }

                    Spacer()

                    // Scan count
                    if let settings, !settings.isPremium {
                        Text("\(settings.scansRemainingToday) free scans remaining today")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Action buttons
                    HStack(spacing: 16) {
                        // Camera button
                        Button {
                            showCamera = true
                        } label: {
                            Image(systemName: "camera.fill")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .frame(width: 70, height: 70)
                                .background(CaloTheme.coral)
                                .clipShape(Circle())
                                .shadow(color: CaloTheme.coral.opacity(0.4), radius: 8, y: 4)
                        }

                        // Analyze text button
                        if !foodDescription.isEmpty {
                            Button {
                                analyzeFood()
                            } label: {
                                Text("Analyze")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .frame(height: 50)
                                    .frame(maxWidth: .infinity)
                                    .background(CaloTheme.coral)
                                    .clipShape(Capsule())
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    .animation(CaloTheme.springAnimation, value: foodDescription.isEmpty)
                }
            }
            .navigationTitle("Scan")
            .navigationBarTitleDisplayMode(.inline)
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
