//
//  Onboarding.swift
//  VoiceJournal
//
//  Created by Rujin Devkota on 10/3/25.
//

import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var isAnimating = false
    @State private var showHome = false
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    
    let onboardingData = [
        OnboardingPage(
            image: "onboarding1",
            title: "Capture Your Thoughts",
            description: "Write down your thoughts, ideas, and experiences in your personal digital journal."
        ),
        OnboardingPage(
            image: "onboarding2",
            title: "Express with Voice",
            description: "Use voice recording to capture your thoughts naturally and effortlessly."
        ),
        OnboardingPage(
            image: "onboarding3",
            title: "Track Your Journey",
            description: "Build a writing streak and watch your personal growth unfold over time."
        )
    ]
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.9, green: 0.85, blue: 0.95),
                    Color(red: 0.95, green: 0.9, blue: 0.98),
                    Color(red: 0.9, green: 0.85, blue: 0.95)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                HStack {
                    Spacer()
                    Button("Skip") {
                        completeOnboarding()
                    }
                    .foregroundColor(.gray)
                    .padding(.trailing, 20)
                    .padding(.top, 10)
                }
                
            
                TabView(selection: $currentPage) {
                    ForEach(0..<onboardingData.count, id: \.self) { index in
                        OnboardingPageView(
                            page: onboardingData[index],
                            isAnimating: isAnimating
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)
                
               
                VStack(spacing: 30) {
         
                    HStack(spacing: 8) {
                        ForEach(0..<onboardingData.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentPage ? Color.purple : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .scaleEffect(index == currentPage ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 0.3), value: currentPage)
                        }
                    }
                    
                    
                    HStack(spacing: 20) {
                        if currentPage > 0 {
                            Button("Previous") {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentPage -= 1
                                }
                            }
                            .foregroundColor(.gray)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.3))
                            .cornerRadius(25)
                        }
                        
                        Spacer()
                        
                        Button(currentPage == onboardingData.count - 1 ? "Get Started" : "Next") {
                            if currentPage == onboardingData.count - 1 {
                                completeOnboarding()
                            } else {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentPage += 1
                                }
                            }
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [Color.purple, Color.purple.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(25)
                        .scaleEffect(isAnimating ? 1.0 : 0.9)
                        .animation(.easeInOut(duration: 0.3), value: isAnimating)
                    }
                    .padding(.horizontal, 30)
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8)) {
                isAnimating = true
            }
        }
        .fullScreenCover(isPresented: $showHome) {
            ContentView()
        }
    }
    
    private func completeOnboarding() {
        hasSeenOnboarding = true
        withAnimation(.easeInOut(duration: 0.5)) {
            showHome = true
        }
    }
}

struct OnboardingPage {
    let image: String
    let title: String
    let description: String
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    let isAnimating: Bool
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            
            Image(page.image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 300)
                .scaleEffect(isAnimating ? 1.0 : 0.8)
                .opacity(isAnimating ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.8).delay(0.2), value: isAnimating)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            
       
            VStack(spacing: 20) {
                Text(page.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.8).delay(0.4), value: isAnimating)
                
                Text(page.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.8).delay(0.6), value: isAnimating)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    OnboardingView()
}
