
//
//  Home.swift
//  VoiceJournal
//
//  Created by Rujin Devkota on 10/3/25.
//
import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = HomeViewModel()
    @Query(sort: \JournalNote.createdAt, order: .reverse) private var notes: [JournalNote]
    
    @State private var selectedDate: Date = Date()
    private let rulerItemHeight: CGFloat = 90
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(colors: [.appBackgroundStart, .appBackgroundEnd], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    HStack {
                        Text("Your Journey")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.black)
                        Spacer()
                        NavigationLink(destination: JournalView()) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.vibrantPurple)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                        
                    StreakCardView(
                        currentStreak: viewModel.currentStreak,
                        longestStreak: viewModel.longestStreak,
                        totalEntries: viewModel.totalEntries(from: notes)
                    )
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                        
                    GeometryReader { geo in
                        HStack(spacing: 12) {
                            TimelineRulerView(
                                viewModel: viewModel,
                                notes: notes,
                                selectedDate: $selectedDate,
                                itemHeight: rulerItemHeight,
                                containerHeight: geo.size.height
                            )
                            .frame(width: 100)
                            
                            JournalCardsDisplayView(
                                entries: viewModel.entriesForDate(selectedDate, in: notes),
                                selectedDate: selectedDate,
                                containerHeight: geo.size.height,
                                modelContext: modelContext
                            )
                        }
                        .padding(.horizontal, 8)
                    }
                }
            }
        }
    }
}

// MARK: - Subviews

struct StreakCardView: View {
    let currentStreak: Int
    let longestStreak: Int
    let totalEntries: Int
    
    var body: some View {
        HStack(spacing: 10) {
            StreakItemView(icon: "flame.fill", value: "\(currentStreak)", label: "Day Streak", color: .vibrantOrange, isLarge: true)
            
            VStack(spacing: 10) {
                StreakItemView(icon: "star.fill", value: "\(longestStreak)", label: "Longest", color: .vibrantGold, isLarge: false)
                StreakItemView(icon: "book.fill", value: "\(totalEntries)", label: "Entries", color: .vibrantTeal, isLarge: false)
            }
        }
    }
}

struct StreakItemView: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    let isLarge: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: isLarge ? 34 : 28, height: isLarge ? 34 : 28)
                    Image(systemName: icon)
                        .font(.system(size: isLarge ? 18 : 14))
                        .foregroundColor(color)
                }
                Spacer()
            }
            
            Text(value)
                .font(.system(size: isLarge ? 34 : 22, weight: .bold))
                .foregroundColor(.primary)
            
            Text(label)
                .font(.system(size: isLarge ? 14 : 12, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(isLarge ? 14 : 10)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
                .shadow(color: color.opacity(0.2), radius: 8, x: 0, y: 4)
        )
    }
}

struct TimelineRulerView: View {
    @ObservedObject var viewModel: HomeViewModel
    let notes: [JournalNote]
    @Binding var selectedDate: Date
    let itemHeight: CGFloat
    let containerHeight: CGFloat
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
              
                VStack {
                    Rectangle()
                        .fill(LinearGradient(colors: [Color(red: 0.7, green: 0.65, blue: 0.85).opacity(0.8), Color(red: 0.7, green: 0.65, blue: 0.85).opacity(0.3)], startPoint: .top, endPoint: .bottom))
                        .frame(width: 3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 28)
                
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.allDatesFromToday(from: notes), id: \.self) { date in
                                TimelineItemView(
                                    date: date,
                                    isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                                    hasEntries: viewModel.hasEntries(for: date, in: notes),
                                    entryCount: viewModel.entriesForDate(date, in: notes).count
                                )
                                .frame(height: itemHeight)
                                .id(Calendar.current.startOfDay(for: date))
                                .background(
                                    GeometryReader { itemGeo in
                                        Color.clear.preference(
                                            key: DatePositionPreferenceKey.self,
                                            value: [date: itemGeo.frame(in: .named("scroll")).midY]
                                        )
                                    }
                                )
                            }
                        }
                        .padding(.bottom, containerHeight - itemHeight / 2)
                    }
                    .coordinateSpace(name: "scroll")
                    .onPreferenceChange(DatePositionPreferenceKey.self) { positions in
                        updateSelectedDate(from: positions)
                    }
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            proxy.scrollTo(Calendar.current.startOfDay(for: Date()), anchor: .top)
                        }
                    }
                }
                

                VStack {
                    Image("journalicon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        .offset(y: itemHeight / 2 - 14)
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 14)
                .frame(maxHeight: .infinity, alignment: .top)
            }
        }
    }
    
    private func updateSelectedDate(from positions: [Date: CGFloat]) {
        let selectionY = itemHeight / 2
        guard let closest = positions.min(by: { abs($0.value - selectionY) < abs($1.value - selectionY) }) else { return }
        
        if !Calendar.current.isDate(closest.key, inSameDayAs: selectedDate) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedDate = closest.key
            }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }
}

struct TimelineItemView: View {
    let date: Date
    let isSelected: Bool
    let hasEntries: Bool
    let entryCount: Int
    
    var body: some View {
        HStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(hasEntries ? Color(red: 0.7, green: 0.65, blue: 0.85) : Color.gray.opacity(0.3))
                    .frame(width: isSelected ? 22 : 16, height: isSelected ? 22 : 16)
            }
            .frame(width: 38)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(date, format: .dateTime.month(.abbreviated).day())
                    .font(.system(size: isSelected ? 16 : 14, weight: isSelected ? .bold : .semibold))
                    .foregroundColor(isSelected ? .primary : .secondary)
                
                Text(date, format: .dateTime.weekday(.abbreviated))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary.opacity(0.8))
            }
            .padding(.leading, 8)
            Spacer()
        }
        .scaleEffect(isSelected ? 1.08 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

struct JournalCardsDisplayView: View {
    let entries: [JournalNote]
    let selectedDate: Date
    let containerHeight: CGFloat
    let modelContext: ModelContext
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            if entries.isEmpty {
                EmptyStateView(selectedDate: selectedDate, containerHeight: containerHeight)
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                        JournalCardView(entry: entry, index: index, modelContext: modelContext)
                    }
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 12)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: entries.count)
    }
}

struct JournalCardView: View {
    let entry: JournalNote
    let index: Int
    let modelContext: ModelContext
    @State private var isVisible = false
    @State private var offset: CGFloat = 0
    @State private var isSwiping = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(entry.color.opacity(0.15))
                        .frame(width: 46, height: 46)
                    Text(entry.mood)
                        .font(.system(size: 24))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                }
                Spacer()
            }
            
            Text(entry.plainTextPreview)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .lineLimit(4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.white)
                .shadow(color: entry.color.opacity(0.15), radius: 10, x: 0, y: 5)
        )
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? offset : 30)
        .background(
      
            HStack {
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.red)
                    VStack(spacing: 4) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                        Text("Delete")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .frame(width: 80)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    if gesture.translation.width < 0 {
                        offset = gesture.translation.width
                        isSwiping = true
                    }
                }
                .onEnded { gesture in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        if gesture.translation.width < -100 {
                       
                            offset = -500
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                modelContext.delete(entry)
                                try? modelContext.save()
                            }
                        } else {
                      
                            offset = 0
                        }
                        isSwiping = false
                    }
                }
        )
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(Double(index) * 0.1)) {
                isVisible = true
            }
        }
    }
}

struct EmptyStateView: View {
    let selectedDate: Date
    let containerHeight: CGFloat
    private var isToday: Bool { Calendar.current.isDateInToday(selectedDate) }

    var body: some View {
        VStack(spacing: 16) {
            if isToday {
                Image(systemName: "book.closed")
                    .font(.system(size: 60))
                    .foregroundColor(.vibrantPurple)
                Text("No entries today")
                    .font(.system(size: 22, weight: .bold))
                Text("Tap + to start journaling")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.secondary)
            } else {
                Image(systemName: "book.closed")
                    .font(.system(size: 60))
                    .foregroundColor(.gray.opacity(0.3))
                Text("No entries")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.secondary)
                Text(selectedDate, format: .dateTime.month().day().year())
                    .font(.system(size: 14))
                    .foregroundColor(.secondary.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: containerHeight)
    }
}

struct DatePositionPreferenceKey: PreferenceKey {
    static var defaultValue: [Date: CGFloat] = [:]
    static func reduce(value: inout [Date: CGFloat], nextValue: () -> [Date: CGFloat]) {
        value.merge(nextValue()) { $1 }
    }
}
