//
//  ThemeManager.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-03-31.
//

import Foundation
import Combine
import SwiftUI

class ThemeManager: ObservableObject {
    @Published var current: AppTheme = .defaultTheme
    @Published var isDarkMode: Bool = true
    
    func update(highContrast: Bool, darkMode: Bool, fontSize: Double) {
        let baseTheme: AppTheme
        if highContrast && darkMode {
            baseTheme = .highContrastTheme
        } else if !darkMode {
            baseTheme = .lightTheme
        } else {
            baseTheme = .defaultTheme
        }
        
        current = baseTheme.scaled(by: fontSize)
        isDarkMode = darkMode
    }
}

private struct ThemeKey: EnvironmentKey {
    static let defaultValue: AppTheme = .defaultTheme
}

extension EnvironmentValues {
    var theme: AppTheme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}
