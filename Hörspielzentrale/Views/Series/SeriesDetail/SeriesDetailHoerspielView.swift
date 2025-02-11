//
//  SeriesDetailHoerspielView.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 11.02.25.
//

import SwiftData
import SwiftUI

/// A view to present the 10 most recent releases of a series
struct SeriesDetailHoerspielView: View {
    /// The matching hoerspiele
    @Query var hoerspiele: [Hoerspiel]
    
    /// The series
    let series: SendableSeries
    
    var body: some View {
        NavigationSection(destination: .allHoerspiels(series: series), title: "Alle Hörspiele")
        ScrollView(.horizontal) {
            LazyHStack {
                ForEach(hoerspiele) { hoerspiel in
                    HoerspielDisplayView(SendableHoerspiel(hoerspiel: hoerspiel), .coverOnly)
                }
                NavigationLink {
                    AllHoerspielsView(series: series)
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 15)
                            .foregroundStyle(Color.white.opacity(0.3))
                        RoundedRectangle(cornerRadius: 15)
                            .foregroundStyle(Color.systemBackground)
                            .padding(1)
                        VStack {
                            Image(systemName: "chevron.forward")
                                .font(.title)
                                .fontWeight(.heavy)
                            Text("Alle anzeigen")
                                .fontWeight(.medium)
                        }
                        
                    }
                    .frame(width: 120, height: 120)
                }
                
            }
            .scrollTargetLayout()
        }
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
