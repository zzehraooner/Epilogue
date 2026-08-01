//
//  EpilogueApp.swift
//  Epilogue
//
//  Created by Zehra Öner on 18.07.2026.
//
import SwiftUI
import FirebaseCore

@main
struct EpilogueApp: App {
    @State private var authViewModel: AuthViewModel

        /// FirebaseApp.configure() burada, AuthViewModel oluşturulmadan
        /// hemen önce, senkron olarak çağrılıyor. Bu, @UIApplicationDelegateAdaptor
        /// kullanırken oluşabilecek "configure() henüz çağrılmadı" race condition'ını
        /// tamamen ortadan kaldırır.
        init() {
            FirebaseApp.configure()
            _authViewModel = State(initialValue: AuthViewModel())
        }

        var body: some Scene {
            WindowGroup {
                RootView()
                    .environment(authViewModel)
                    .tint(.purple)
                    .preferredColorScheme(.dark)
            }

    }
}
