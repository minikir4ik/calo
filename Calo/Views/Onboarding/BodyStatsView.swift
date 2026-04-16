import SwiftUI

struct BodyStatsView: View {
    @Binding var gender: String
    @Binding var age: Int
    @Binding var heightCm: Double
    @Binding var weightKg: Double
    @Binding var targetWeightKg: Double
    let showTargetWeight: Bool
    let onContinue: () -> Void

    @State private var useImperial = false

    private var heightFeet: Int { Int(heightCm / 2.54) / 12 }
    private var heightInches: Int { Int(heightCm / 2.54) % 12 }
    private var weightLbs: Double { weightKg * 2.205 }
    private var targetLbs: Double { targetWeightKg * 2.205 }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer().frame(height: 20)

                Text("Tell us about yourself")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                Spacer().frame(height: 32)

                VStack(spacing: 20) {
                    // Gender
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Gender")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(CaloTheme.subtleText)

                        HStack(spacing: 10) {
                            ForEach(["male", "female", "other"], id: \.self) { g in
                                GenderButton(
                                    label: g.capitalized,
                                    icon: g == "male" ? "figure.stand" : g == "female" ? "figure.stand.dress" : "figure.wave",
                                    isSelected: gender == g
                                ) {
                                    HapticManager.selection()
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        gender = g
                                    }
                                }
                            }
                        }
                    }

                    // Age
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Age")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(CaloTheme.subtleText)

                        HStack {
                            Text("\(age)")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(width: 60, height: 40, alignment: .leading)

                            Slider(value: Binding(
                                get: { Double(age) },
                                set: { age = Int($0) }
                            ), in: 13...100, step: 1)
                            .tint(CaloTheme.coral)
                        }
                        .padding(16)
                        .frame(height: 72)
                        .background(CaloTheme.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(CaloTheme.cardBorder, lineWidth: 0.5)
                        )
                    }

                    // Unit toggle
                    HStack {
                        Spacer()
                        Picker("Units", selection: $useImperial) {
                            Text("Metric").tag(false)
                            Text("Imperial").tag(true)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 180)
                    }

                    // Height
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Height")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(CaloTheme.subtleText)

                        HStack {
                            if useImperial {
                                Text("\(heightFeet)'\(heightInches)\"")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .frame(width: 110, height: 40, alignment: .leading)
                            } else {
                                Text("\(Int(heightCm)) cm")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .frame(width: 110, height: 40, alignment: .leading)
                            }

                            Slider(value: $heightCm, in: 120...230, step: 1)
                                .tint(CaloTheme.coral)
                        }
                        .padding(16)
                        .frame(height: 72)
                        .background(CaloTheme.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(CaloTheme.cardBorder, lineWidth: 0.5)
                        )
                    }
                    .animation(nil, value: heightCm)

                    // Weight
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Weight")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(CaloTheme.subtleText)

                        HStack {
                            if useImperial {
                                Text("\(Int(weightLbs)) lbs")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .frame(width: 110, height: 40, alignment: .leading)
                            } else {
                                Text("\(String(format: "%.1f", weightKg)) kg")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .frame(width: 110, height: 40, alignment: .leading)
                            }

                            Slider(
                                value: $weightKg,
                                in: 30...250,
                                step: 0.5
                            )
                            .tint(CaloTheme.coral)
                        }
                        .padding(16)
                        .frame(height: 72)
                        .background(CaloTheme.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(CaloTheme.cardBorder, lineWidth: 0.5)
                        )
                    }
                    .animation(nil, value: weightKg)

                    // Target weight
                    if showTargetWeight {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Target weight")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(CaloTheme.subtleText)

                            HStack {
                                if useImperial {
                                    Text("\(Int(targetLbs)) lbs")
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white)
                                        .frame(width: 110, height: 40, alignment: .leading)
                                } else {
                                    Text("\(String(format: "%.1f", targetWeightKg)) kg")
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white)
                                        .frame(width: 110, height: 40, alignment: .leading)
                                }

                                Slider(
                                    value: $targetWeightKg,
                                    in: 30...250,
                                    step: 0.5
                                )
                                .tint(CaloTheme.coral)
                            }
                            .padding(16)
                            .frame(height: 72)
                            .background(CaloTheme.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(CaloTheme.cardBorder, lineWidth: 0.5)
                            )
                        }
                        .animation(nil, value: targetWeightKg)
                        .transition(.opacity)
                    }
                }
                .padding(.horizontal, 24)

                Spacer().frame(height: 32)

                Button {
                    HapticManager.mediumImpact()
                    onContinue()
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(CaloTheme.coral, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)

                Spacer().frame(height: 50)
            }
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .background(Color.black.ignoresSafeArea())
    }
}

private struct GenderButton: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(isSelected ? CaloTheme.coral : .white.opacity(0.5))
                Text(label)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(isSelected ? .white : CaloTheme.subtleText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(CaloTheme.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? CaloTheme.coral : CaloTheme.cardBorder, lineWidth: isSelected ? 1.5 : 0.5)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
