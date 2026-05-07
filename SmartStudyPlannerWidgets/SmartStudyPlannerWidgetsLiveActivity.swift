import ActivityKit
import WidgetKit
import SwiftUI

private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

struct SmartStudyPlannerWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: StudyTimerAttributes.self) { context in

            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: context.attributes.subjectColorHex).opacity(0.18))
                        .frame(width: 46, height: 46)
                    Image(systemName: "book.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color(hex: context.attributes.subjectColorHex))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(context.attributes.sessionTitle)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(context.attributes.subjectName)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.65))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(context.state.startDate, style: .timer)
                        .font(.title3.monospacedDigit().bold())
                        .foregroundStyle(.white)
                        .frame(minWidth: 64, alignment: .trailing)
                    Text("elapsed")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.55))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .activityBackgroundTint(Color(hex: "#0A0A0B").opacity(0.95))

        } dynamicIsland: { context in
            DynamicIsland {

                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        Image(systemName: "book.fill")
                            .font(.body.bold())
                            .foregroundStyle(Color(hex: context.attributes.subjectColorHex))
                        VStack(alignment: .leading, spacing: 1) {
                            Text(context.attributes.subjectName)
                                .font(.caption2.bold())
                                .foregroundStyle(.secondary)
                            Text(context.attributes.sessionTitle)
                                .font(.callout.bold())
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                        }
                    }
                    .padding(.leading, 6)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(context.state.startDate, style: .timer)
                            .font(.title3.monospacedDigit().bold())
                            .foregroundStyle(.primary)
                        Text("elapsed")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.trailing, 6)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 6) {
                        Image(systemName: "brain.head.profile")
                            .font(.caption)
                        Text("Session in progress")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 6)
                    .padding(.top, 2)
                }

            } compactLeading: {
                Image(systemName: "book.fill")
                    .font(.caption.bold())
                    .foregroundStyle(Color(hex: context.attributes.subjectColorHex))
                    .padding(.leading, 4)

            } compactTrailing: {
                Text(context.state.startDate, style: .timer)
                    .font(.caption.monospacedDigit().bold())
                    .foregroundStyle(.primary)
                    .frame(minWidth: 44)
                    .padding(.trailing, 4)

            } minimal: {
                Image(systemName: "book.fill")
                    .font(.caption)
                    .foregroundStyle(Color(hex: context.attributes.subjectColorHex))
            }
            .widgetURL(URL(string: "smartstudyplanner://session"))
            .keylineTint(Color(hex: context.attributes.subjectColorHex))
        }
    }
}

extension StudyTimerAttributes {
    fileprivate static var preview: StudyTimerAttributes {
        StudyTimerAttributes(
            sessionId: "preview",
            sessionTitle: "Advanced Algorithms",
            subjectName: "iOS Development",
            subjectColorHex: "#44A5FF"
        )
    }
}

extension StudyTimerAttributes.ContentState {
    fileprivate static var active: StudyTimerAttributes.ContentState {
        .init(startDate: Date().addingTimeInterval(-754))
    }
}

#Preview("Lock Screen", as: .content, using: StudyTimerAttributes.preview) {
    SmartStudyPlannerWidgetsLiveActivity()
} contentStates: {
    StudyTimerAttributes.ContentState.active
}

#Preview("Dynamic Island Compact", as: .dynamicIsland(.compact), using: StudyTimerAttributes.preview) {
    SmartStudyPlannerWidgetsLiveActivity()
} contentStates: {
    StudyTimerAttributes.ContentState.active
}

#Preview("Dynamic Island Expanded", as: .dynamicIsland(.expanded), using: StudyTimerAttributes.preview) {
    SmartStudyPlannerWidgetsLiveActivity()
} contentStates: {
    StudyTimerAttributes.ContentState.active
}
