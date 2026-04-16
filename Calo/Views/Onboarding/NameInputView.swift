import SwiftUI

struct NameInputView: View {
    @Binding var name: String
    let onContinue: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 56))
                    .foregroundStyle(CaloTheme.coral.opacity(0.6))

                Text("What\u{2019}s your name?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                Text("We\u{2019}ll personalize your experience")
                    .font(.subheadline)
                    .foregroundStyle(CaloTheme.subtleText)
            }

            Spacer().frame(height: 40)

            TextField("Your first name", text: $name)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(CaloTheme.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(isFocused ? CaloTheme.coral : CaloTheme.cardBorder, lineWidth: isFocused ? 1.5 : 0.5)
                        )
                )
                .padding(.horizontal, 32)
                .focused($isFocused)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.continue)
                .onSubmit {
                    if !name.trimmingCharacters(in: .whitespaces).isEmpty {
                        HapticManager.mediumImpact()
                        onContinue()
                    }
                }

            Spacer()

            if !name.trimmingCharacters(in: .whitespaces).isEmpty {
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
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            Spacer().frame(height: 50)
        }
        .animation(.easeInOut(duration: 0.35), value: name.isEmpty)
        .background(Color.black.ignoresSafeArea())
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { isFocused = false }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isFocused = true
            }
        }
    }
}
