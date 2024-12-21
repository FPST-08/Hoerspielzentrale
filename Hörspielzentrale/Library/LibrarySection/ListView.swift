//
//  ListView.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 18.10.24.
//

import SwiftUI
import TelemetryDeck

/// A view to display hoerspiele in a list
struct ListView: View {
    // MARK: - Properties
    
    /// The hoerspiele to display
    let hoerspiele: [SendableHoerspiel]
    
    // MARK: - View
    var body: some View {
        List {
            ForEach(hoerspiele) { hoerspiel in
                HoerspielListView(hoerspiel: hoerspiel)
            }
        }
        .safeAreaPadding(.bottom, 60)
        .listStyle(.plain)
        .trackNavigation(path: "ListView")
    }
}
