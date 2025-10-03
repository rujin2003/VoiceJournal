import SwiftUI
import AVFoundation

struct JournalView: View {
    @Environment(\.modelContext) private var modelContext
    
    @State private var isRecording = false
    @State private var speechRecognizer = SpeechRecognizer()
    @State private var transcription = ""
    @State private var audioLevel: CGFloat = 0.0
    
    @State private var showNotePreview = false
    @State private var preloadedAttributedString: NSAttributedString?
    @State private var showEditor = false
    
    @State private var selectedMood: String = "😊"
    private let moods = ["😊", "🤩", "🥰", "😐", "😢", "😠", "🤔", "😎"]

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.appBackgroundStart, Color.appBackgroundEnd]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                HeaderView()
                
                if isRecording {
                    RecordingPreview(
                        text: transcription,
                        isRecording: isRecording,
                        audioLevel: audioLevel
                    )
                } else if showNotePreview, let content = preloadedAttributedString {
                    NotePreviewView(content: content, action: { showEditor = true })
                    
                    MoodSelectorView(moods: moods, selectedMood: $selectedMood)
                    
                    DiscardButtonView(action: discardTranscription)
                        .padding(.bottom, 20)
                } else {
                    TranscriptionPlaceholderView()
                }
                
                Spacer()
                
                RecordingButton(
                    isRecording: $isRecording,
                    audioLevel: $audioLevel,
                    action: toggleRecording
                )
            }
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .onAppear(perform: setupSpeechRecognizer)
        .sheet(isPresented: $showEditor) {
            if let preloadedContent = preloadedAttributedString {
                JournalNoteEditorView(preloadedAttributedString: preloadedContent, mood: selectedMood)
            }
        }
        .onChange(of: showEditor) { _, isShowing in
            if !isShowing {
                discardTranscription()
            }
        }
    }
    
    private func setupSpeechRecognizer() {
        speechRecognizer.onTranscriptionUpdate = { text in self.transcription = text }
        speechRecognizer.onAudioLevelUpdate = { level in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5, blendDuration: 0)) {
                self.audioLevel = CGFloat(level)
            }
        }
    }
    
    private func toggleRecording() {
        isRecording.toggle()
        
        if isRecording {
            discardTranscription()
            speechRecognizer.startTranscribing()
        } else {
            speechRecognizer.stopTranscribing()
            if !transcription.isEmpty {
                prepareNoteForPreview()
            }
        }
    }
    
    private func prepareNoteForPreview() {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18),
            .foregroundColor: UIColor.label
        ]
        self.preloadedAttributedString = NSAttributedString(string: transcription, attributes: attributes)
        self.showNotePreview = true
    }
    
    private func discardTranscription() {
        transcription = ""
        preloadedAttributedString = nil
        showNotePreview = false
    }
}



struct VoiceWaveformView: View {
    let audioLevel: CGFloat
    let isRecording: Bool
    
    @State private var barHeights: [CGFloat] = Array(repeating: 0.2, count: 40)
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<40, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [.vibrantPurple, .vibrantTeal],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 3, height: max(4, barHeights[index] * 50))
                    .animation(.easeInOut(duration: 0.15), value: barHeights[index])
            }
        }
        .onAppear {
            startWaveAnimation()
        }
    }
    
    private func startWaveAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if isRecording {
                for i in 0..<barHeights.count {
                    let baseHeight = CGFloat.random(in: 0.3...0.7)
                    let audioInfluence = audioLevel * 0.5
                    barHeights[i] = min(1.0, baseHeight + audioInfluence)
                }
            } else {
                for i in 0..<barHeights.count {
                    barHeights[i] = 0.2
                }
            }
        }
    }
}

struct RecordingButton: View {
    @Binding var isRecording: Bool
    @Binding var audioLevel: CGFloat
    let action: () -> Void
     
    var body: some View {
        Button(action: action) {
            FlowerIcon(isRecording: isRecording, audioLevel: audioLevel)
                .frame(width: 80, height: 80)
        }
        .padding(.bottom, 40)
    }
}

struct FlowerIcon: View {
    let isRecording: Bool
    let audioLevel: CGFloat
    @State private var rotation: Double = 0
    
    let purpleShades = [
        Color(red: 0.7, green: 0.5, blue: 0.9),
        Color(red: 0.6, green: 0.4, blue: 0.85),
        Color(red: 0.5, green: 0.3, blue: 0.8),
        Color(red: 0.65, green: 0.45, blue: 0.88),
        Color(red: 0.55, green: 0.35, blue: 0.82),
        Color(red: 0.75, green: 0.55, blue: 0.92),
        Color(red: 0.6, green: 0.38, blue: 0.86),
        Color(red: 0.68, green: 0.48, blue: 0.9)
    ]
    
    var body: some View {
        ZStack {
            ForEach(0..<8) { index in
                RoundedRectangle(cornerRadius: 12)
                    .fill(purpleShades[index])
                    .frame(width: 32, height: 38)
                    .offset(y: -20)
                    .rotationEffect(.degrees(Double(index) * 45))
            }
            
            if isRecording {
                Circle()
                    .fill(Color.white)
                    .frame(width: 20, height: 20)
                
                Circle()
                    .stroke(Color.vibrantPurple, lineWidth: 2)
                    .frame(width: 28, height: 28)
            }
        }
        .rotationEffect(.degrees(rotation))
        .scaleEffect(isRecording ? 1 + (audioLevel * 0.15) : 1.0)
        .shadow(color: .vibrantPurple.opacity(isRecording ? 0.4 : 0.2), radius: 15, y: 8)
        .onChange(of: isRecording) { _, newValue in
            if newValue {
                withAnimation(
                    .linear(duration: 3.0)
                    .repeatForever(autoreverses: false)
                ) {
                    rotation = 360
                }
            } else {
                withAnimation(.easeOut(duration: 0.5)) {
                    rotation = 0
                }
            }
        }
    }
}

struct TranscriptionPlaceholderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.vibrantPurple.opacity(0.6))
            
            Text("Tap to start recording")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.primary.opacity(0.7))
            
            Text("Your thoughts will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 80)
    }
}

struct NotePreviewView: View {
    let content: NSAttributedString
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your Journal Entry")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "pencil.circle.fill")
                    .font(.title3)
                    .foregroundColor(.vibrantPurple)
            }
            
            Divider()
            
            Text(AttributedString(content))
                .lineLimit(6)
                .multilineTextAlignment(.leading)
                .foregroundColor(.primary.opacity(0.8))
            
            Spacer()
            
            HStack {
                Spacer()
                Text("Tap to edit & format")
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundColor(.vibrantPurple)
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundColor(.vibrantPurple)
            }
        }
        .padding(20)
        .frame(height: 220)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.08), radius: 15, y: 8)
        )
        .padding(.horizontal, 24)
        .onTapGesture(perform: action)
    }
}

struct DiscardButtonView: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.counterclockwise")
                Text("Start Over")
            }
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.secondary)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.gray.opacity(0.15))
            )
        }
    }
}

struct HeaderView: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Journal")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(Date().formatted(.dateTime.weekday(.wide).day().month(.wide)))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 60)
    }
}

struct MoodSelectorView: View {
    let moods: [String]
    @Binding var selectedMood: String
    
    var body: some View {
        VStack(spacing: 12) {
            Text("How are you feeling?")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fontWeight(.medium)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(moods, id: \.self) { mood in
                        Button(action: {
                            selectedMood = mood
                        }) {
                            Text(mood)
                                .font(.system(size: 40))
                                .padding(12)
                                .background(
                                    Circle()
                                        .fill(selectedMood == mood ? Color.vibrantPurple.opacity(0.15) : Color.clear)
                                )
                                .scaleEffect(selectedMood == mood ? 1.15 : 1.0)
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
        }
        .padding(.vertical, 8)
    }
}
