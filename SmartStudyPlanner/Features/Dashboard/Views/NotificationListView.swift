//
//  NotificationListView.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-04-02.
//

import SwiftUI

// Full notification history view with filtering, search, read state, and bulk delete controls.

struct NotificationListView: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var notificationStore: NotificationStore
    @EnvironmentObject var sessionVM: SessionViewModel

    @State private var selectedType: NotificationType = .all
    @State private var searchText: String = ""
    @State private var editMode: EditMode = .inactive
    @State private var selectedIds = Set<AppNotification.ID>()

    private let visibleTypes: [NotificationType] = [.all, .study, .deadline, .quiz]

    private var userNotifications: [AppNotification] {
        notificationStore.notifications(for: sessionVM.activeUserId)
    }

    private var userUnreadCount: Int {
        notificationStore.unreadCount(for: sessionVM.activeUserId)
    }

    // Applies the selected notification type and search text without changing the stored history.
    private var filteredNotifications: [AppNotification] {
        let base = selectedType == .all
            ? userNotifications
            : userNotifications.filter { $0.notificationType == selectedType }
        if searchText.isEmpty { return base }
        return base.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.message.localizedCaseInsensitiveContains(searchText)
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
                    items: visibleTypes,
                    selection: $selectedType,
                    labelProvider: { $0.rawValue }
                )
                .padding(.horizontal, theme.spacing.sm)
                .padding(.vertical, theme.spacing.md)
                .background(theme.colors.background)

                Rectangle()
                    .fill(Color.clear)
                    .frame(height: theme.spacing.md)

                if filteredNotifications.isEmpty {
                    emptyState
                } else {
                    List(selection: $selectedIds) {
                        ForEach(filteredNotifications) { notification in
                            NotificationCard(notification: notification) {
                                notificationStore.markRead(id: notification.id)
                            }
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
                                    notificationStore.delete(id: notification.id)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }.tint(Color.red)
                            }
                            .swipeActions(edge: .leading) {
                                if !notification.isRead {
                                    Button {
                                        notificationStore.markRead(id: notification.id)
                                    } label: {
                                        Label("Read", systemImage: "envelope.open")
                                    }.tint(theme.colors.primary)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .environment(\.editMode, $editMode)
                }
            }
        }
        .toolbar(.hidden)
    }


    private var headerSection: some View {
        HStack {
            Button {
                if editMode == .active {
                    editMode = .inactive
                    selectedIds.removeAll()
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

            VStack(spacing: 2) {
                Text(editMode == .active ? "\(selectedIds.count) Selected" : "Notifications")
                    .font(theme.typography.headingMedium)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.textPrimary)
                    .animation(.default, value: editMode)
                if userUnreadCount > 0 && editMode == .inactive {
                    Text("\(userUnreadCount) unread")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.primary)
                }
            }

            Spacer()

            if editMode == .inactive {
                HStack(spacing: theme.spacing.sm) {
                    if userUnreadCount > 0 {
                        Button {
                            notificationStore.markAllRead(userId: sessionVM.activeUserId)
                        } label: {
                            Image(systemName: "envelope.open")
                                .fontWeight(.semibold)
                                .foregroundColor(theme.colors.primary)
                                .frame(width: 36, height: 36)
                        }
                        .glassEffect(.regular, in: Circle())
                    }
                    Button {
                        withAnimation { editMode = .active }
                    } label: {
                        Image(systemName: "checkmark.circle")
                            .fontWeight(.semibold)
                            .foregroundColor(theme.colors.primary)
                            .frame(width: 36, height: 36)
                    }
                    .glassEffect(.regular, in: Circle())
                }
            } else {
                Button {
                    notificationStore.delete(ids: selectedIds)
                    selectedIds.removeAll()
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


    private var emptyState: some View {
        VStack(spacing: theme.spacing.lg) {
            Spacer()
            Image(systemName: "bell.slash")
                .font(.system(size: 48))
                .foregroundColor(theme.colors.textSecondary.opacity(0.5))
            Text("No Notifications")
                .font(theme.typography.headingMedium)
                .foregroundColor(theme.colors.textSecondary)
            Text("Notifications about your sessions,\ndeadlines and quizzes will appear here.")
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.colors.textSecondary.opacity(0.7))
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(theme.spacing.xl)
    }
}

#Preview {
    NotificationListView()
        .environmentObject(NotificationStore.shared)
        .environmentObject(SessionViewModel())
        .environment(\.theme, AppTheme.defaultTheme)
}
