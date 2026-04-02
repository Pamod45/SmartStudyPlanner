//
//  NotificationListView.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-04-02.
//

//
//  DashboardView.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-04-01.
//
import SwiftUI

struct NotificationListView: View {
    @Environment(\.theme) var theme
    @State private var notifications: [AppNotification] = AppNotification.samples

    var body: some View {
        ZStack {
            theme.colors.background
                .ignoresSafeArea()
            VStack(spacing: 0) {
                headerSection
                    .padding(.horizontal, theme.spacing.sm)
                    .padding(.vertical, theme.spacing.md)
                    .background(theme.colors.background)
                    
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: theme.spacing.md)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: theme.spacing.md) {
                        ForEach(AppNotification.samples) { notification in
                            NotificationCard(notification: notification) {
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
            HStack (spacing: theme.spacing.md){
                Button {  }
                label: {
                        Image(systemName: "chevron.left")
                            .fontWeight(.semibold)
                            .foregroundColor(theme.colors.textPrimary)
                            .frame(width: 36, height: 36)
                            .background(theme.colors.surface)
                            .clipShape(Circle())
                }
               

                Text("Notifications")
                    .font(theme.typography.headingMedium)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.textPrimary)
            }
            
            
            Spacer()
            
            Button {  }
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
    NotificationListView()
        .environment(\.theme, AppTheme.defaultTheme)
}
