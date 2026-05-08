import Foundation

enum AppTab: Int, CaseIterable {
    case dashboard
    case subjects
    case plan
    case progress
    case settings

    var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .subjects:  return "Subjects"
        case .plan:      return "Plan"
        case .progress:  return "Progress"
        case .settings:  return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .dashboard: return "square.grid.2x2.fill"
        case .subjects:  return "book.pages.fill"
        case .plan:      return "calendar"
        case .progress:  return "chart.bar"
        case .settings:  return "gearshape"
        }
    }
}
