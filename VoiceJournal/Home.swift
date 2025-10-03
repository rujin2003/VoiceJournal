//
//  Home.swift
//  VoiceJournal
//
//  Created by Rujin Devkota on 10/3/25.
//

//
//  Home.swift
//  VoiceJournal
//
//  Created by Rujin Devkota on 10/3/25.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var scrollOffset: CGFloat = 0
    @State private var activeIndex: Int? = 0

    private let cardHeight: CGFloat = 150
    private let cardSpacing: CGFloat = 16
    private var itemHeight: CGFloat { cardHeight + cardSpacing }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.95, green: 0.96, blue: 0.98), Color.white], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                StreakCardView(
                    currentStreak: viewModel.currentStreak,
                    longestStreak: viewModel.longestStreak,
                    totalEntries: viewModel.totalEntries
                )
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 12)

                GeometryReader { mainGeo in
                    let scrollAreaHeight = mainGeo.size.height
                    let verticalPadding = (scrollAreaHeight / 2) - (itemHeight / 2)

                    HStack(alignment: .top, spacing: 0) {
                        DateRulerView(
                            scrollOffset: scrollOffset,
                            entries: viewModel.entries,
                            activeIndex: $activeIndex,
                            itemHeight: itemHeight,
                            verticalPadding: verticalPadding,
                            rulerHeight: scrollAreaHeight
                        )
                        .frame(width: 80)

                        ScrollView(showsIndicators: false) {
                            GeometryReader { scrollGeo in
                                Color.clear.preference(
                                    key: ScrollOffsetPreferenceKey.self,
                                    value: scrollGeo.frame(in: .named("scroll")).minY
                                )
                            }
                            .frame(height: 0)
                            
                            LazyVStack(spacing: cardSpacing) {
                                ForEach(Array(viewModel.entries.enumerated()), id: \.element.id) { index, entry in
                                    JournalCardView(entry: entry, index: index, cardHeight: cardHeight)
                                }
                            }
                            .padding(.vertical, verticalPadding)
                        }
                        .coordinateSpace(name: "scroll")
                        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                            scrollOffset = value
                            updateActiveIndex(from: value, containerHeight: scrollAreaHeight)
                        }
                    }
                }
            }
        }
    }

    private func updateActiveIndex(from offset: CGFloat, containerHeight: CGFloat) {
        let centerLine = containerHeight / 2
        let centeredIndex = Int(round((centerLine - offset - (itemHeight / 2)) / itemHeight))
        
        guard centeredIndex >= 0 && centeredIndex < viewModel.entries.count else { return }
        
        if centeredIndex != activeIndex {
            activeIndex = centeredIndex
            let generator = UIImpactFeedbackGenerator(style: .soft)
            generator.impactOccurred()
        }
    }
}

// MARK: - Streak Card View
struct StreakCardView: View {
    let currentStreak: Int
    let longestStreak: Int
    let totalEntries: Int
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Your Journey")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                Spacer()
            }
            
            HStack(spacing: 12) {
                StreakItemView(
                    icon: "flame.fill",
                    value: "\(currentStreak)",
                    label: "Day Streak",
                    color: .orange,
                    isLarge: true
                )
                
                VStack(spacing: 12) {
                    StreakItemView(
                        icon: "star.fill",
                        value: "\(longestStreak)",
                        label: "Longest",
                        color: .yellow,
                        isLarge: false
                    )
                    
                    StreakItemView(
                        icon: "book.fill",
                        value: "\(totalEntries)",
                        label: "Entries",
                        color: .blue,
                        isLarge: false
                    )
                }
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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: isLarge ? 24 : 18))
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.system(size: isLarge ? 42 : 28, weight: .bold))
                .foregroundColor(.primary)
            
            Text(label)
                .font(.system(size: isLarge ? 16 : 14, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(isLarge ? 20 : 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.background)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: -  Date Ruler
struct DateRulerView: View {
    let scrollOffset: CGFloat
    let entries: [JournalEntry]
    @Binding var activeIndex: Int?
    
    let itemHeight: CGFloat
    let verticalPadding: CGFloat
    let rulerHeight: CGFloat

    var body: some View {
        ZStack {
            RulerBackgroundTicksView(itemHeight: itemHeight, topPadding: verticalPadding)
                .offset(y: scrollOffset)

            VStack(spacing: 0) {
                let centerLine = rulerHeight / 2
                
                ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                    let itemYPosition = verticalPadding + (CGFloat(index) * itemHeight) + scrollOffset + (itemHeight / 2)
                    let distanceFromCenter = abs(centerLine - itemYPosition)
                    
                    RulerMarkingView(
                        entry: entry,
                        isActive: activeIndex == index,
                        distanceFromCenter: distanceFromCenter
                    )
                    .frame(height: itemHeight)
                }
            }
        }
        .clipped()
    }
}

// MARK: - Background Ticks View
struct RulerBackgroundTicksView: View {
    let itemHeight: CGFloat
    let topPadding: CGFloat
    
    var body: some View {
        Canvas { context, size in
            let tickSpacing = itemHeight / 10
            let totalTicks = Int(size.height / tickSpacing) + 50
            let midX = size.width - 15

            for i in -25..<totalTicks {
                let y = CGFloat(i) * tickSpacing
                let startPoint = CGPoint(x: midX, y: y)
                var endPoint = CGPoint(x: midX + 5, y: y)
                var color = Color.gray.opacity(0.3)
                
                if i % 5 == 0 {
                    endPoint = CGPoint(x: midX + 8, y: y)
                }
                
                if i % 10 == 0 {
                    endPoint = CGPoint(x: midX + 12, y: y)
                    color = .gray.opacity(0.5)
                }
                
                context.stroke(
                    Path { path in
                        path.move(to: startPoint)
                        path.addLine(to: endPoint)
                    },
                    with: .color(color),
                    lineWidth: 1
                )
            }
        }
        .padding(.top, topPadding - (itemHeight * 1.5))
    }
}

// MARK: - Ruler Marking View
struct RulerMarkingView: View {
    let entry: JournalEntry
    let isActive: Bool
    let distanceFromCenter: CGFloat
    
    private var scale: CGFloat {
        let maxDistance: CGFloat = 250
        let normalized = max(0, 1 - (distanceFromCenter / maxDistance))
        return 1.0 + (normalized * normalized) * 0.7
    }
    
    private var opacity: Double {
        let maxDistance: CGFloat = 300
        let normalized = min(distanceFromCenter / maxDistance, 1.0)
        return Double(0.4 + (1 - normalized) * 0.6)
    }
    
    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .trailing) {
                Text(entry.date, format: .dateTime.month(.abbreviated).year())
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(isActive ? .blue : .secondary)
                
                Text(entry.date, format: .dateTime.day())
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(isActive ? .primary : .secondary)
            }
            .frame(minWidth: 55, alignment: .trailing)
            
            Rectangle()
                .fill(isActive ? Color.blue : Color.gray.opacity(0.5))
                .frame(width: 2, height: isActive ? 20 : 12)
                .cornerRadius(1)
        }
        .scaleEffect(x: scale, y: scale)
        .opacity(opacity)
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: scale)
        .animation(.easeInOut(duration: 0.3), value: isActive)
    }
}

// MARK: - Journal Card View
struct JournalCardView: View {
    let entry: JournalEntry
    let index: Int
    let cardHeight: CGFloat
    @State private var isVisible = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(entry.mood)
                    .font(.system(size: 32))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text(entry.date, style: .time)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Text(entry.content)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .lineLimit(3)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: cardHeight)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.background)
                .shadow(color: .black.opacity(0.05), radius: 15, x: 0, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(entry.color.opacity(0.4), lineWidth: 1.5)
        )
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 30)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index % 10) * 0.05)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Preference Key
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview(body: {
    HomeView()
})
