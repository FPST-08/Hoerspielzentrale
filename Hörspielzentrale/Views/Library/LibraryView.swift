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
    
    /// An Observable Class responsible for data
    @Environment(DataManagerClass.self) var dataManager
    
    /// All series that are part of the library
    @State private var allSeries = [SendableSeries]()
    
    @Default(.libraryCoverDisplayMode) var displayMode
    
    var body: some View {
        NavigationStack(path: Bindable(navigation).libraryPath) {
            ScrollView {
                switch displayMode {
                case .inline:
                    VStack {
                        ForEach(allSeries) { series in
                            RichLibrarySection(series: series)
                        }
                    }
                case .circle:
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 110))]) {
                        ForEach(allSeries) { series in
                            LibraryCircleView(series: series)
                        }
                    }
                    .padding(.horizontal, 3)
                }
            }
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
                HoerspielDetailView(hoerspiel: $0)
            }
        }
        .task {
            do {
                allSeries = try await dataManager.manager.fetchAllSeries()
            } catch {
                Logger.data.fullError(error, sendToTelemetryDeck: true)
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
