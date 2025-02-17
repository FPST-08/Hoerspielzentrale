//
//  LibraryView.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 20.01.25.
//

import Defaults
import OSLog
import SwiftData
import SwiftUI
import TelemetryDeck

/// The library root view
struct LibraryView: View {
    
    /// An Observable Class responsible for navigation
    @Environment(NavigationManager.self) var navigation
    
    @Default(.libraryCoverDisplayMode) var displayMode
    
    /// The search string
    @State private var searchString = ""
    
    /// Referencing an `@Observable` class responsible for managing series
    @Environment(SeriesManager.self) var seriesManager
    
    var body: some View {
        NavigationStack(path: Bindable(navigation).libraryPath) {
            ScrollView {
                LibraryInlineSection(title: "Hörspiele", systemImage: "square.stack") {
                    SearchView()
                }
                LibraryQueryView(searchString: searchString)
            }
            .searchable(text: $searchString, prompt: Text("Suche nach Serien in der Mediathek"))
            .navigationTitle("Mediathek")
            .safeAreaPadding(.bottom, 60)
            .toolbar {
                ToolbarItem {
                    Button {
                        displayMode.toggle()
                    } label: {
                        Image(systemName: displayMode.imageSystemName)
                    }
                }
                ToolbarItem {
                    Button {
                        navigation.showSeriesAddingSheet = true
                    } label: {
                        Image(systemName: "plus.square.fill.on.square.fill")
                    }
                }
            }
            .navigationDestination(for: SendableHoerspiel.self) {
                HoerspielDetailView($0)
            }
            .refreshable {
                do {
                    try await seriesManager.checkForNewReleases()
                    TelemetryDeck.signal("Data.refreshed")
                } catch {
                    let hapticGen = UINotificationFeedbackGenerator()
                    hapticGen.notificationOccurred(.error)
                    Logger.data.fullError(error, sendToTelemetryDeck: true)
                }
            }
        }
        .trackNavigation(path: "Library")
    }
    
    /// The displaymode for the series
    enum SeriesDisplayMode: Codable, Defaults.Serializable {
        case inline, circle
        
        /// The system name to represent the current mode
        var imageSystemName: String {
            switch self {
            case .inline:
                return "line.3.horizontal"
            case .circle:
                return "circle.grid.2x2.fill"
            }
        }
        
        /// A function to toggle the mode
        mutating func toggle() {
            self = self == .inline ? .circle : .inline
        }
    }
}
