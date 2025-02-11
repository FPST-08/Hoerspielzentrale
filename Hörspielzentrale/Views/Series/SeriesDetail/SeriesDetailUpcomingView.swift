//
//  SeriesDetailUpcomingView.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 11.02.25.
//

import SwiftData
import SwiftUI

/// A view to present an upcmoing release of a series if possible
struct SeriesDetailUpcomingView: View {
    /// The matching hoerspiele
    @Query var hoerspiele: [Hoerspiel]
    
    /// The series
    let series: SendableSeries
    
    var body: some View {
        if let hoerspiel = hoerspiele.first {
            SectionHeader(title: "Bald verfügbar")
            HoerspielDisplayView(SendableHoerspiel(hoerspiel: hoerspiel), .rectangular)
        }
    }
    
    init(series: SendableSeries) {
        self.series = series
        let id = series.musicItemID
        let now = Date.now
        var descriptor = FetchDescriptor<Hoerspiel>(predicate: #Predicate { hoerspiel in
            return hoerspiel.series?.musicItemID == id && hoerspiel.releaseDate > now
        })
        descriptor.fetchLimit = 1
        descriptor.sortBy = [SortDescriptor(\Hoerspiel.releaseDate, order: .reverse)]
        _hoerspiele = Query(descriptor)
    }
}
