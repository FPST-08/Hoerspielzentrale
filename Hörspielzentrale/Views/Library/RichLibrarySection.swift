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
    
    /// The ``Hoerspiel`` to link display
    @State private var hoerspiele = [SendableHoerspiel]()
    
    /// The series
    let series: SendableSeries
    
    var body: some View {
        SeriesNavigationSection(series: series)
        ScrollView(.horizontal) {
            LazyHStack {
                ForEach(hoerspiele) { hoerspiel in
                    HoerspielDisplayView(hoerspiel, .rectangularSmall)
                }
            }
            .scrollTargetLayout()
        }
        .frame(height: 140)
        .scrollTargetBehavior(.viewAligned)
        .scrollIndicators(.never)
        .contentMargins(.leading, 20, for: .scrollContent)
        .task {
            hoerspiele = (try? await dataManager.manager.fetch({
                let id = series.musicItemID
                let now = Date.now
                var descriptor = FetchDescriptor<Hoerspiel>(predicate: #Predicate { hoerspiel in
                    hoerspiel.series?.musicItemID == id && hoerspiel.releaseDate < now
                })
                descriptor.fetchLimit = 10
                descriptor.sortBy = [SortDescriptor(\Hoerspiel.releaseDate, order: .reverse)]
                return descriptor
            })) ?? []
        }
    }
}
