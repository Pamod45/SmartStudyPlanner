//
//  SmartStudyPlannerWidgetsBundle.swift
//  SmartStudyPlannerWidgets
//
//  Created by Pubudu Perera on 2026-05-07.
//

import WidgetKit
import SwiftUI

@main
struct SmartStudyPlannerWidgetsBundle: WidgetBundle {
    var body: some Widget {
        SmartStudyPlannerWidgets()
        SmartStudyPlannerWidgetsControl()
        SmartStudyPlannerWidgetsLiveActivity()
    }
}
