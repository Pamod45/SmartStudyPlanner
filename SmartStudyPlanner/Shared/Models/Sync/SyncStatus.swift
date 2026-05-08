import Foundation

enum SyncStatus: String, Codable {
    case localOnly
    case pendingUpload
    case synced
    case pendingUpdate
    case pendingDelete
    case conflicted
}
