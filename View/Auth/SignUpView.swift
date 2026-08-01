//
//  SignUpView.swift
//  Epilogue
//
//  Created by Zehra Öner on 20.07.2026.
//

import SwiftUI

/// Kayıt (Sign Up) ekranı. LoginView'dan sheet olarak açılır.
struct SignUpView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var displayName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isSubmitting = false

    private var isFormValid: Bool {
        !displayName.trimmingCharacters(in: .whitespaces).isEmpty
        && !email.isEmpty
        && password.count >= 6
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "4361EE"), Color(hex: "9B5DE5"), Color(hex: "FF6B6B")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 16) {
                    TextField("Adın", text: $displayName)
                        .padding()
                        .foregroundStyle(.black)
                        .tint(.black)
                        .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                    TextField("E-posta", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .padding()
                        .foregroundStyle(.black)
                        .tint(.black)
                        .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                    SecureField("Şifre (en az 6 karakter)", text: $password)
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
                            await authViewModel.signUp(email: email, password: password, displayName: displayName)
                            isSubmitting = false
                            if authViewModel.currentUser != nil {
                                dismiss()
                            }
                        }
                    } label: {
                        Group {
                            if isSubmitting {
                                ProgressView().tint(.white)
                            } else {
                                Text("Hesap Oluştur")
                                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                    .background(Color.black.opacity(0.85), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .foregroundStyle(.white)
                    .disabled(!isFormValid || isSubmitting)
                }
                .padding(24)
                .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                .padding(.horizontal, 24)
            }
            .navigationTitle("Kayıt Ol")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç") { dismiss() }
                        .tint(.white)
                }
            }
        }
    }
}

#Preview {
    SignUpView()
        .environment(AuthViewModel())
}
