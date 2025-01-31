//
//  OnboardingSeriesView.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 21.11.24.
//

import SwiftUI
import TelemetryDeck

/// A view to let the user slelect series
struct SeriesSelectionView: View {
    // MARK: - Properties
    
    /// A class resposible for network checks
    @Environment(NetworkHelper.self) var networkHelper
    
    /// A closure to run to dismiss the view
    let onFinished: () -> Void
    
    // MARK: - View
    var body: some View {
        Group {
            switch networkHelper.connectionStatus {
            case .working:
                SeriesSelectionWorkingView(onFinished: onFinished)
            case .notWorking(let description, let systemName):
                ContentUnavailableView {
                    Label("Internetverbindung erforderlich", systemImage: systemName)
                } description: {
                    Text(description)
                } actions: {
                    Button {
                        onFinished()
                    } label: {
                        Text("Schließen")
                    }
                }
            }
        }
        .navigationTitle("Serien hinzufügen")
        .trackNavigation(path: "SeriesSelection")
    }
}
