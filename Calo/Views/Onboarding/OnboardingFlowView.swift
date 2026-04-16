import SwiftUI
import SwiftData

struct OnboardingFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allSettings: [UserSettings]
    @Query private var allOnboarding: [OnboardingData]

    let onComplete: () -> Void

    @State private var currentStep = 0
    @State private var goal = ""
    @State private var activityLevel = ""
    @State private var gender = "male"
    @State private var age = 25
    @State private var heightCm: Double = 170
    @State private var weightKg: Double = 70
    @State private var targetWeightKg: Double = 65
    @State private var weeklyRate: Double = 0.5
    @State private var macros = TDEECalculator.MacroResult(calories: 2000, protein: 150, carbs: 250, fat: 65)

    private var totalSteps: Int {
        showPaceStep ? 8 : 7
    }

    private var showPaceStep: Bool {
        goal == "lose_fat" || goal == "build_muscle"
    }

    var body: some View {
        ZStack {
            CaloTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress bar + back button
                if currentStep > 0 {
                    HStack(spacing: 12) {
                        Button {
                            HapticManager.lightImpact()
                            withAnimation(.easeInOut(duration: 0.35)) {
                                currentStep -= 1
                            }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.body.weight(.medium))
                                .foregroundStyle(.white.opacity(0.7))
                                .frame(width: 36, height: 36)
                                .background(CaloTheme.cardBackground, in: Circle())
                        }
                        .buttonStyle(.plain)

                        // Progress dots
                        HStack(spacing: 6) {
                            ForEach(0..<totalSteps, id: \.self) { step in
                                Capsule()
                                    .fill(step <= currentStep ? CaloTheme.coral : CaloTheme.cardBorder)
                                    .frame(height: 4)
                                    .frame(maxWidth: step == currentStep ? 24 : 12)
                            }
                        }

                        // Spacer to balance back button
                        Color.clear.frame(width: 36, height: 36)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .animation(.easeInOut(duration: 0.35), value: currentStep)
                }

                // Content
                TabView(selection: $currentStep) {
                    WelcomeView(onContinue: { advance() })
                        .tag(0)

                    GoalSelectionView(selectedGoal: $goal, onContinue: { advance() })
                        .tag(1)

                    ActivityLevelView(selectedLevel: $activityLevel, onContinue: { advance() })
                        .tag(2)

                    BodyStatsView(
                        gender: $gender,
                        age: $age,
                        heightCm: $heightCm,
                        weightKg: $weightKg,
                        targetWeightKg: $targetWeightKg,
                        showTargetWeight: showPaceStep,
                        onContinue: { advance() }
                    )
                    .tag(3)

                    if showPaceStep {
                        PaceView(
                            weeklyRate: $weeklyRate,
                            currentWeight: weightKg,
                            targetWeight: targetWeightKg,
                            onContinue: { advance() }
                        )
                        .tag(4)

                        CalculationView(
                            calories: macros.calories,
                            protein: macros.protein,
                            carbs: macros.carbs,
                            fat: macros.fat,
                            onContinue: { advance() }
                        )
                        .tag(5)

                        DemoView(onContinue: { advance() })
                            .tag(6)

                        TrialPaywallView(onContinue: { completeOnboarding() })
                            .tag(7)
                    } else {
                        CalculationView(
                            calories: macros.calories,
                            protein: macros.protein,
                            carbs: macros.carbs,
                            fat: macros.fat,
                            onContinue: { advance() }
                        )
                        .tag(4)

                        DemoView(onContinue: { advance() })
                            .tag(5)

                        TrialPaywallView(onContinue: { completeOnboarding() })
                            .tag(6)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.35), value: currentStep)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func advance() {
        // Calculate macros before showing the calculation screen
        let calcStep = showPaceStep ? 5 : 4
        if currentStep == calcStep - 1 {
            calculateMacros()
        }

        withAnimation(.easeInOut(duration: 0.35)) {
            currentStep += 1
        }
    }

    private func calculateMacros() {
        macros = TDEECalculator.calculate(
            weightKg: weightKg,
            heightCm: heightCm,
            age: age,
            gender: gender,
            activityLevel: activityLevel,
            goal: goal,
            weeklyRate: weeklyRate
        )
    }

    private func completeOnboarding() {
        // Save onboarding data
        let onboarding: OnboardingData
        if let existing = allOnboarding.first {
            onboarding = existing
        } else {
            onboarding = OnboardingData()
            modelContext.insert(onboarding)
        }

        onboarding.hasCompletedOnboarding = true
        onboarding.goal = goal
        onboarding.activityLevel = activityLevel
        onboarding.gender = gender
        onboarding.age = age
        onboarding.heightCm = heightCm
        onboarding.weightKg = weightKg
        onboarding.targetWeightKg = targetWeightKg
        onboarding.weeklyRate = weeklyRate
        onboarding.calculatedCalories = macros.calories
        onboarding.calculatedProtein = macros.protein
        onboarding.calculatedCarbs = macros.carbs
        onboarding.calculatedFat = macros.fat

        // Update UserSettings with calculated goals
        let settings: UserSettings
        if let existing = allSettings.first {
            settings = existing
        } else {
            settings = UserSettings()
            modelContext.insert(settings)
        }

        settings.dailyCalorieGoal = macros.calories
        settings.dailyProteinGoal = macros.protein
        settings.dailyCarbsGoal = macros.carbs
        settings.dailyFatGoal = macros.fat

        HapticManager.success()
        onComplete()
    }
}
