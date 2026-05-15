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
                    Circle()
                        .stroke(Color(hex: context.attributes.subjectColorHex).opacity(0.25), lineWidth: 2)
                        .frame(width: 52, height: 52)
 
                    Circle()
                        .fill(Color(hex: context.attributes.subjectColorHex).opacity(0.15))
                        .frame(width: 44, height: 44)
 
                    Image(systemName: "book.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color(hex: context.attributes.subjectColorHex))
                }
 
                VStack(alignment: .leading, spacing: 3) {
                    Text(context.attributes.sessionTitle)
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .lineLimit(1)
 
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(hex: context.attributes.subjectColorHex))
                            .frame(width: 6, height: 6)
                        Text(context.attributes.subjectName)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
 
                Spacer()
 
                VStack(alignment: .trailing, spacing: 3) {
                    Text(context.state.startDate, style: .timer)
                        .font(.title3.monospacedDigit().bold())
                        .foregroundStyle(Color(hex: context.attributes.subjectColorHex))
                        .frame(minWidth: 64, alignment: .trailing)
                    Text("elapsed")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.45))
                }
                .padding(.leading, 12)
                .overlay(
                    Rectangle()
                        .fill(Color(hex: context.attributes.subjectColorHex).opacity(0.4))
                        .frame(width: 2),
                    alignment: .leading
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .activityBackgroundTint(Color(hex: "#0A0A0B").opacity(0.96))
 
        } dynamicIsland: { context in
            DynamicIsland {
                 DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: context.attributes.subjectColorHex).opacity(0.2))
                                .frame(width: 32, height: 32)
                            Image(systemName: "book.fill")
                                .font(.caption.bold())
                                .foregroundStyle(Color(hex: context.attributes.subjectColorHex))
                        }
 
                        VStack(alignment: .leading, spacing: 2) {
                            Text(context.attributes.subjectName)
                                .font(.caption2.bold())
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                            Text(context.attributes.sessionTitle)
                                .font(.callout.bold())
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                        }
                    }
                    .padding(.leading, 4)
                }
                 DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 3) {
                        Text(context.state.startDate, style: .timer)
                            .font(.title3.monospacedDigit().bold())
                            .foregroundStyle(Color(hex: context.attributes.subjectColorHex))
                        Text("elapsed")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.trailing, 4)
                }
                 DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 0) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)
                            Text("Session in progress")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
 
                        Spacer()
 
                        Link(destination: URL(string: "smartstudyplanner://session")!) {
                            HStack(spacing: 4) {
                                Text("Manage")
                                    .font(.caption2.bold())
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 8, weight: .bold))
                            }
                            .foregroundStyle(Color(hex: context.attributes.subjectColorHex))
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.top, 4)
                }
 
            } compactLeading: {
                 ZStack {
                    Circle()
                        .fill(Color(hex: context.attributes.subjectColorHex).opacity(0.25))
                        .frame(width: 22, height: 22)
                    Image(systemName: "book.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color(hex: context.attributes.subjectColorHex))
                }
                .padding(.leading, 4)
 
            } compactTrailing: {
                 Text(context.state.startDate, style: .timer)
                    .font(.caption.monospacedDigit().bold())
                    .foregroundStyle(Color(hex: context.attributes.subjectColorHex))
                    .frame(minWidth: 44)
                    .padding(.trailing, 4)
 
            } minimal: {
                 ZStack {
                    Circle()
                        .fill(Color(hex: context.attributes.subjectColorHex).opacity(0.25))
                    Image(systemName: "book.fill")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color(hex: context.attributes.subjectColorHex))
                }
            }
            .widgetURL(URL(string: "smartstudyplanner://session"))
            .keylineTint(Color(hex: context.attributes.subjectColorHex))
        }
    }
}
