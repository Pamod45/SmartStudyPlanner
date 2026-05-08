import SwiftUI
import LocalAuthentication
import Combine

// Stores device-only settings in UserDefaults, such as biometric unlock and local accessibility preferences.
// These values are intentionally separate from Firebase user settings.
class LocalSettingsManager: ObservableObject {
    @Published var textSize: Double {
        didSet {
            Self.persistTextSize(textSize)
        }
    }
    
    @Published var reduceMotion: Bool {
        didSet {
            Self.persistReduceMotion(reduceMotion)
        }
    }
    
    @Published var highContrast: Bool {
        didSet {
            Self.persistHighContrast(highContrast)
        }
    }
    
    @Published var faceIDEnabled: Bool {
        didSet {
            Self.persistFaceIDEnabled(faceIDEnabled)
        }
    }
    
    init() {
        self.textSize = UserDefaults.standard.object(forKey: "accessibilityTextSize") as? Double ?? 1.0
        self.reduceMotion = UserDefaults.standard.bool(forKey: "accessibilityReduceMotion")
        self.highContrast = UserDefaults.standard.bool(forKey: "accessibilityHighContrast")
        self.faceIDEnabled = UserDefaults.standard.bool(forKey: "securityFaceIDEnabled")
    }

    static func persistTextSize(_ value: Double) {
        UserDefaults.standard.set(value, forKey: "accessibilityTextSize")
    }

    static func persistReduceMotion(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: "accessibilityReduceMotion")
    }

    static func persistHighContrast(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: "accessibilityHighContrast")
    }

    static func persistFaceIDEnabled(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: "securityFaceIDEnabled")
    }
    
    // Used when enabling Face ID. If authentication fails, the toggle is immediately turned back off.
    func requestBiometricAuth(completion: @escaping (Bool) -> Void) {
        authenticateWithBiometrics { success in
            if !success {
                self.faceIDEnabled = false
            }
            completion(success)
        }
    }

    // Asks iOS to perform biometric authentication and returns the result on the main thread for SwiftUI updates.
    func authenticateWithBiometrics(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Unlock SmartStudyPlanner"
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if let authError = authenticationError {
                        print("Biometric authentication failed: \(authError.localizedDescription)")
                    }
                    completion(success)
                }
            }
        } else {
            DispatchQueue.main.async {
                if let evalError = error {
                    print("Cannot evaluate biometric policy: \(evalError.localizedDescription)")
                } else {
                    print("Cannot evaluate biometric policy: Unknown reason or not available on this device.")
                }
                completion(false)
            }
        }
    }
}
