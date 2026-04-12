//
//  ProfileEditView.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-04-12.
//

import SwiftUI
import PhotosUI

struct ProfileEditView: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss

    @Binding var user: SettingsUser

    @State private var name: String
    @State private var email: String
    @State private var domain: String
    @State private var institute: String
    @State private var username: String
    @State private var avatarImage: UIImage?

    @State private var photoPickerItem: PhotosPickerItem? = nil
    @State private var showDeleteConfirm: Bool = false

    init(user: Binding<SettingsUser>) {
        _user = user
        _name = State(initialValue: user.wrappedValue.name)
        _email = State(initialValue: user.wrappedValue.email)
        _domain = State(initialValue: user.wrappedValue.domain)
        _institute = State(initialValue: user.wrappedValue.institute)
        _username = State(initialValue: user.wrappedValue.username)
        _avatarImage = State(initialValue: user.wrappedValue.avatarImage)
    }

    var body: some View {
        ZStack {
            theme.colors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerSection
                    .padding(.horizontal, theme.spacing.sm)
                    .padding(.top, theme.spacing.md)
                    .padding(.bottom, theme.spacing.lg)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: theme.spacing.lg) {
                        avatarSection
                        fieldsSection
                        saveButton
                        Spacer(minLength: theme.spacing.xxl + 8)
                        deleteButton
                    }
                    .padding(.horizontal, theme.spacing.sm)
                    .padding(.bottom, theme.spacing.md)
                }
            }
        }
        .navigationBarHidden(true)
        .onChange(of: photoPickerItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    avatarImage = uiImage
                }
            }
        }
        .alert("Delete Account", isPresented: $showDeleteConfirm) {
            Button("Delete Account", role: .destructive) {
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to permanently delete your account? This action cannot be undone.")
        }
    }

    private var headerSection: some View {
        HStack {
            RoundedIconButton(icon: "chevron.left") {
                dismiss()
            }
            Spacer()
            Text("Settings")
                .font(theme.typography.headingMedium.weight(.bold))
                .foregroundColor(theme.colors.textPrimary)
            Spacer()
            RoundedIconButton(icon:""){}.opacity(0)
        }
    }

    private var avatarSection: some View {
        HStack {
            Spacer()
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if let img = avatarImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                    } else {
                        ZStack {
                            Circle()
                                .fill(theme.colors.onSurface)
                            Image(systemName: "person.fill")
                                .font(.system(size: 48))
                                .foregroundColor(theme.colors.textSecondary)
                        }
                    }
                }
                .frame(width: 110, height: 110)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(theme.colors.border.opacity(0.4), lineWidth: 2)
                )

                PhotosPicker(selection: $photoPickerItem, matching: .images, photoLibrary: .shared()) {
                    ZStack {
                        Circle()
                            .fill(theme.colors.primary)
                            .frame(width: 34, height: 34)
                        Image(systemName: "camera.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(theme.colors.textOnPrimary)
                    }
                }
                .offset(x: 4, y: 4)
            }
            Spacer()
        }
    }

    private var fieldsSection: some View {
        VStack(spacing: 0) {
            profileRow(label: "Full Name", value: $name)
            Divider()
                .background(theme.colors.border.opacity(0.4))
                .padding(.leading, theme.spacing.md)
            profileRow(label: "Email", value: $email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
            Divider()
                .background(theme.colors.border.opacity(0.4))
                .padding(.leading, theme.spacing.md)
            profileRow(label: "Domain", value: $domain)
            Divider()
                .background(theme.colors.border.opacity(0.4))
                .padding(.leading, theme.spacing.md)
            profileRow(label: "Institute", value: $institute)
            Divider()
                .background(theme.colors.border.opacity(0.4))
                .padding(.leading, theme.spacing.md)
            profileRow(label: "User name", value: $username)
                .autocapitalization(.none)
        }
        .background(theme.colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radius.xl)
                .stroke(theme.colors.border.opacity(0.4), lineWidth: 1)
        )
    }

    private func profileRow(label: String, value: Binding<String>) -> some View {
        HStack(spacing: theme.spacing.md) {
            Text(label)
                .font(theme.typography.bodyMedium.weight(.medium))
                .foregroundColor(theme.colors.textSecondary)
                .frame(width: 100, alignment: .leading)

            TextField("", text: value)
                .font(theme.typography.bodyLarge.weight(.semibold))
                .foregroundColor(theme.colors.textPrimary)
                .multilineTextAlignment(.trailing)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, theme.spacing.md)
        .padding(.vertical, theme.spacing.md)
    }

    private var saveButton: some View {
        PrimaryButton(title: "Save Changes") {
            user.name = name
            user.email = email
            user.domain = domain
            user.institute = institute
            user.username = username
            user.avatarImage = avatarImage
        }
    }

    private var deleteButton: some View {
        Button {
            showDeleteConfirm = true
        } label: {
            Text("Delete Account")
                .font(theme.typography.bodyLarge.weight(.semibold))
                .foregroundColor(theme.colors.error)
                .frame(maxWidth: .infinity)
                .padding(.vertical, theme.spacing.md)
                .background(theme.colors.surface)
                .cornerRadius(theme.radius.xl)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        ProfileEditView(user: .constant(SettingsUser(
            name: "Pubudu Perera",
            email: "pubudu@gmail.com",
            domain: "Software Engineering",
            institute: "NIBM",
            username: "Pubudu@45"
        )))
    }
    .environmentObject(ThemeManager())
    .environment(\.theme, AppTheme.defaultTheme)
}
