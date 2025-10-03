import SwiftUI
import SwiftData
import AVFoundation


struct JournalView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var isRecording = false
    @State private var speechRecognizer = SpeechRecognizer()
    @State private var transcription = ""
    @State private var audioLevel: CGFloat = 0.0
    
    @State private var showNotePreview = false
    @State private var preloadedAttributedString: NSAttributedString?
    @State private var editedAttributedString: NSAttributedString?
    @State private var showEditor = false
    @State private var generatedTitle: String = ""
    @State private var editedTitle: String = ""
    
    @State private var selectedMood: String = "😊"
    @State private var availableMoods: [String] = ["😊", "🤩", "🥰", "😐", "😢", "😠", "🤔", "😎"]
    @State private var showEmojiPicker = false

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
                    NotePreviewView(title: editedTitle.isEmpty ? generatedTitle : editedTitle, content: editedAttributedString as? NSAttributedString ?? content, action: { showEditor = true })
                    
                    MoodSelectorView(
                        moods: availableMoods,
                        selectedMood: $selectedMood,
                        showEmojiPicker: $showEmojiPicker
                    )
                    
                    SaveNewJournalButton(action: saveNewJournal)
                        .disabled((editedAttributedString ?? preloadedAttributedString) == nil)
                        .padding(.bottom, 6)
                    
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
            
      
            if showEmojiPicker {
                EmojiPickerView(
                    availableMoods: $availableMoods,
                    showEmojiPicker: $showEmojiPicker
                )
            }
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .onAppear(perform: setupSpeechRecognizer)
        .sheet(isPresented: $showEditor) {
            if let preloadedContent = preloadedAttributedString {
                JournalNoteEditorView(
                    preloadedAttributedString: preloadedContent,
                    title: editedTitle.isEmpty ? generatedTitle : editedTitle,
                    mood: selectedMood,
                    onDismiss: {
                        showEditor = false
                    },
                    onSave: {
                        // No-op: saving handled in JournalView for creation flow
                    },
                    onUpdate: { updatedContent, updatedTitle in
                        self.editedAttributedString = updatedContent
                        self.editedTitle = updatedTitle
                    }
                )
            }
        }
    }

       
 
       private func extractTitleFromContent(_ content: String) -> String {
           let words = content.split(separator: " ")
           let titleWords = words.prefix(6)
           return titleWords.joined(separator: " ")
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
        self.generatedTitle = extractTitleFromContent(transcription)
        self.showNotePreview = true
        self.editedAttributedString = preloadedAttributedString
        self.editedTitle = generatedTitle
    }
    
    private func discardTranscription() {
        transcription = ""
        preloadedAttributedString = nil
        editedAttributedString = nil
        editedTitle = ""
        showNotePreview = false
    }

    private func saveNewJournal() {
        guard let content = (editedAttributedString ?? preloadedAttributedString) else { return }
        let titleToUse = (editedTitle.isEmpty ? generatedTitle : editedTitle)
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: content, requiringSecureCoding: false)
            let dataString = data.base64EncodedString()

            let newNote = JournalNote(
                title: titleToUse.isEmpty ? extractTitleFromContent(content.string) : titleToUse,
                noteContent: dataString,
                mood: selectedMood,
                colorString: Color.journalColors.randomElement()?.description ?? "vibrantPurple"
            )
            modelContext.insert(newNote)

            // Update streak
            try updateStreakAfterCreate()

            try modelContext.save()

            // Notify HomeView to show confetti
            NotificationCenter.default.post(name: .journalSaved, object: nil)

            // Reset and go back
            discardTranscription()
            dismiss()
        } catch {
            print("Error saving new journal: \(error)")
        }
    }

    private func updateStreakAfterCreate() throws {
        let streakFetchDescriptor = FetchDescriptor<Streak>()
        var streaks = try modelContext.fetch(streakFetchDescriptor)
        let streak: Streak
        if let existing = streaks.first {
            streak = existing
        } else {
            streak = Streak()
            modelContext.insert(streak)
            streaks.append(streak)
        }
        streak.numberOfEntries += 1

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        if let lastDate = streak.lastEntryDate {
            let lastEntryDay = calendar.startOfDay(for: lastDate)
            if !calendar.isDate(today, inSameDayAs: lastEntryDay) {
                if let yesterday = calendar.date(byAdding: .day, value: -1, to: today), calendar.isDate(lastEntryDay, inSameDayAs: yesterday) {
                    streak.currentStreak += 1
                } else {
                    streak.currentStreak = 1
                }
            }
        } else {
            streak.currentStreak = 1
        }
        streak.lastEntryDate = .now
        if streak.currentStreak > streak.longestStreak { streak.longestStreak = streak.currentStreak }
    }
}

struct EmojiPickerView: View {
    @Binding var availableMoods: [String]
    @Binding var showEmojiPicker: Bool
    @State private var newEmoji: String = ""
    
    let emojiSuggestions = [
        "😀", "😃", "😄", "😁", "😅", "😂", "🤣", "😊", "😇",
        "🙂", "🙃", "😉", "😌", "😍", "🥰", "😘", "😗", "😙",
        "😚", "😋", "😛", "😝", "😜", "🤪", "🤨", "🧐", "🤓",
        "😎", "🤩", "🥳", "😏", "😒", "😞", "😔", "😟", "😕",
        "🙁", "☹️", "😣", "😖", "😫", "😩", "🥺", "😢", "😭",
        "😤", "😠", "😡", "🤬", "🤯", "😳", "🥵", "🥶", "😱",
        "😨", "😰", "😥", "😓", "🤗", "🤔", "🤭", "🤫", "🤥",
        "😶", "😐", "😑", "😬", "🙄", "😯", "😦", "😧", "😮"
    ]
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    showEmojiPicker = false
                }
            
            VStack(spacing: 0) {
              
                HStack {
                    Text("Add Custom Emoji")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    Button(action: { showEmojiPicker = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.title3)
                    }
                }
                .padding()
                .background(Color.vibrantPurple.opacity(0.1))
                
                Divider()
                
                
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 6), spacing: 12) {
                        ForEach(emojiSuggestions, id: \.self) { emoji in
                            Button(action: {
                                if !availableMoods.contains(emoji) {
                                    availableMoods.append(emoji)
                                }
                                showEmojiPicker = false
                            }) {
                                Text(emoji)
                                    .font(.system(size: 32))
                                    .padding(8)
                                    .background(
                                        Circle()
                                            .fill(availableMoods.contains(emoji) ? Color.green.opacity(0.2) : Color.clear)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(availableMoods.contains(emoji) ? Color.green : Color.clear, lineWidth: 2)
                                    )
                            }
                        }
                    }
                    .padding()
                }
                .frame(maxHeight: 400)
            }
            .frame(maxWidth: 350)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.3), radius: 20)
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
                RoundedRectangle(cornerRadius: 15)
                    .fill(purpleShades[index])
                    .frame(width: 32, height: 40).padding(5)
                    .offset(y: -20)
                    .rotationEffect(.degrees(Double(index) * 45))
            }
            
            if isRecording {
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
    let title: String
    let content: NSAttributedString
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
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

struct SaveNewJournalButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                Text("Save Journal")
            }
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.vibrantPurple, Color.vibrantPurple.opacity(0.8)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(14)
            .shadow(color: Color.vibrantPurple.opacity(0.3), radius: 8, y: 6)
        }
    }
}

struct HeaderView: View {
    @Environment(\.dismiss) private var dismiss

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
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "calendar.day.timeline.left")
                    .font(.title2)
                    .foregroundColor(Color.vibrantPurple.opacity(0.6))
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 10)
    }
}

struct MoodSelectorView: View {
    let moods: [String]
    @Binding var selectedMood: String
    @Binding var showEmojiPicker: Bool
    
    var body: some View {
        VStack(spacing: 10) {
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
                                .font(.system(size: 34))
                                .padding(12)
                                .background(
                                    Circle()
                                        .fill(selectedMood == mood ? Color.purple.opacity(0.2) : Color.clear)
                                )
                                .scaleEffect(selectedMood == mood ? 1.2 : 1.0)
                                .animation(.spring(), value: selectedMood)
                        }
                    }
                    
                 
                    Button(action: {
                        showEmojiPicker = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 34))
                            .foregroundColor(.vibrantPurple)
                            .padding(12)
                            .background(
                                Circle()
                                    .fill(Color.purple.opacity(0.1))
                            )
                    }
                }
                .padding(.horizontal, 16)
            }
            .frame(height: 65)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.purple.opacity(0.1))
                .shadow(color: Color.purple.opacity(0.2), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 24)
    }
}
