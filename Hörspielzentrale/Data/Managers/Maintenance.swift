//
//  MaintenanceManager.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 13.10.24.
//

import CloudKitSyncMonitor
import OSLog
import SwiftData
import SwiftUI
import TelemetryDeck
@preconcurrency import MusicKit

@MainActor
@Observable
class Maintenance {
    /// The datamanager to perform changes with
    private let manager: DataManager
    
    /// The series manager
    private let seriesManager: SeriesManager
    
    /// Detects duplicates and merges them into a single entity
    func handleDuplicateHoerspiels() {
        let modelContext = ModelContext(manager.modelContainer)
        do {
            try modelContext.transaction {
                let hoerspiele = try modelContext.fetch(FetchDescriptor<Hoerspiel>())
                let dups = Dictionary(grouping: hoerspiele, by: { $0.upc }).filter { $1.count > 1 }.keys
                
                Logger.maintenance.info("Found \(dups.count) duplicates in database")
                for dup in dups {
                    #if DEBUG
                    if dup == "DEBUG" {
                        return
                    }
                    #endif
                    let fetchDescriptor = FetchDescriptor<Hoerspiel>(predicate: #Predicate { hoerspiel in
                        hoerspiel.upc == dup
                    })
                    let sames = try modelContext.fetch(fetchDescriptor)
                    let showInUpNext = sames.contains(where: { $0.showInUpNext
                    })
                    
                    let played = sames.contains(where: { $0.played })
                    
                    let playedUpTo = sames.max(by: { $0.playedUpTo < $1.playedUpTo })?.playedUpTo ?? 0
                    
                    let lastPlayed = sames.max(by: { $0.lastPlayed < $1.lastPlayed})?.lastPlayed ?? Date.distantPast
                    
                    guard let first = sames.first else {
                        return
                    }
                    
                    let hoerspiel = Hoerspiel(title: first.title,
                                              albumID: first.albumID,
                                              played: played,
                                              lastPlayed: lastPlayed,
                                              playedUpTo: playedUpTo,
                                              showInUpNext: showInUpNext,
                                              duration: first.duration,
                                              releaseDate: first.releaseDate,
                                              artist: first.artist,
                                              upc: first.upc,
                                              series: first.series
                    )
                    
                    for same in sames {
                        modelContext.delete(same)
                        Logger.maintenance.debug("Deleted \(same.title)")
                    }
                    
                    modelContext.insert(hoerspiel)
                    Logger.maintenance.debug("Cleaned duplicates for \(first.upc) with title \(first.title)")
                    
                }
                try modelContext.save()
            }
            
        } catch {
            Logger.data.fullError(error, sendToTelemetryDeck: true)
        }
    }
    
    func handleDuplicateSeries() {
        let modelContext = ModelContext(manager.modelContainer)
        do {
            try modelContext.transaction {
                let hoerspiele = try modelContext.fetch(FetchDescriptor<Series>())
                let dups = Dictionary(grouping: hoerspiele, by: { $0.musicItemID }).filter { $1.count > 1 }.keys
                
                Logger.maintenance.info("Found \(dups.count) duplicate series in database")
                for dup in dups {
                    let fetchDescriptor = FetchDescriptor<Series>(predicate: #Predicate { series in
                        series.musicItemID == dup
                    })
                    let sames = try modelContext.fetch(fetchDescriptor)
                    
                    guard let first = sames.first else {
                        return
                    }
                    
                    let series = Series(name: first.name,
                                        musicItemID: first.musicItemID,
                                        hoerspiels: first.hoerspiels)
                    
                    for same in sames {
                        modelContext.delete(same)
                        Logger.maintenance.debug("Deleted \(same.name)")
                    }
                    
                    modelContext.insert(series)
                    Logger.maintenance.debug("Cleaned duplicates for \(first.musicItemID) with name \(first.name)")
                    
                }
                try modelContext.save()
            }
            
        } catch {
            Logger.data.fullError(error, sendToTelemetryDeck: true)
        }
    }
    
    /// Checks for required maintenance and performs such
    public func checkForRequiredMaintenance() {
        do {
            try retroActivelyAddSeries()
        } catch {
            Logger.data.fullError(error, sendToTelemetryDeck: true)
        }
        Task.detached(priority: .utility) {
            Logger.maintenance.info("Started maintenance")
            let startdate = Date.now
            await self.handleDuplicateSeries()
            await self.handleDuplicateHoerspiels()
            await self.addMissingSeries()
            Logger.metadata.info("Finished maintenance after \(Date() - startdate)")
        }
    }
    
    private func retroActivelyAddSeries() throws {
        let context = ModelContext(manager.modelContainer)
        let count = try context.fetchCount(FetchDescriptor<Series>())
        if count == 0 {
            let allHoerspiels = try context.fetch(FetchDescriptor<Hoerspiel>())
            
            var artistFetchDescriptor = FetchDescriptor<Hoerspiel>()
            artistFetchDescriptor.propertiesToFetch = [\.artist]
            
            let fetchedResults = try context.fetch(artistFetchDescriptor)
            
            let uniqueArtists = Set(fetchedResults.map(\.artist))
            
            let filepath = Bundle.main.url(forResource: "ArtistIDMatch", withExtension: "json")
            guard let filepath else {
                assertionFailure()
                return
            }
            let contents = try Data(contentsOf: filepath)
            let decoded = try JSONDecoder().decode([CodableSeries].self, from: contents)
            
            var allSeries = [Series]()
            
            for series in decoded where uniqueArtists.contains(series.name) {
                let serie = Series(name: series.name, musicItemID: series.id)
                allSeries.append(serie)
            }
            
            for series in allSeries {
                series.hoerspiels = allHoerspiels.filter { $0.artist == series.name }
                Logger.data.fault("Count of hoerspiels for \(series.name) is \(series.hoerspiels?.count ?? 0)")
            }
            try context.save()
        }
    }
    
    /// Adds correct ``Series`` to all ``Hoerspiel`` that lack one
    private func addMissingSeries() async {
        do {
            let context = ModelContext(manager.modelContainer)
            let withMissingSeries = try context.fetch(FetchDescriptor<Hoerspiel>(predicate: #Predicate { hoerspiel in
                hoerspiel.series == nil
            }))
            
            for hoerspiel in withMissingSeries {
                Logger.maintenance.info("\(hoerspiel.title) has no associated series")
                let artist = hoerspiel.artist
                if let series = try context.fetch(FetchDescriptor<Series>(predicate: #Predicate { series in
                    return series.name == artist
                })).first {
                    hoerspiel.series = series
                    Logger.maintenance.info("Added series for \(hoerspiel.title) from storage: \(series.name)")
                } else {
                    let request = MusicCatalogSearchRequest(term: hoerspiel.artist, types: [Artist.self])
                    let response = try await request.response()
                    if let artist = response.artists.first(where: { $0.name == hoerspiel.artist }) {
                        let series = Series(name: artist.name, musicItemID: artist.id.rawValue)
                        hoerspiel.series = series
                        Logger.maintenance.info("Added series for \(hoerspiel.title) from apple music: \(series.name)")
                    }
                }
            }
            try context.save()
        } catch {
            Logger.maintenance.fullError(error, sendToTelemetryDeck: true)
        }
    }
    
    init(manager: DataManager, seriesManager: SeriesManager) {
        self.manager = manager
        self.seriesManager = seriesManager
    }
}

/// A view modifier that attaches and handles maintenance checks
struct MaintenanceModifier: ViewModifier {
    @Environment(Maintenance.self) var maintenanceManager
    func body(content: Content) -> some View {
        content
            .onAppear {
                maintenanceManager.checkForRequiredMaintenance()
            }
    }
}

extension View {
    /// A modifier that attaches maintenance checks to the given view
    /// - Returns: Returns a view with attached maintenance checks
    func maintenance() -> some View {
        modifier(MaintenanceModifier())
    }
}
