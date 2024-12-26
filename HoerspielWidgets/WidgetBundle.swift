//
//  WidgetBundle.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 23.12.24.
//

import SwiftUI

/// The entry point of the target
@main
struct HoerspielWidgetsBundle: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        UpNextWidget()
    }
}
