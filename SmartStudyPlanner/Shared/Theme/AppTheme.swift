//
//  AppTheme.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-03-31.
//

import SwiftUI

struct AppTheme {
    let colors: ThemeColors
    let typography: ThemeTypography
    let spacing: ThemeSpacing
    let radius: ThemeRadius
}

struct ThemeColors {
    let primary: Color
    let secondary: Color
    let background: Color
    let surface: Color
    let error: Color
    let textPrimary: Color
    let textSecondary: Color
    let textOnPrimary: Color
    let border: Color
    let success: Color
}

struct ThemeTypography {
    let displayLarge: Font
    let displayMedium: Font
    let headingLarge: Font
    let headingMedium: Font
    let headingSmall: Font
    let bodyLarge: Font
    let bodyMedium: Font
    let bodySmall: Font
    let caption: Font
    let label: Font
}

struct ThemeSpacing {
    let xs: CGFloat
    let sm: CGFloat
    let m: CGFloat
    let md: CGFloat
    let lg: CGFloat
    let xl: CGFloat
    let xxl: CGFloat
}

struct ThemeRadius {
    let sm: CGFloat
    let md: CGFloat
    let lg: CGFloat
    let xl: CGFloat
    let full: CGFloat
}

extension AppTheme {
    static let defaultTheme = AppTheme(
        colors: ThemeColors(
            primary: Color(hex: "#44A5FF"),
            secondary: Color(hex: "#1F1F23"),
            background: Color(hex: "#0A0A0B"),
            surface: Color(hex: "#1F1F23"),
            error: Color(hex: "#EF4444"),
            textPrimary: Color(hex: "#E7E5E4"),
            textSecondary: Color(hex: "#ACABAA"),
            textOnPrimary: Color(hex: "#002442"),
            border: Color(hex: "#444444"),
            success: Color(hex: "#22C55E")
        ),
        typography: ThemeTypography(
            displayLarge: .custom("SF Pro Display", size: 40, weight: .bold),
            displayMedium: .custom("SF Pro Display", size: 32, weight: .bold),
            headingLarge: .custom("SF Pro Display", size: 28, weight: .semibold),
            headingMedium: .custom("SF Pro Display", size: 22, weight: .semibold),
            headingSmall: .custom("SF Pro Display", size: 18, weight: .semibold),
            bodyLarge: .custom("SF Pro Text", size: 16, weight: .regular),
            bodyMedium: .custom("SF Pro Text", size: 14, weight: .regular),
            bodySmall: .custom("SF Pro Text", size: 13, weight: .regular),
            caption: .custom("SF Pro Text", size: 12, weight: .regular),
            label: .custom("SF Pro Text", size: 11, weight: .medium)
        ),
        spacing: ThemeSpacing(xs: 4, sm: 8, m: 12, md: 16, lg: 24, xl: 32,  xxl: 48),
        radius: ThemeRadius(sm: 8, md: 12, lg: 16, xl: 24, full: 999)
    )
}
