//
//  JoinDepoSheet.swift
//  Epilogue
//
//  Created by Zehra Öner on 20.07.2026.
//

import SwiftUI

struct JoinDepoSheet: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(\.dismiss) private var dismiss
    var depoViewModel: DepoViewModel

    @State private var code = ""
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Davet Kodu") {
                    TextField("Örn: A1B2C3", text: $code)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                }
                if let error = depoViewModel.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
            .navigationTitle("Depoya Katıl")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Katıl") {
                        guard let userId = authViewModel.currentUser?.id else { return }
                        Task {
                            isSubmitting = true
                            await depoViewModel.joinDepo(inviteCode: code, userId: userId)
                            isSubmitting = false
                            if depoViewModel.errorMessage == nil {
                                dismiss()
                            }
                        }
                    }
                    .disabled(code.trimmingCharacters(in: .whitespaces).isEmpty || isSubmitting)
                }
            }
        }
    }
}

#Preview {
    JoinDepoSheet(depoViewModel: DepoViewModel())
        .environment(AuthViewModel())
}
