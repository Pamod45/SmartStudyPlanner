import SwiftUI

struct StatItem {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String
    let badge: String?
    let badgeColor: Color

    init(icon: String, iconColor: Color, value: String, label: String, badge: String? = nil, badgeColor: Color = .blue) {
        self.icon = icon
        self.iconColor = iconColor
        self.value = value
        self.label = label
        self.badge = badge
        self.badgeColor = badgeColor
    }
}

enum SubjectStatus: String {
    case excellent   = "EXCELLENT"
    case good        = "GOOD"
    case needsFocus  = "NEEDS FOCUS"

    var color: Color {
        switch self {
        case .excellent:  return Color(hex: "#44A5FF")
        case .good:       return Color(hex: "#22C55E")
        case .needsFocus: return Color(hex: "#F97316")
        }
    }
}

struct SubjectProgress {
    let name: String
    let subtitle: String
    let mastery: Double
    let status: SubjectStatus
    let color: Color
}

struct InsightItem {
    let tag: String
    let tagColor: Color
    let title: String
    let body: String
    let icon: String
}

struct DailyActivity: Identifiable {
    let id = UUID()
    let day: String
    let date: Date
    let hours: Double
    let subject: String
    let color: Color
}

struct SubjectDistribution {
    let name: String
    let percentage: Double
    let color: Color
}

struct ResourceUtilization {
    let type: String
    let icon: String
    let count: Int
    let color: Color
}

extension StatItem {
    static let samples: [StatItem] = [
        StatItem(icon: "clock.fill",         iconColor: Color(hex: "#44A5FF"), value: "42.5", label: "STUDY HOURS",   badge: "+12%",  badgeColor: Color(hex: "#44A5FF")),
        StatItem(icon: "chart.bar.fill",      iconColor: Color(hex: "#F97316"), value: "94%",  label: "AVG SCORE",    badge: "TOP 5%", badgeColor: Color(hex: "#F97316")),
        StatItem(icon: "checkmark.circle.fill",iconColor: Color(hex: "#44A5FF"), value: "18",   label: "TOPICS DONE",  badge: nil,     badgeColor: .clear),
        StatItem(icon: "flame.fill",          iconColor: Color(hex: "#F97316"), value: "14 days", label: "CURRENT STREAK", badge: nil, badgeColor: .clear)
    ]
}

extension SubjectProgress {
    static let samples: [SubjectProgress] = [
        SubjectProgress(name: "iOS Development",  subtitle: "SWIFTUI & COMBINE",       mastery: 0.88, status: .excellent,  color: Color(hex: "#44A5FF")),
        SubjectProgress(name: "Web APIs",         subtitle: "REST & GRAPHQL",           mastery: 0.72, status: .good,       color: Color(hex: "#22C55E")),
        SubjectProgress(name: "Data Structures",  subtitle: "BINARY TREES & SORTING",  mastery: 0.45, status: .needsFocus, color: Color(hex: "#F97316"))
    ]
}

extension InsightItem {
    static let samples: [InsightItem] = [
        InsightItem(
            tag: "TOP PERFORMANCE",
            tagColor: Color(hex: "#44A5FF"),
            title: "Logical Reasoning",
            body: "Your consistency in problem-solving has increased by 22% this week. You excel at complex architectural patterns.",
            icon: "arrow.up.right"
        ),
        InsightItem(
            tag: "FOCUS NEEDED",
            tagColor: Color(hex: "#F97316"),
            title: "Time Complexity",
            body: "Average response time for Big O notation questions is higher than your peer group. Consider a deep dive into Algorithms.",
            icon: "exclamationmark.triangle"
        )
    ]
}

extension DailyActivity {
    static let allSamples: [DailyActivity] = {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let subjects: [(String, Color, [Double])] = [
            ("iOS Development", Color(hex: "#44A5FF"), [1.5, 2.0, 1.0, 0.5, 2.5, 3.0, 2.0]),
            ("Data Structures", Color(hex: "#A78BFA"), [0.5, 1.0, 1.2, 0.8, 1.0, 1.5, 1.2]),
            ("Web APIs",        Color(hex: "#22C55E"), [0.0, 0.5, 0.6, 0.2, 0.7, 1.3, 1.5]),
            ("Algorithms",      Color(hex: "#F97316"), [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
        ]
        let days = ["MON","TUE","WED","THU","FRI","SAT","SUN"]
        var result: [DailyActivity] = []
        for (name, color, hours) in subjects {
            for i in 0..<7 {
                let date = cal.date(byAdding: .day, value: i - 6, to: today) ?? today
                result.append(DailyActivity(day: days[i], date: date, hours: hours[i], subject: name, color: color))
            }
        }
        return result
    }()

    static let monthSamples: [DailyActivity] = {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let subjects: [(String, Color)] = [
            ("iOS Development", Color(hex: "#44A5FF")),
            ("Data Structures", Color(hex: "#A78BFA")),
            ("Web APIs",        Color(hex: "#22C55E")),
            ("Algorithms",      Color(hex: "#F97316"))
        ]
        var result: [DailyActivity] = []
        for (name, color) in subjects {
            for i in 0..<30 {
                let date = cal.date(byAdding: .day, value: i - 29, to: today) ?? today
                let weekday = cal.component(.weekday, from: date)
                let isWeekend = weekday == 1 || weekday == 7
                let base: Double = isWeekend ? Double.random(in: 1.5...4.0) : Double.random(in: 0.5...3.0)
                let dayLabel = "\(i+1)"
                result.append(DailyActivity(day: dayLabel, date: date, hours: (base * 10).rounded() / 10, subject: name, color: color))
            }
        }
        return result
    }()

    static let quarterSamples: [DailyActivity] = {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let subjects: [(String, Color)] = [
            ("iOS Development", Color(hex: "#44A5FF")),
            ("Data Structures", Color(hex: "#A78BFA")),
            ("Web APIs",        Color(hex: "#22C55E")),
            ("Algorithms",      Color(hex: "#F97316"))
        ]
        var result: [DailyActivity] = []
        for (name, color) in subjects {
            for i in 0..<13 {
                let date = cal.date(byAdding: .weekOfYear, value: i - 12, to: today) ?? today
                let hours = Double.random(in: 5.0...25.0)
                let weekLabel = "W\(i+1)"
                result.append(DailyActivity(day: weekLabel, date: date, hours: (hours * 10).rounded() / 10, subject: name, color: color))
            }
        }
        return result
    }()

    static let samples: [DailyActivity] = allSamples
}

extension SubjectDistribution {
    static let samples: [SubjectDistribution] = [
        SubjectDistribution(name: "iOS Development", percentage: 0.40, color: Color(hex: "#44A5FF")),
        SubjectDistribution(name: "Data Structures",  percentage: 0.28, color: Color(hex: "#A78BFA")),
        SubjectDistribution(name: "Web APIs",         percentage: 0.20, color: Color(hex: "#22C55E")),
        SubjectDistribution(name: "Algorithms",       percentage: 0.12, color: Color(hex: "#F97316"))
    ]
}

extension ResourceUtilization {
    static let samples: [ResourceUtilization] = [
        ResourceUtilization(type: "PDFs",       icon: "doc.richtext.fill",    count: 14, color: Color(hex: "#EF4444")),
        ResourceUtilization(type: "Notes",      icon: "note.text",            count: 22, color: Color(hex: "#22C55E")),
        ResourceUtilization(type: "Links",      icon: "link",                 count: 9,  color: Color(hex: "#F97316")),
        ResourceUtilization(type: "Recordings", icon: "waveform",             count: 6,  color: Color(hex: "#A78BFA")),
        ResourceUtilization(type: "Slides",     icon: "arrow.up.doc.fill",    count: 11, color: Color(hex: "#44A5FF"))
    ]
}
