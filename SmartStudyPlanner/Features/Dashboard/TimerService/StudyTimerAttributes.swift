import ActivityKit
import Foundation

// Data passed to ActivityKit so the active study timer can appear as a Live Activity.
struct StudyTimerAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var startDate: Date
    }

    var sessionId: String
    var sessionTitle: String
    var subjectName: String
    var subjectColorHex: String
}
