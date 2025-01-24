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
    
    /// All series that are part of the library
    @Query var allSeries: [Series]
    
    @Default(.libraryCoverDisplayMode) var displayMode
    
    var body: some View {
        NavigationStack(path: Bindable(navigation).libraryPath) {
            ScrollView {
                switch displayMode {
                case .inline:
                    VStack {
                        ForEach(allSeries) { series in
                            RichLibrarySection(series: SendableSeries(series))
                        }
                    }
                case .circle:
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 110))]) {
                        ForEach(allSeries) { series in
                            LibraryCircleView(series: SendableSeries(series))
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
