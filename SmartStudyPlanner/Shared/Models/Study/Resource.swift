import SwiftUI

enum ResourceType: String, CaseIterable, Codable {
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

struct Resource: Identifiable, Codable, Syncable {
    var id: String
    var userId: String
    var subjectId: String
    var name: String
    var resourceType: ResourceType
    var size: String
    var content: String?
    var localFilePath: String?
    var remoteURL: String?
    var fileSize: Int?
    var mimeType: String?
    var tags: [String]
    var isFavorite: Bool
    var createdAt: Date
    var updatedAt: Date
    var syncStatus: SyncStatus

    var type: ResourceType { resourceType }

    init(
        id: String = UUID().uuidString,
        userId: String = "",
        subjectId: String = "",
        name: String,
        resourceType: ResourceType,
        size: String = "",
        content: String? = nil,
        localFilePath: String? = nil,
        remoteURL: String? = nil,
        fileSize: Int? = nil,
        mimeType: String? = nil,
        tags: [String] = [],
        isFavorite: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        syncStatus: SyncStatus = .localOnly
    ) {
        self.id = id
        self.userId = userId
        self.subjectId = subjectId
        self.name = name
        self.resourceType = resourceType
        self.size = size
        self.content = content
        self.localFilePath = localFilePath
        self.remoteURL = remoteURL
        self.fileSize = fileSize
        self.mimeType = mimeType
        self.tags = tags
        self.isFavorite = isFavorite
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.syncStatus = syncStatus
    }
}
