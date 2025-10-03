import SwiftUI

import SwiftUI

struct RecordingPreview: View {
    let text: String
    let isRecording: Bool
    let audioLevel: CGFloat
    
    @State private var animatedText: String = ""
    @State private var textChangeWorkItem: DispatchWorkItem?
    @State private var phase: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    LinearGradient(
                        colors: [
                            .vibrantPurple,
                            .vibrantTeal,
                            .cyan,
                            .vibrantPurple.opacity(0.7),
                            .vibrantTeal.opacity(0.8),
                            .cyan.opacity(0.6),
                            .vibrantPurple
                        ],
                        startPoint: UnitPoint(x: 0.5 + cos(phase) * 0.5, y: 0.5 + sin(phase) * 0.5),
                        endPoint: UnitPoint(x: 0.5 + cos(phase + .pi) * 0.5, y: 0.5 + sin(phase + .pi) * 0.5)
                    ),
                    lineWidth: 3 + (audioLevel * 3)
                )
                .blur(radius: 2 + (audioLevel * 2))
                .scaleEffect(pulseScale)
                .opacity(0.9)
            
         
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    RadialGradient(
                        colors: [
                            .vibrantPurple.opacity(0.4),
                            .vibrantTeal.opacity(0.3),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    ),
                    lineWidth: 2
                )
                .blur(radius: 8)
                .scaleEffect(1 + audioLevel * 0.02)
            
            VStack(spacing: 20) {
                ScrollView {
                    Text(animatedText.isEmpty && isRecording ? "Listening..." : animatedText)
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(.primary.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.top, 40)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 250)
            .padding()
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .shadow(color: .vibrantPurple.opacity(0.15), radius: 20, y: 10)
        )
        .padding(.horizontal, 24)
        .onChange(of: text) { _, newValue in
            textChangeWorkItem?.cancel()
            animatedText = newValue
        }
        .onAppear {
            startBorderAnimation()
            startPulseAnimation()
        }
    }
    
    private func startBorderAnimation() {
        withAnimation(
            .linear(duration: 4.0)
            .repeatForever(autoreverses: false)
        ) {
            phase = .pi * 2
        }
    }
    
    private func startPulseAnimation() {
        withAnimation(
            .easeInOut(duration: 2.0)
            .repeatForever(autoreverses: true)
        ) {
            pulseScale = 1.01
        }
    }
}
