import SwiftUI
import LocalAuthentication
import Combine

class LocalSettingsManager: ObservableObject {
    @Published var textSize: Double {
        didSet {
            UserDefaults.standard.set(textSize, forKey: "accessibilityTextSize")
        }
    }
    
    @Published var reduceMotion: Bool {
        didSet {
            UserDefaults.standard.set(reduceMotion, forKey: "accessibilityReduceMotion")
        }
    }
    
    @Published var highContrast: Bool {
        didSet {
            UserDefaults.standard.set(highContrast, forKey: "accessibilityHighContrast")
        }
    }
    
    @Published var faceIDEnabled: Bool {
        didSet {
            UserDefaults.standard.set(faceIDEnabled, forKey: "securityFaceIDEnabled")
        }
    }
    
    init() {
        self.textSize = UserDefaults.standard.object(forKey: "accessibilityTextSize") as? Double ?? 1.0
        self.reduceMotion = UserDefaults.standard.bool(forKey: "accessibilityReduceMotion")
        self.highContrast = UserDefaults.standard.bool(forKey: "accessibilityHighContrast")
        self.faceIDEnabled = UserDefaults.standard.bool(forKey: "securityFaceIDEnabled")
    }
    
    func requestBiometricAuth(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Unlock SmartStudyPlanner"
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        completion(true)
                    } else {
                        completion(false)
                        self.faceIDEnabled = false
                    }
                }
            }
        } else {
            DispatchQueue.main.async {
                completion(false)
                self.faceIDEnabled = false
            }
        }
    }
}
