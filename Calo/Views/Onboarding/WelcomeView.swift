import SwiftUI

struct WelcomeView: View {
    let onContinue: () -> Void

    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var particlePhase: CGFloat = 0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Subtle particle dots
            Canvas { context, size in
                for i in 0..<30 {
                    let seed = Double(i)
                    let x = (sin(seed * 1.3 + Double(particlePhase) * 0.5) * 0.5 + 0.5) * size.width
                    let y = (cos(seed * 0.9 + Double(particlePhase) * 0.3) * 0.5 + 0.5) * size.height
                    let opacity = sin(seed * 2.1 + Double(particlePhase)) * 0.15 + 0.15
                    let radius: CGFloat = CGFloat(sin(seed * 1.7) * 1.5 + 2.0)
                    context.opacity = opacity
                    context.fill(
                        Path(ellipseIn: CGRect(x: x, y: y, width: radius, height: radius)),
                        with: .color(CaloTheme.coral)
                    )
                }
            }
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
                    particlePhase = .pi * 4
                }
            }

            VStack(spacing: 0) {
                Spacer()

                // Logo
                ZStack {
                    Circle()
                        .fill(CaloTheme.coral.opacity(0.15))
                        .frame(width: 160, height: 160)
                        .blur(radius: 25)

                    Image(systemName: "flame.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [CaloTheme.coral, CaloTheme.coral.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                Spacer().frame(height: 32)

                // App name
                Text("Calo")
                    .font(.system(size: 48, weight: .bold, design: .default))
                    .foregroundStyle(.white)
                    .opacity(textOpacity)

                Spacer().frame(height: 12)

                // Subtitle
                Text("AI-powered nutrition that adapts to you")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .opacity(textOpacity)

                Spacer()

                // Button
                Button {
                    HapticManager.mediumImpact()
                    onContinue()
                } label: {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(CaloTheme.coral, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: CaloTheme.coral.opacity(0.4), radius: 16, y: 6)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .opacity(buttonOpacity)

                Spacer().frame(height: 50)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.5)) {
                textOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.8)) {
                buttonOpacity = 1.0
            }
        }
    }
}
