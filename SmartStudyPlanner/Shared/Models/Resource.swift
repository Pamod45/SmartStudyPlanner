import SwiftUI

enum ResourceType: String, CaseIterable {
    case pdf       = "PDF"
    case ppt       = "PPT"
    case doc       = "DOC"
    case link      = "Link"
    case note      = "Note"
    case scan      = "Scan"
    case recording = "Recording"

    var icon: String {
        switch self {
        case .pdf:       return "doc.richtext.fill"
        case .ppt:       return "arrow.up.doc.fill"
        case .doc:       return "doc.text.fill"
        case .link:      return "link"
        case .note:      return "note.text"
        case .scan:      return "doc.viewfinder.fill"
        case .recording: return "waveform"
        }
    }

    var color: Color {
        switch self {
        case .pdf:       return .red
        case .ppt:       return .blue
        case .doc:       return .indigo
        case .link:      return .orange
        case .note:      return .green
        case .scan:      return .cyan
        case .recording: return .purple
        }
    }
}

struct Resource: Identifiable {
    let id: UUID
    var name: String
    var type: ResourceType
    var size: String
    var subjectID: UUID
    var url: String?
    var noteContent: String?
    var filePath: String?

    init(
        id: UUID = UUID(),
        name: String,
        type: ResourceType,
        size: String = "",
        subjectID: UUID = UUID(),
        url: String? = nil,
        noteContent: String? = nil,
        filePath: String? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.size = size
        self.subjectID = subjectID
        self.url = url
        self.noteContent = noteContent
        self.filePath = filePath
    }

    static func samples(for subjectID: UUID) -> [Resource] {
        [
            Resource(name: "SwiftUI Basics",       type: .pdf,       size: "2.4 MB",  subjectID: subjectID),
            Resource(name: "Architecture Slides",  type: .ppt,       size: "15.1 MB", subjectID: subjectID),
            Resource(name: "Lecture Notes",        type: .note,      size: "",        subjectID: subjectID),
            Resource(name: "API Documentation",    type: .link,      size: "",        subjectID: subjectID, url: "https://developer.apple.com"),
            Resource(name: "Whiteboard Capture",   type: .scan,      size: "1.2 MB",  subjectID: subjectID),
            Resource(name: "Lecture Recording",    type: .recording, size: "45 min",  subjectID: subjectID)
        ]
    }
}
