//
//  OnboardingView.swift
//  Epilogue
//
//  Created by Zehra Öner on 21.07.2026.
//

import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            // Arka plan gradyanı
            LinearGradient(
                colors: [Color(hex: "4A00E0"), Color(hex: "8E2DE2")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            TabView(selection: $selectedTab) {
                OnboardingPage(
                    title: "Anılarını Biriktir",
                    description: "Sevdiklerinle yaşadığın en güzel anıları tek bir yerde topla.",
                    iconName: "photo.stack.fill"
                )
                .tag(0)
                
                OnboardingPage(
                    title: "Depo Oluştur",
                    description: "Farklı arkadaş grupları veya ailen için özel depolar oluştur.",
                    iconName: "shippingbox.fill"
                )
                .tag(1)
                
                OnboardingPage(
                    title: "Sevdiklerinle Paylaş",
                    description: "Davet koduyla sevdiklerini depolara davet et, anıları ortaklaşa büyüt.",
                    iconName: "person.2.fill"
                )
                .tag(2)
                
                VStack(spacing: 30) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                        .padding(.bottom, 20)
                    
                    Text("Hadi Başlayalım")
                        .font(.system(.largeTitle, design: .rounded).weight(.bold))
                        .foregroundColor(.white)
                    
                    Button(action: {
                        withAnimation {
                            hasSeenOnboarding = true
                        }
                    }) {
                        Text("Başla")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: "4A00E0"))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(15)
                            .padding(.horizontal, 40)
                    }
                    .padding(.top, 40)
                }
                .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
        }
    }
}

struct OnboardingPage: View {
    let title: String
    let description: String
    let iconName: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: iconName)
                .font(.system(size: 100))
                .foregroundColor(.white)
                .padding(.bottom, 20)
            
            Text(title)
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .foregroundColor(.white)
            
            Text(description)
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 40)
        }
    }
}

#Preview {
    OnboardingView()
}
