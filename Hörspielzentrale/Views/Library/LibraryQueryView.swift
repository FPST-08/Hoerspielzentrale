//
//  LibraryQueryView.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 25.01.25.
//

import Defaults
import SwiftData
import SwiftUI

/// A view used to fetch the ``Series`` via a `Query`
struct LibraryQueryView: View {
    
    @Default(.libraryCoverDisplayMode) var displayMode
    
    @Default(.searchMode) var searchMode
    
    /// All series that are part of the library
    @Query var allSeries: [Series]
    
    let searchString: String
    
    /// An Observable Class responsible for navigation
    @Environment(NavigationManager.self) var navigation
    
    var body: some View {
        if allSeries.isEmpty && searchString != "" {
            ContentUnavailableView.search
        } else if searchString == ""  && allSeries.isEmpty {
            ContentUnavailableView {
                Label("Keine Serien", systemImage: "music.microphone")
            } description: {
                Text("Hinzugefügte Serien erscheinen hier")
            } actions: {
                Button {
                    navigation.selection = .search
                    searchMode = .appleMusic
                    navigation.searchPresented = true
                } label: {
                    Label("Füge deine erste Serie hinzu", systemImage: "arrow.right")
                }
                .buttonStyle(BorderedProminentButtonStyle())
            }

        } else {
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
    }
    
    init(searchString: String) {
        var descriptor = FetchDescriptor<Series>(predicate: #Predicate<Series> { series in
            if searchString.isEmpty {
                return true
            } else {
                return series.name.localizedStandardContains(searchString)
            }
        })
        descriptor.sortBy = [SortDescriptor(\Series.name, order: .forward)]
        _allSeries = Query(descriptor)
        self.searchString = searchString
    }
    
}
