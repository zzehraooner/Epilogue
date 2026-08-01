//
//  LoginView.swift
//  Epilogue
//
//  Created by Zehra Öner on 20.07.2026.
//

import SwiftUI

/// Giriş ekranı. Canlı gradient arka plan, yuvarlatılmış kart içinde
/// form — minimalist beyaz/siyahtan farklı olarak burada renk ve
/// enerji ön planda.
struct LoginView: View {
    @Environment(AuthViewModel.self) private var authViewModel

    @State private var email = ""
    @State private var password = ""
    @State private var showingSignUp = false
    @State private var isSubmitting = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "FF6B6B"), Color(hex: "9B5DE5"), Color(hex: "4361EE")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 8) {
                        Image(systemName: "sparkles.rectangle.stack.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.white)
                        Text("Stash")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Anılarını sevdiklerinle biriktir")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    .padding(.top, 60)

                    VStack(spacing: 16) {
                        TextField("E-posta", text: $email)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .padding()
                            .foregroundStyle(.black)
                            .tint(.black)
                            .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                        SecureField("Şifre", text: $password)
                            .padding()
                            .foregroundStyle(.black)
                            .tint(.black)
                            .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                        if let error = authViewModel.errorMessage {
                            Text(error)
                                .font(.footnote)
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                        }

                        Button {
                            Task {
                                isSubmitting = true
                                await authViewModel.signIn(email: email, password: password)
                                isSubmitting = false
                            }
                        } label: {
                            Group {
                                if isSubmitting {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Giriş Yap")
                                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                        }
                        .background(Color.black.opacity(0.85), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .foregroundStyle(.white)
                        .disabled(email.isEmpty || password.isEmpty || isSubmitting)

                        Button {
                            showingSignUp = true
                        } label: {
                            Text("Hesabın yok mu? **Kayıt Ol**")
                                .font(.footnote)
                                .foregroundStyle(.white)
                        }
                        .padding(.top, 4)
                    }
                    .padding(24)
                    .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .padding(.horizontal, 24)
                }
            }
        }
        .sheet(isPresented: $showingSignUp) {
            SignUpView()
        }
    }
}

/// Hex renk kodlarından SwiftUI Color oluşturmak için yardımcı.
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

#Preview {
    LoginView()
        .environment(AuthViewModel())
}
