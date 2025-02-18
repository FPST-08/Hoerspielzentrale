//
//  SeriesInfoView.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 20.01.25.
//

import SwiftData
import SwiftUI

/// A view used to fetch and display information about a ``Series``
struct SeriesInfoView: View {
    /// The series to display information about
    let series: SendableSeries
    
    /// The first release date of a ``Hoerspiel`` associated with this ``Series``
    @State private var firstReleaseDate: Date?
    /// The most recent release date  date of a ``Hoerspiel`` associated with this ``Series``
    @State private var lastReleaseDate: Date?
    /// The overall count of ``Hoerspiel``
    @State private var overallCount: Int?
    /// The overall duration of all ``Hoerspiel`` combined
    @State private var overallDurationString = "N/A"
    
    /// An Observable Class responsible for data
    @Environment(DataManagerClass.self) var dataManager
    
    var body: some View {
        DetailsInfoView(entries: [
            DetailsInfoDisplay(title: "Name", value: series.name),
            DetailsInfoDisplay(title: "Erstveröffentlichung",
                               value: "\(firstReleaseDate?.formatted(date: .abbreviated, time: .omitted) ?? "N/A")"),
            DetailsInfoDisplay(title: "Zuletzt veröffentlicht",
                               value: "\(lastReleaseDate?.formatted(date: .abbreviated, time: .omitted) ?? "N/A")"),
            DetailsInfoDisplay(title: "Anzahl Hörspiele", value: "\(overallCount?.formatted() ?? "N/A")")
        ])
        .task {
            firstReleaseDate = try? await dataManager.manager.read({
                let id = series.musicItemID
                let date = Date.distantPast
                var descriptor = FetchDescriptor<Hoerspiel>(predicate: #Predicate<Hoerspiel> { hoerspiel in
                    hoerspiel.series?.musicItemID == id && hoerspiel.releaseDate != date
                })
                descriptor.sortBy = [SortDescriptor(\Hoerspiel.releaseDate, order: .forward)]
                return descriptor
            }, keypath: \.releaseDate)
            lastReleaseDate = try? await dataManager.manager.read({
                let id = series.musicItemID
                let now = Date.now
                var descriptor = FetchDescriptor<Hoerspiel>(predicate: #Predicate<Hoerspiel> { hoerspiel in
                    hoerspiel.series?.musicItemID == id && hoerspiel.releaseDate < now
                })
                descriptor.sortBy = [SortDescriptor(\Hoerspiel.releaseDate, order: .reverse)]
                return descriptor
            }, keypath: \.releaseDate)
            overallCount = try? await dataManager.manager.fetchCount({
                let id = series.musicItemID
                let descriptor = FetchDescriptor<Hoerspiel>(predicate: #Predicate<Hoerspiel> { hoerspiel in
                    hoerspiel.series?.musicItemID == id
                })
                return descriptor
            })
        }
    }
}
