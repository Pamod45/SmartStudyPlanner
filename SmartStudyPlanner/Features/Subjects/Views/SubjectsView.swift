//
//  Subject.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-04-01.
//

import SwiftUI

struct SubjectsView: View {
    @Environment(\.theme) var theme
    @State private var searchText: String = ""

    let subjects: [Subject] = Subject.samples

    var filtered: [Subject] {
        if searchText.isEmpty { return subjects }
        return subjects.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ZStack {
            theme.colors.background
                .ignoresSafeArea()
            VStack(spacing: 0) {
                headerSection
                    .padding(.horizontal, theme.spacing.sm)
                    .padding(.vertical, theme.spacing.md)
                    .background(theme.colors.background)
                
                SearchBar(text: $searchText, placeholder: "Search subjects")
                    .padding(.horizontal, theme.spacing.sm)
                    
                Rectangle().frame(height: theme.spacing.md)
                
                ScrollView {
                    VStack(spacing: theme.spacing.md) {
                        
                        ForEach(filtered) { subject in
                            SubjectCard(subject: subject) {
                            }
                        }
                    }
                    .padding(.horizontal, theme.spacing.sm)
                    .padding(.bottom, theme.spacing.lg)
                }
            }
            
        }
    }
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text("Learning Track")
                    .font(theme.typography.bodyMedium)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.textSecondary)
                    .lineSpacing(2)
                    .textCase(.uppercase)
                
                Text("Subjects")
                    .font(theme.typography.headingMedium)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.textPrimary)
            }
            
            Spacer()
            
            Button { }
            label: {
                Image(systemName: "plus")
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(theme.colors.surface)
                    .clipShape(Circle())
            }
            
            Button { }
            label: {
                Image(systemName: "slider.horizontal.3")
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(theme.colors.surface)
                    .clipShape(Circle())
            }
        }
    }
}

#Preview {
    SubjectsView()
        .environment(\.theme, AppTheme.defaultTheme)
}
