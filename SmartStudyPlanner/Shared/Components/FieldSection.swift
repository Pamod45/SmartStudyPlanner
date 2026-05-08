//
//  FieldSection.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-04-07.
//
import SwiftUI

struct FieldSection<Content: View>: View {
    
    let title: String
    let content: Content
    @Environment(\.theme) var theme
    
    init(title: String,
         @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            Text(title)
                .font(theme.typography.caption.weight(.bold))
                .foregroundColor(theme.colors.textPrimary)
                .tracking(2)
            
            content
//                .frame(maxWidth: .infinity)
//                .frame(height: 48)
               // .background(Color.red)
        }
    }
}
