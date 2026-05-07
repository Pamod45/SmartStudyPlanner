import Foundation

final class StudyScheduleService {
    static let shared = StudyScheduleService()
    private init() {}

    struct SubjectEntry {
        let subject: Subject
        let topics: [StudyPathTopic]
        let nearestDeadline: Date?
    }
    func schedule(
        entries: [SubjectEntry],
        slots: [AvailabilitySlot],
        period: DateInterval,
        breakMinutes: Int = 10,
        minSessionMinutes: Int = 30
    ) -> [StudySession] {

        let blocks = expandSlots(slots, over: period)
        guard !blocks.isEmpty else { return [] }

        var queue = buildQueue(entries: entries)
        guard !queue.isEmpty else { return [] }

        return fillBlocks(
            blocks: blocks,
            queue: &queue,
            breakMinutes: breakMinutes,
            minSessionMinutes: minSessionMinutes
        )
    }

    private struct ConcreteBlock {
        let date: Date
        let start: Date
        let end: Date
    }

    private func expandSlots(_ slots: [AvailabilitySlot], over period: DateInterval) -> [ConcreteBlock] {
        let cal = Calendar.current
        var blocks: [ConcreteBlock] = []
        var current = cal.startOfDay(for: period.start)
        let last    = cal.startOfDay(for: period.end)

        while current <= last {
            for slot in slots where slot.applies(on: current) {
                guard let start = cal.date(
                    bySettingHour:   cal.component(.hour,   from: slot.startTime),
                    minute:          cal.component(.minute, from: slot.startTime),
                    second: 0, of: current
                ), let end = cal.date(
                    bySettingHour:   cal.component(.hour,   from: slot.endTime),
                    minute:          cal.component(.minute, from: slot.endTime),
                    second: 0, of: current
                ), end > start else { continue }

                blocks.append(ConcreteBlock(date: current, start: start, end: end))
            }
            current = cal.date(byAdding: .day, value: 1, to: current) ?? current.addingTimeInterval(86_400)
        }

        return blocks.sorted { $0.start < $1.start }
    }

    private struct QueueEntry {
        let topic: StudyPathTopic
        let subject: Subject
        let nearestDeadline: Date?
        var remainingMinutes: Int
        let priorityScore: Double
    }

    private func buildQueue(entries: [SubjectEntry]) -> [QueueEntry] {
        let today = Date()
        var queue: [QueueEntry] = []

        for entry in entries {
            let deadlinePressure: Double
            if let d = entry.nearestDeadline, d > today {
                let days = max(1.0, d.timeIntervalSince(today) / 86_400)
                deadlinePressure = 100.0 / days
            } else {
                deadlinePressure = 0
            }

            for topic in entry.topics {
                let minutes = topic.estimatedMinutes > 0 ? topic.estimatedMinutes : max(30, topic.weightPercent * 6)
                let score   = deadlinePressure * 3 + Double(topic.difficultyLevel) * 2 + Double(topic.weightPercent)
                queue.append(QueueEntry(
                    topic:            topic,
                    subject:          entry.subject,
                    nearestDeadline:  entry.nearestDeadline,
                    remainingMinutes: minutes,
                    priorityScore:    score
                ))
            }
        }

        return queue.sorted { $0.priorityScore > $1.priorityScore }
    }

    private func fillBlocks(
        blocks: [ConcreteBlock],
        queue: inout [QueueEntry],
        breakMinutes: Int,
        minSessionMinutes: Int
    ) -> [StudySession] {

        var sessions: [StudySession] = []
        var topicIndex = 0

        for block in blocks {
            guard topicIndex < queue.count else { break }

            var cursor = block.start

            while topicIndex < queue.count {
                let availableMinutes = Int(block.end.timeIntervalSince(cursor) / 60)
                guard availableMinutes >= minSessionMinutes else { break }

                let sessionDuration = min(queue[topicIndex].remainingMinutes, availableMinutes)
                guard sessionDuration >= minSessionMinutes else {
                    topicIndex += 1
                    continue
                }

                let sessionEnd = cursor.addingTimeInterval(TimeInterval(sessionDuration * 60))
                let entry = queue[topicIndex]

                sessions.append(StudySession(
                    subjectId:       entry.subject.id,
                    subjectName:     entry.subject.name,
                    subjectColorHex: entry.subject.colorHex,
                    title:           entry.topic.title,
                    topic:           entry.topic.title,
                    scheduledDate:   block.date,
                    startTime:       cursor,
                    endTime:         sessionEnd,
                    status:          .scheduled,
                    sessionType:     .focused,
                    resourceIds:     entry.topic.resourceIds,
                    topicIds:        [entry.topic.id]
                ))

                queue[topicIndex].remainingMinutes -= sessionDuration
                if queue[topicIndex].remainingMinutes <= 0 {
                    topicIndex += 1
                }

                cursor = sessionEnd.addingTimeInterval(TimeInterval(breakMinutes * 60))
            }
        }

        return sessions
    }
}
