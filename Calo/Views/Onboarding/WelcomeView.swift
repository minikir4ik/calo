import SwiftUI

struct WelcomeView: View {
    let onContinue: () -> Void

    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var glowPulse: Bool = false
    @State private var particlePhase: CGFloat = 0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Radial glow behind logo
            RadialGradient(
                colors: [CaloTheme.coral.opacity(0.25), Color.clear],
                center: .center,
                startRadius: 10,
                endRadius: 250
            )
            .scaleEffect(glowPulse ? 1.15 : 1.0)
            .offset(y: -60)
            .ignoresSafeArea()

            // Floating particle dots
            Canvas { context, size in
                for i in 0..<40 {
                    let seed = Double(i)
                    let x = (sin(seed * 1.3 + Double(particlePhase) * 0.5) * 0.5 + 0.5) * size.width
                    let y = (cos(seed * 0.9 + Double(particlePhase) * 0.3) * 0.5 + 0.5) * size.height
                    let opacity = sin(seed * 2.1 + Double(particlePhase)) * 0.2 + 0.2
                    let radius: CGFloat = CGFloat(sin(seed * 1.7) * 1.5 + 2.5)
                    context.opacity = opacity
                    context.fill(
                        Path(ellipseIn: CGRect(x: x, y: y, width: radius, height: radius)),
                        with: .color(CaloTheme.coral)
                    )
                }
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo
                ZStack {
                    Circle()
                        .fill(CaloTheme.coral.opacity(0.2))
                        .frame(width: 180, height: 180)
                        .blur(radius: 30)

                    Image(systemName: "flame.fill")
                        .font(.system(size: 88))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white.opacity(0.95), CaloTheme.coral],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: CaloTheme.coral.opacity(0.6), radius: 20, y: 8)
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                Spacer().frame(height: 28)

                // App name
                Text("Calo")
                    .font(.system(size: 52, weight: .bold, design: .default))
                    .foregroundStyle(.white)
                    .opacity(textOpacity)

                Spacer().frame(height: 10)

                // Subtitle
                Text("AI-powered nutrition\nthat adapts to you")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
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
                        .shadow(color: CaloTheme.coral.opacity(0.5), radius: 20, y: 8)
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
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
            withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
                particlePhase = .pi * 4
            }
        }
    }
}
