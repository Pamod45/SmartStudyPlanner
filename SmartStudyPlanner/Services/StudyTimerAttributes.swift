import ActivityKit
import Foundation

struct StudyTimerAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var startDate: Date
    }

    var sessionId: String
    var sessionTitle: String
    var subjectName: String
    var subjectColorHex: String
}
