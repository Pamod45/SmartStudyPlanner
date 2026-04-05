import SwiftUI

enum ResourceType: String, CaseIterable {
    case pdf  = "PDF"
    case ppt  = "PPT"
    case doc  = "DOC"
    case link = "Link"
    case note = "Note"

    var icon: String {
        switch self {
        case .pdf:  return "doc.richtext.fill"
        case .ppt:  return "arrow.up.doc.fill"
        case .doc:  return "doc.text.fill"
        case .link: return "link"
        case .note: return "note.text"
        }
    }

    var color: Color {
        switch self {
        case .pdf:  return .red
        case .ppt:  return .blue
        case .doc:  return .indigo
        case .link: return .orange
        case .note: return .green
        }
    }
}

struct Resource: Identifiable {
    let id: UUID
    var name: String
    var type: ResourceType
    var size: String
    var subjectID: UUID

    init(id: UUID = UUID(), name: String, type: ResourceType, size: String = "", subjectID: UUID = UUID()) {
        self.id = id
        self.name = name
        self.type = type
        self.size = size
        self.subjectID = subjectID
    }

    static func samples(for subjectID: UUID) -> [Resource] {
        [
            Resource(name: "SwiftUI Basics", type: .pdf, size: "2.4 MB", subjectID: subjectID),
            Resource(name: "Architecture Slides", type: .ppt, size: "15.1 MB", subjectID: subjectID)
        ]
    }
}
