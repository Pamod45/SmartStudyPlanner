//
//  SettingsModels.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-04-11.
//

import SwiftUI

struct SettingsUser {
    var name: String
    var degree: String
    var avatarSystemImage: String = "person.crop.circle.fill"
}

enum SettingsRowType {
    case toggle(binding: Binding<Bool>)
    case navigation(action: () -> Void)
}

struct SettingsSection: Identifiable {
    let id = UUID()
    let rows: [SettingsRowItem]
}

struct SettingsRowItem: Identifiable {
    let id = UUID()
    let icon: String
    let iconColor: Color
    let title: String
    let type: SettingsRowKind
}

enum SettingsRowKind {
    case toggle
    case navigation
    case destructive
}
