//
//  RootView.swift
//  Epilogue
//
//  Created by Zehra Öner on 20.07.2026.
//

import SwiftUI

/// Uygulamanın kök view'ı: AuthViewModel'in durumuna göre
/// yükleniyor / giriş ekranı / ana uygulama arasında geçiş yapar.
struct RootView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @Environment(AuthViewModel.self) private var authViewModel
    @AppStorage("isBiometricEnabled") private var isBiometricEnabled = false
    @State private var biometricManager = BiometricManager()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if !hasSeenOnboarding {
                OnboardingView()
            } else if authViewModel.isLoading {
                ProgressView()
            } else if authViewModel.currentUser != nil {
                if isBiometricEnabled && !biometricManager.isUnlocked {
                    LockScreenView(biometricManager: biometricManager)
                } else {
                    MainTabView()
                }
            } else {
                LoginView()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                biometricManager.isUnlocked = false
            }
        }
    }
}
