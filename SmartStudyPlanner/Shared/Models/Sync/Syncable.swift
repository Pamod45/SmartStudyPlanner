import Foundation

protocol Syncable {
    var id: String { get }
    var userId: String { get }
    var syncStatus: SyncStatus { get set }
    var updatedAt: Date { get }
}
