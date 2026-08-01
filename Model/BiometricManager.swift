import Foundation
internal import LocalAuthentication

@Observable
class BiometricManager {
    var isUnlocked = false
    var authError: String?
    
    var biometricType: LABiometryType {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return context.biometryType
    }
    
    var biometricName: String {
        switch biometricType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        default: return "Biyometrik"
        }
    }
    
    var canUseBiometrics: Bool {
        let context = LAContext()
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }
    
    func authenticate() {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            authError = error?.localizedDescription ?? "Biyometrik doğrulama kullanılamıyor."
            return
        }
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Stash uygulamanızı açmak için doğrulama yapın.") { success, authenticationError in
            DispatchQueue.main.async {
                if success {
                    self.isUnlocked = true
                    self.authError = nil
                } else {
                    self.authError = authenticationError?.localizedDescription ?? "Doğrulama başarısız."
                }
            }
        }
    }
}
