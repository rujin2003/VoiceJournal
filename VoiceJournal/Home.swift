//
//  Home.swift
//  VoiceJournal
//
//  Created by Rujin Devkota on 10/3/25.
//
import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var selectedDate: Date = Date()
    private let rulerItemHeight: CGFloat = 90
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [.appBackgroundStart, .appBackgroundEnd], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Text("Your Journey")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.black)
                    Spacer()
                    Button(action: {}) {
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
                    totalEntries: viewModel.totalEntries
                )
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                
                GeometryReader { geo in
                    HStack(spacing: 12) {
                        TimelineRulerView(
                            viewModel: viewModel,
                            selectedDate: $selectedDate,
                            itemHeight: rulerItemHeight,
                            containerHeight: geo.size.height
                        )
                        .frame(width: 100)
                        
                        JournalCardsDisplayView(
                            entries: viewModel.entriesForDate(selectedDate),
                            selectedDate: selectedDate,
                            containerHeight: geo.size.height
                        )
                    }
                    .padding(.horizontal, 8)
                }
            }
        }
    }
}

struct StreakCardView: View {
    let currentStreak: Int
    let longestStreak: Int
    let totalEntries: Int
    
    var body: some View {
        HStack(spacing: 10) {
            StreakItemView(
                icon: "flame.fill",
                value: "\(currentStreak)",
                label: "Day Streak",
                color: .vibrantOrange,
                isLarge: true
            )
            
            VStack(spacing: 10) {
                StreakItemView(
                    icon: "star.fill",
                    value: "\(longestStreak)",
                    label: "Longest",
                    color: .vibrantGold,
                    isLarge: false
                )
                
                StreakItemView(
                    icon: "book.fill",
                    value: "\(totalEntries)",
                    label: "Entries",
                    color: .vibrantTeal,
                    isLarge: false
                )
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
    @Binding var selectedDate: Date
    let itemHeight: CGFloat
    let containerHeight: CGFloat
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                VStack {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.7, green: 0.65, blue: 0.85).opacity(0.8), Color(red: 0.7, green: 0.65, blue: 0.85).opacity(0.3)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 30)
                
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.allDatesFromToday, id: \.self) { date in
                                TimelineItemView(
                                    date: date,
                                    isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                                    hasEntries: viewModel.hasEntries(for: date),
                                    entryCount: viewModel.entriesForDate(date).count
                                )
                                .frame(height: itemHeight)
                                .id(date)
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
                            proxy.scrollTo(Date(), anchor: .top)
                        }
                    }
                }
                
                VStack {
                    Image("journalicon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        .alignmentGuide(.top) { d in d[.top] + (itemHeight / 2 - d.height / 2) }
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 16)
                .frame(maxHeight: .infinity, alignment: .top)

            }
        }
    }
    
    private func updateSelectedDate(from positions: [Date: CGFloat]) {
        let selectionY = itemHeight / 2
        var closestDate: Date?
        var minDistance: CGFloat = .infinity
        
        for (date, y) in positions {
            let distance = abs(y - selectionY)
            if distance < minDistance {
                minDistance = distance
                closestDate = date
            }
        }
        
        if let newDate = closestDate, !Calendar.current.isDate(newDate, inSameDayAs: selectedDate) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedDate = newDate
            }
            #if os(iOS)
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            #endif
        }
    }
}

struct TimelineItemView: View {
    let date: Date
    let isSelected: Bool
    let hasEntries: Bool
    let entryCount: Int
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(hasEntries ? Color(red: 0.7, green: 0.65, blue: 0.85) : Color.gray.opacity(0.3))
                    .frame(width: isSelected ? 22 : 16, height: isSelected ? 22 : 16)
            }
            .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(date, format: .dateTime.month(.abbreviated).day())
                    .font(.system(size: isSelected ? 16 : 14, weight: isSelected ? .bold : .semibold))
                    .foregroundColor(isSelected ? .primary : .secondary)
                
                Text(date, format: .dateTime.weekday(.abbreviated))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary.opacity(0.8))
            }
            .padding(.leading, 6)
            
            Spacer()
        }
        .scaleEffect(isSelected ? 1.08 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

struct JournalCardsDisplayView: View {
    let entries: [JournalEntry]
    let selectedDate: Date
    let containerHeight: CGFloat
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            if entries.isEmpty {
                VStack(spacing: 16) {
                    if isToday {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [Color.vibrantPurple.opacity(0.2), Color.vibrantTeal.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 70))
                                .foregroundColor(.vibrantPurple)
                        }
                        
                        Text("Please journal today")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("Start capturing your thoughts")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Button(action: {}) {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                Text("Create Entry")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background(
                                Capsule().fill(
                                    LinearGradient(colors: [.vibrantPurple, .vibrantTeal], startPoint: .leading, endPoint: .trailing)
                                )
                            )
                        }
                        .padding(.top, 8)
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
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                        JournalCardView(entry: entry, index: index)
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
    let entry: JournalEntry
    let index: Int
    @State private var isVisible = false
    
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
            
            Text(entry.content)
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
        .offset(x: isVisible ? 0 : 30)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(Double(index) * 0.1)) {
                isVisible = true
            }
        }
    }
}

struct DatePositionPreferenceKey: PreferenceKey {
    static var defaultValue: [Date: CGFloat] = [:]
    static func reduce(value: inout [Date: CGFloat], nextValue: () -> [Date: CGFloat]) {
        value.merge(nextValue()) { $1 }
    }
}

