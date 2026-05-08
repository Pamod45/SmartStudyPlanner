import SwiftUI

struct Shortcut: Identifiable {
    var id: String
    let title: String
    let icon: String
    let color: Color

    init(id: String = UUID().uuidString, title: String, icon: String, color: Color) {
        self.id = id
        self.title = title
        self.icon = icon
        self.color = color
    }
}
