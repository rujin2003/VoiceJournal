import SwiftUI

struct RecordingPreview: View {
    let text: String
    let isRecording: Bool
    let audioLevel: CGFloat
    
    @State private var animatedText: String = ""
    @State private var textChangeWorkItem: DispatchWorkItem?
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    LinearGradient(
                        colors: [.vibrantPurple, .vibrantTeal, .vibrantPurple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3 + (audioLevel * 4)
                )
                .blur(radius: audioLevel * 2)
                .scaleEffect(1 + audioLevel * 0.02)
                .animation(.easeInOut(duration: 0.2), value: audioLevel)
            
            VStack(spacing: 20) {
                VoiceWaveformView(audioLevel: audioLevel, isRecording: isRecording)
                    .frame(height: 60)
                    .padding(.horizontal)
                
                ScrollView {
                    Text(animatedText.isEmpty && isRecording ? "Listening..." : animatedText)
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(.primary.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 250)
            .padding()
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .shadow(color: .vibrantPurple.opacity(0.2), radius: 20, y: 10)
        )
        .padding(.horizontal, 24)
        .onChange(of: text) { _, newValue in
            textChangeWorkItem?.cancel()
            animatedText = newValue
        }
    }
}

struct PulsingMicView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.vibrantPurple.opacity(0.3))
                .scaleEffect(isAnimating ? 1.5 : 1.0)
                .opacity(isAnimating ? 0 : 1)
            
            Circle()
                .fill(Color.vibrantPurple.opacity(0.5))
                .scaleEffect(isAnimating ? 1.2 : 1.0)
                .opacity(isAnimating ? 0.5 : 1)
            
            Image(systemName: "mic.fill")
                .font(.system(size: 24))
                .foregroundColor(.white)
        }
        .frame(width: 60, height: 60)
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}
