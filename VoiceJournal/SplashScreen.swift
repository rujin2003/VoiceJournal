//
//  SplashScreen.swift
//  VoiceJournal
//
//  Created by Rujin Devkota on 10/3/25.
//

import SwiftUI

struct SplashScreen: View {
    @State private var isAnimating = false
    @State private var showOnboarding = false
    
    var body: some View {
        ZStack {
            
            LinearGradient(
                colors: [
                    Color(red: 0.8, green: 0.7, blue: 0.9),
                    Color(red: 0.9, green: 0.8, blue: 0.95),
                    Color(red: 0.85, green: 0.75, blue: 0.9)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
              
                Image("applogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .scaleEffect(isAnimating ? 1.1 : 0.8)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 1.0), value: isAnimating)
                
             
                Text("VoiceJournal")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 1.0).delay(0.3), value: isAnimating)
                
                Spacer()
            }
        }
        .onAppear {
            isAnimating = true
            
           
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showOnboarding = true
                }
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView()
        }
    }
}

#Preview {
    SplashScreen()
}
