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
    
    /// All series that are part of the library
    @Query var allSeries: [Series]
    
    var body: some View {
        if allSeries.isEmpty {
            ContentUnavailableView.search
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
    }
    
}
