//
//  RichLibrarySection.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 20.01.25.
//

import SwiftData
import SwiftUI

/// A view used to represent a ``Series`` in the library
struct RichLibrarySection: View {
    /// An Observable Class responsible for data
    @Environment(DataManagerClass.self) var dataManager
    
    /// The first ten hoerspiele of the series
    @Query var hoerspiele: [Hoerspiel]
    
    /// The series
    let series: SendableSeries
    
    var body: some View {
        SeriesNavigationSection(series: series)
        ScrollView(.horizontal) {
            LazyHStack {
                ForEach(hoerspiele) { hoerspiel in
                    HoerspielDisplayView(SendableHoerspiel(hoerspiel: hoerspiel), .rectangularSmall)
                }
            }
            .scrollTargetLayout()
        }
        .frame(height: 140)
        .scrollTargetBehavior(.viewAligned)
        .scrollIndicators(.never)
        .contentMargins(.leading, 20, for: .scrollContent)
    }
    
    init(series: SendableSeries) {
        self.series = series
        let id = series.musicItemID
        let now = Date.now
        var descriptor = FetchDescriptor<Hoerspiel>(predicate: #Predicate { hoerspiel in
            hoerspiel.series?.musicItemID == id && hoerspiel.releaseDate < now
        })
        descriptor.fetchLimit = 10
        descriptor.sortBy = [SortDescriptor(\Hoerspiel.releaseDate, order: .reverse)]
        _hoerspiele = Query(descriptor)
    }
}
