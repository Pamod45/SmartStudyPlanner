//
//  NotificationListView.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-04-02.
//

import SwiftUI

struct NotificationListView: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedType: NotificationType = .all
    @State private var searchText: String = ""
    @State private var editMode: EditMode = .inactive
    @State private var selectedNotifications = Set<AppNotification.ID>()

    private var filteredNotifications: [AppNotification] {
        if selectedType == .all {
            return AppNotification.samples
        } else {
            return AppNotification.samples.filter { $0.notificationType == selectedType }
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
                
                ChipPicker(
                    items: NotificationType.allCases,
                    selection: $selectedType,
                    labelProvider: { $0.rawValue }
                )
                .padding(.horizontal, theme.spacing.sm)
                .padding(.vertical, theme.spacing.md)
                .background(theme.colors.background)

                Rectangle()
                    .fill(Color.clear)
                    .frame(height: theme.spacing.md)
                
                List(selection: $selectedNotifications) {
                    ForEach(filteredNotifications) { notification in
                        NotificationCard(notification: notification) {}
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(
                                top: 0,
                                leading: theme.spacing.sm,
                                bottom: theme.spacing.md,
                                trailing: theme.spacing.sm
                            ))
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    AppNotification.samples.removeAll { $0.id == notification.id }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }.tint(Color.red)
                            }
                    }
                }
                .listStyle(.plain)
                .environment(\.editMode, $editMode)

                
            }
        }
        .toolbar(.hidden)
    }

    private var headerSection: some View {
        HStack {
            Button {
                if editMode == .active {
                    editMode = .inactive
                    selectedNotifications.removeAll()
                } else {
                    dismiss()
                }
            } label: {
                Image(systemName: editMode == .active ? "xmark" : "chevron.left")
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                    .frame(width: 36, height: 36)
                    .glassEffect(.regular, in: Circle())
            }
            
            Spacer()
            Text(editMode == .active ? "\(selectedNotifications.count) Selected" : "Notifications")
                .font(theme.typography.headingMedium)
                .fontWeight(.bold)
                .foregroundColor(theme.colors.textPrimary)
                .animation(.default, value: editMode)
            
            Spacer()
            
            if editMode == .inactive {
                
                Button {
                      withAnimation { editMode = .active }
                }
                label: {
                    Image(systemName: "checkmark.circle")
                        .fontWeight(.semibold)
                        .foregroundColor(theme.colors.primary)
                        .frame(width: 36, height: 36)
                }
                .glassEffect(.regular, in: Circle())
            } else {
                Button {
                    AppNotification.samples.removeAll { selectedNotifications.contains($0.id) }
                    selectedNotifications.removeAll()
                    editMode = .inactive
                } label: {
                    Image(systemName: "trash")
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                        .frame(width: 36, height: 36)
                        .glassEffect(.regular, in: Circle())
                }
            }
        }
    }
}

#Preview {
    NotificationListView()
        .environment(\.theme, AppTheme.defaultTheme)
}
