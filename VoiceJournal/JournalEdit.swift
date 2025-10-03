import SwiftUI
import SwiftData


struct RichTextView: UIViewRepresentable {
   
    @Binding var attributedText: NSMutableAttributedString
    @Binding var selectedRange: NSRange
    @Binding var typingAttributes: [NSAttributedString.Key: Any]
    @Binding var isEmpty: Bool
    
   
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = true
        textView.isScrollEnabled = true
        textView.delegate = context.coordinator
        textView.font = UIFont.systemFont(ofSize: 18)
        textView.typingAttributes = typingAttributes
        textView.backgroundColor = .clear
        textView.textColor = UIColor.label
        
        textView.attributedText = attributedText
        textView.selectedRange = selectedRange
        
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        
        if context.coordinator.isUpdating { return }
        
        if !uiView.attributedText.isEqual(to: attributedText) {
            let previousSelectedRange = uiView.selectedRange
            context.coordinator.isUpdating = true
            uiView.attributedText = attributedText
   
            if previousSelectedRange.location <= uiView.attributedText.length {
                let maxRange = min(previousSelectedRange.location + previousSelectedRange.length, uiView.attributedText.length)
                let validRange = NSRange(location: previousSelectedRange.location, length: maxRange - previousSelectedRange.location)
                uiView.selectedRange = validRange
            }
            context.coordinator.isUpdating = false
        }

        if !NSEqualRanges(uiView.selectedRange, selectedRange) &&
           selectedRange.location <= uiView.attributedText.length &&
           NSMaxRange(selectedRange) <= uiView.attributedText.length {
            context.coordinator.isUpdating = true
            uiView.selectedRange = selectedRange
            context.coordinator.isUpdating = false
        }
        
        if !NSDictionary(dictionary: uiView.typingAttributes).isEqual(to: typingAttributes) {
            uiView.typingAttributes = typingAttributes
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: RichTextView
        var isUpdating = false

        init(_ parent: RichTextView) { self.parent = parent }

        func textViewDidChange(_ textView: UITextView) {
            guard !isUpdating else { return }
            isUpdating = true
            defer { isUpdating = false }
        
            parent.attributedText = NSMutableAttributedString(attributedString: textView.attributedText)
            parent.isEmpty = textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            parent.typingAttributes = textView.typingAttributes
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            guard !isUpdating else { return }
            isUpdating = true
            defer { isUpdating = false }
            
            parent.selectedRange = textView.selectedRange
            
            if textView.selectedRange.length == 0 && textView.selectedRange.location > 0 {
                let location = min(textView.selectedRange.location - 1, textView.attributedText.length - 1)
                if location >= 0 {
                    let attributes = textView.attributedText.attributes(at: location, effectiveRange: nil)
                    parent.typingAttributes = attributes
                }
            }
        }
    }
}


struct JournalNoteEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var attributedText: NSMutableAttributedString
    @State private var selectedRange = NSRange(location: 0, length: 0)
    @State private var typingAttributes: [NSAttributedString.Key: Any]
    @State private var isEmpty = true
    @State private var hasUnsavedChanges = false

    @State private var selectedColor: Color
    @State private var showFontPicker = false
    @State private var showFontSizePicker = false
    
    private var existingNote: JournalNote?
    private var mood: String
    @State private var noteTitle: String
    
    init(preloadedAttributedString: NSAttributedString, mood: String) {
        self._attributedText = State(initialValue: NSMutableAttributedString(attributedString: preloadedAttributedString))
        self.existingNote = nil
        self.mood = mood
        self._noteTitle = State(initialValue: "")
        
        let initialColor = Color(uiColor: preloadedAttributedString.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor ?? .label)
        self._selectedColor = State(initialValue: initialColor)
        
        let initialTypingAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18),
            .foregroundColor: UIColor.label
        ]
        self._typingAttributes = State(initialValue: initialTypingAttributes)
    }
    
    private func saveNote() {
        if noteTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            noteTitle = generateSmartTitle(from: attributedText.string)
        }
        
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: attributedText, requiringSecureCoding: false)
            let dataString = data.base64EncodedString()

            if let note = existingNote {
                note.title = noteTitle
                note.noteContent = dataString
                note.createdAt = .now
            } else {
                let newNote = JournalNote(
                    title: noteTitle,
                    noteContent: dataString,
                    mood: mood,
                    colorString: Color.journalColors.randomElement()?.description ?? "vibrantPurple"
                )
                modelContext.insert(newNote)
            }

            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving note: \(error)")
        }
    }
    
    private func generateSmartTitle(from plainText: String) -> String {
        let firstLine = plainText.components(separatedBy: .newlines).first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty })
        return String(firstLine?.prefix(40) ?? "Journal Entry")
    }

    private let fonts: [UIFont] = [
        UIFont.systemFont(ofSize: 18),
        UIFont(name: "Times New Roman", size: 18) ?? UIFont.systemFont(ofSize: 18),
        UIFont(name: "Helvetica", size: 18) ?? UIFont.systemFont(ofSize: 18),
        UIFont(name: "Courier", size: 18) ?? UIFont.systemFont(ofSize: 18)
    ]

    private let fontSizes: [CGFloat] = [12, 14, 16, 18, 20, 22, 24, 28, 32, 36, 42, 48]

    var body: some View {
     
        ZStack {
            Color.appBackground.edgesIgnoringSafeArea(.all)
            
            VStack {
                headerView
                textEditorView
                toolbarView
            }

            if showFontPicker {
                fontPickerOverlay
            }
            
            if showFontSizePicker {
                fontSizePickerOverlay
            }
        }
        .onAppear {
            isEmpty = attributedText.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        .onChange(of: attributedText) {
            hasUnsavedChanges = true
            isEmpty = attributedText.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        .navigationBarHidden(true)
        .animation(.easeInOut(duration: 0.3), value: showFontPicker)
        .animation(.easeInOut(duration: 0.3), value: showFontSizePicker)
    }

    private var headerView: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
            }
            Spacer()
            TextField("Title", text: $noteTitle)
                 .multilineTextAlignment(.center)
            Spacer()
            Button("Save", action: saveNote)
        }
        .padding()
    }

    private var textEditorView: some View {
        RichTextView(
            attributedText: $attributedText,
            selectedRange: $selectedRange,
            typingAttributes: $typingAttributes,
            isEmpty: $isEmpty
        )
    }

   
    private var toolbarView: some View {
        HStack(spacing: 20) {
            Button(action: {
                showFontPicker.toggle()
                showFontSizePicker = false
            }) {
                Image(systemName: "textformat")
                    .foregroundColor(.vibrantPurple)
            }
            
            Button(action: {
                showFontSizePicker.toggle()
                showFontPicker = false
            }) {
                HStack(spacing: 2) {
                    Text("a")
                        .font(.system(size: 12))
                        .foregroundColor(.vibrantPurple)
                    Text("A")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.vibrantPurple)
                }
            }
            
            formatButton(action: toggleBold, icon: "bold", isActive: isBoldActive())
            formatButton(action: toggleItalic, icon: "italic", isActive: isItalicActive())
            formatButton(action: toggleUnderline, icon: "underline", isActive: isUnderlineActive())

            ColorPicker("", selection: $selectedColor, supportsOpacity: false)
                .labelsHidden()
                .frame(width: 30, height: 30)
                .onChange(of: selectedColor) { newColor in
                    applyAttribute(.foregroundColor, value: UIColor(newColor))
                }

            Button(action: addBulletPoints) {
                Image(systemName: "list.bullet")
                    .foregroundColor(.vibrantPurple)
            }
        }
        .padding()
        .background(Color.appBackground.opacity(0.8))
    }
    
    private func formatButton(action: @escaping () -> Void, icon: String, isActive: Bool) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .foregroundColor(.vibrantPurple)
                .padding(8)
                .background(isActive ? Color.vibrantPurple.opacity(0.2) : Color.clear)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isActive ? Color.vibrantPurple : Color.clear, lineWidth: 1)
                )
        }
    }
    
    // MARK: - Overlay Views
    
    private var fontPickerOverlay: some View {
        VStack {
            Spacer()
            VStack(spacing: 0) {
                ForEach(fonts, id: \.fontName) { font in
                    Button(action: {
                        applyFontFamily(font)
                        showFontPicker = false
                    }) {
                        Text(font.fontName.replacingOccurrences(of: "-", with: " "))
                            .foregroundColor(.primary)
                            .font(Font(font as CTFont))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    if font != fonts.last {
                        Divider().background(Color.gray.opacity(0.3))
                    }
                }
            }
            .background(Color.appBackground)
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.3), radius: 10)
            .padding(.horizontal, 40)
            .padding(.bottom, 100)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .background(Color.black.opacity(0.3).edgesIgnoringSafeArea(.all))
        .onTapGesture {
            showFontPicker = false
        }
    }
    
    private var fontSizePickerOverlay: some View {
        VStack {
            Spacer()
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                    ForEach(fontSizes, id: \.self) { size in
                        Button(action: {
                            applyFontSize(size)
                            showFontSizePicker = false
                        }) {
                            Text("\(Int(size))")
                                .foregroundColor(.primary)
                                .font(.system(size: min(size, 24)))
                                .frame(width: 50, height: 40)
                                .background(Color.vibrantPurple.opacity(0.2))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.vibrantPurple, lineWidth: 1)
                                )
                        }
                    }
                }
                .padding()
            }
            .frame(maxHeight: 300)
            .background(Color.appBackground)
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.3), radius: 10)
            .padding(.horizontal, 40)
            .padding(.bottom, 100)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .background(Color.black.opacity(0.3).edgesIgnoringSafeArea(.all))
        .onTapGesture {
            showFontSizePicker = false
        }
    }

    func addBulletPoints() {
        guard selectedRange.length > 0 else { return }

        let selectedText = attributedText.attributedSubstring(from: selectedRange).string
        let lines = selectedText.components(separatedBy: "\n")
        let bulletedText = lines.map { "• \($0)" }.joined(separator: "\n")

        let mutableAttributedString = NSMutableAttributedString(attributedString: attributedText)
        mutableAttributedString.replaceCharacters(in: selectedRange, with: bulletedText)

        attributedText = mutableAttributedString
        selectedRange.length = bulletedText.count
    }

    func isBoldActive() -> Bool {
        return checkTraitActive(.traitBold)
    }

    func isItalicActive() -> Bool {
        return checkTraitActive(.traitItalic)
    }

    func isUnderlineActive() -> Bool {
        let underline = getCurrentUnderlineStyle()
        return underline == NSUnderlineStyle.single.rawValue
    }
    
    private func checkTraitActive(_ trait: UIFontDescriptor.SymbolicTraits) -> Bool {
        if selectedRange.length > 0 {
            var hasTraitThroughout = true
            let endLocation = min(selectedRange.location + selectedRange.length, attributedText.length)
            
            attributedText.enumerateAttribute(.font, in: NSRange(location: selectedRange.location, length: endLocation - selectedRange.location), options: []) { value, range, stop in
                if let font = value as? UIFont {
                    if !font.fontDescriptor.symbolicTraits.contains(trait) {
                        hasTraitThroughout = false
                        stop.pointee = true
                    }
                }
            }
            return hasTraitThroughout
        } else {
            if let font = typingAttributes[.font] as? UIFont {
                return font.fontDescriptor.symbolicTraits.contains(trait)
            }
            return false
        }
    }
    
    private func getCurrentFont() -> UIFont {
        if selectedRange.length > 0 && selectedRange.location < attributedText.length {
            return attributedText.attribute(.font, at: selectedRange.location, effectiveRange: nil) as? UIFont ?? UIFont.systemFont(ofSize: 18)
        } else {
            return typingAttributes[.font] as? UIFont ?? UIFont.systemFont(ofSize: 18)
        }
    }
    
    private func getCurrentUnderlineStyle() -> Int {
        if selectedRange.length > 0 && selectedRange.location < attributedText.length {
            return attributedText.attribute(.underlineStyle, at: selectedRange.location, effectiveRange: nil) as? Int ?? 0
        } else {
            return typingAttributes[.underlineStyle] as? Int ?? 0
        }
    }
    
    func applyFontFamily(_ font: UIFont) {
        let size = getCurrentFont().pointSize
        let newFont = UIFont(name: font.fontName, size: size) ?? font
        applyAttribute(.font, value: newFont)
    }
    
    func applyFontSize(_ size: CGFloat) {
        let currentFont = getCurrentFont()
        let newFont = UIFont(descriptor: currentFont.fontDescriptor, size: size)
        applyAttribute(.font, value: newFont)
    }

    func toggleBold() {
        if selectedRange.length > 0 {
            let mutableAttributedString = NSMutableAttributedString(attributedString: attributedText)
            let endLocation = min(selectedRange.location + selectedRange.length, attributedText.length)
            let range = NSRange(location: selectedRange.location, length: endLocation - selectedRange.location)
            
            mutableAttributedString.enumerateAttribute(.font, in: range, options: []) { value, subRange, _ in
                if let font = value as? UIFont {
                    var traits = font.fontDescriptor.symbolicTraits
                    if traits.contains(.traitBold) {
                        traits.remove(.traitBold)
                    } else {
                        traits.insert(.traitBold)
                    }
                    if let newFontDescriptor = font.fontDescriptor.withSymbolicTraits(traits) {
                        let newFont = UIFont(descriptor: newFontDescriptor, size: font.pointSize)
                        mutableAttributedString.addAttribute(.font, value: newFont, range: subRange)
                    }
                }
            }
            attributedText = mutableAttributedString
        } else {
            let currentFont = typingAttributes[.font] as? UIFont ?? UIFont.systemFont(ofSize: 18)
            var traits = currentFont.fontDescriptor.symbolicTraits
            if traits.contains(.traitBold) {
                traits.remove(.traitBold)
            } else {
                traits.insert(.traitBold)
            }
            if let newFontDescriptor = currentFont.fontDescriptor.withSymbolicTraits(traits) {
                let newFont = UIFont(descriptor: newFontDescriptor, size: currentFont.pointSize)
                typingAttributes[.font] = newFont
            }
        }
        hasUnsavedChanges = true
    }

    func toggleItalic() {
        if selectedRange.length > 0 {
            let mutableAttributedString = NSMutableAttributedString(attributedString: attributedText)
            let endLocation = min(selectedRange.location + selectedRange.length, attributedText.length)
            let range = NSRange(location: selectedRange.location, length: endLocation - selectedRange.location)
            
            mutableAttributedString.enumerateAttribute(.font, in: range, options: []) { value, subRange, _ in
                if let font = value as? UIFont {
                    var traits = font.fontDescriptor.symbolicTraits
                    if traits.contains(.traitItalic) {
                        traits.remove(.traitItalic)
                    } else {
                        traits.insert(.traitItalic)
                    }
                    if let newFontDescriptor = font.fontDescriptor.withSymbolicTraits(traits) {
                        let newFont = UIFont(descriptor: newFontDescriptor, size: font.pointSize)
                        mutableAttributedString.addAttribute(.font, value: newFont, range: subRange)
                    }
                }
            }
            attributedText = mutableAttributedString
        } else {
            let currentFont = typingAttributes[.font] as? UIFont ?? UIFont.systemFont(ofSize: 18)
            var traits = currentFont.fontDescriptor.symbolicTraits
            if traits.contains(.traitItalic) {
                traits.remove(.traitItalic)
            } else {
                traits.insert(.traitItalic)
            }
            if let newFontDescriptor = currentFont.fontDescriptor.withSymbolicTraits(traits) {
                let newFont = UIFont(descriptor: newFontDescriptor, size: currentFont.pointSize)
                typingAttributes[.font] = newFont
            }
        }
        hasUnsavedChanges = true
    }
   
    func toggleUnderline() {
        if selectedRange.length > 0 {
            let mutableAttributedString = NSMutableAttributedString(attributedString: attributedText)
            let endLocation = min(selectedRange.location + selectedRange.length, attributedText.length)
            let range = NSRange(location: selectedRange.location, length: endLocation - selectedRange.location)
            
            mutableAttributedString.enumerateAttribute(.underlineStyle, in: range, options: []) { value, subRange, _ in
                let currentUnderline = value as? Int ?? 0
                let newUnderline = currentUnderline == NSUnderlineStyle.single.rawValue ? 0 : NSUnderlineStyle.single.rawValue
                mutableAttributedString.addAttribute(.underlineStyle, value: newUnderline, range: subRange)
            }
            attributedText = mutableAttributedString
        } else {
            let currentUnderline = typingAttributes[.underlineStyle] as? Int ?? 0
            let newUnderline = currentUnderline == NSUnderlineStyle.single.rawValue ? 0 : NSUnderlineStyle.single.rawValue
            typingAttributes[.underlineStyle] = newUnderline
        }
        hasUnsavedChanges = true
    }

    func applyAttribute(_ key: NSAttributedString.Key, value: Any) {
        if selectedRange.length > 0 {
            let mutableAttributedString = NSMutableAttributedString(attributedString: attributedText)
            let endLocation = min(selectedRange.location + selectedRange.length, attributedText.length)
            let range = NSRange(location: selectedRange.location, length: endLocation - selectedRange.location)
            mutableAttributedString.addAttribute(key, value: value, range: range)
            attributedText = mutableAttributedString
        } else {
            typingAttributes[key] = value
        }
        hasUnsavedChanges = true
    }
}
