import Foundation

// Builds study sessions from selected topics and availability slots.
// This service only decides where sessions should go; saving and UI updates happen in the study plan view model.
final class StudyScheduleService {
    static let shared = StudyScheduleService()
    private init() {}

    struct SubjectEntry {
        let subject: Subject
        let topics: [StudyPathTopic]
        let nearestDeadline: Date?
    }
    // Turns selected subjects/topics into scheduled sessions inside the selected date period.
    // Empty slots or empty topic selections return an empty result so the UI can show a validation message.
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

    // Expands repeating/range-style availability into concrete calendar blocks that the scheduler can fill.
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

    // Creates a priority queue from topics. Subjects with higher deadline pressure go first.
    // Within each subject, topics always follow their defined curriculum order so topic N never precedes topic N-1.
    private func buildQueue(entries: [SubjectEntry]) -> [QueueEntry] {
        let today = Date()
        var subjectGroups: [(priority: Double, topics: [QueueEntry])] = []

        for entry in entries {
            let deadlinePressure: Double
            if let d = entry.nearestDeadline, d > today {
                let days = max(1.0, d.timeIntervalSince(today) / 86_400)
                deadlinePressure = 100.0 / days
            } else {
                deadlinePressure = 0
            }

            let subjectScore = deadlinePressure * 3
            let orderedTopics = entry.topics.sorted { $0.order < $1.order }
            let groupEntries = orderedTopics.map { topic -> QueueEntry in
                let minutes = topic.estimatedMinutes > 0 ? topic.estimatedMinutes : max(30, topic.weightPercent * 6)
                return QueueEntry(
                    topic:            topic,
                    subject:          entry.subject,
                    nearestDeadline:  entry.nearestDeadline,
                    remainingMinutes: minutes,
                    priorityScore:    subjectScore
                )
            }
            subjectGroups.append((priority: subjectScore, topics: groupEntries))
        }

        // Round-robin across subjects so sessions alternate between subjects rather than
        // exhausting one subject before moving to the next. Within each subject the
        // topics stay in their sorted curriculum order.
        let sortedGroups = subjectGroups.sorted { $0.priority > $1.priority }
        let maxCount = sortedGroups.map(\.topics.count).max() ?? 0
        var result: [QueueEntry] = []
        for round in 0..<maxCount {
            for group in sortedGroups where round < group.topics.count {
                result.append(group.topics[round])
            }
        }
        return result
    }

    // Walks through each availability block and fills it with topic work while leaving breaks between sessions.
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
                guard sessionDuration > 0 else {
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
