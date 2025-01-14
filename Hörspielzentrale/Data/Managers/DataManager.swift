//
//  SharedModelContainer.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 21.06.24.
//

import AppIntents
import Combine
import Foundation
@preconcurrency import MusicKit
import OSLog
import SwiftData
import UIKit

// swiftlint:disable type_body_length
// swiftlint:disable file_length
/// Resposible to handle all database modifications and programmatic read operations
@ModelActor
actor DataManager {
    
    /// Deletes an entity with a given persistentIdentifier
    /// - Parameter persistentIdentifier: PersistentIdentifier of entity that should be deleted
    public func delete(_ persistentIdentifier: PersistentIdentifier) throws {
        guard let model = modelContext.model(for: persistentIdentifier) as? Hoerspiel else {
            throw DataBaseError.noModelForPersistentIdentifierFound
        }
        modelContext.delete(model)
        try modelContext.save()
    }
    
    /// Fetches the ``Series`` with the specified `ID`
    /// - Parameter id: The id of the desired ``Series``
    /// - Returns: The desired ``Series``
    private func seriesFor(id: String) throws -> Series {
        var fetchDescriptor = FetchDescriptor<Series>(predicate: #Predicate { series in
            series.musicItemID == id
        })
        fetchDescriptor.fetchLimit = 1
        
        guard let series = try modelContext.fetch(fetchDescriptor).first else {
            throw DataBaseError.noSeriesForIDFound
        }
        return series
    }
    
    /// Inserts a `SendableHoerspiel` in the modelContext
    /// - Parameter model: `SendableHoerspiel`to insert
    public func insert(_ model: SendableHoerspiel, seriesID: String) throws {
        let series = try seriesFor(id: seriesID)
        let hoerspiel = Hoerspiel(title: model.title,
                                  albumID: model.albumID,
                                  played: model.played,
                                  lastPlayed: model.lastPlayed,
                                  playedUpTo: model.playedUpTo,
                                  showInUpNext: model.showInUpNext,
                                  duration: model.duration,
                                  releaseDate: model.releaseDate,
                                  artist: model.artist,
                                  series: series
        )
        modelContext.insert(hoerspiel)
    }
    
    /// Inserts a `CodableHoerspiel` in the modelContext
    /// - Parameter model: `CodableHoerspiel`to insert
    public func insert(_ model: CodableHoerspiel, seriesID: String) throws {
        let series = try seriesFor(id: seriesID)
        let hoerspiel = Hoerspiel(title: model.title,
                                  albumID: model.albumID,
                                  duration: model.duration,
                                  releaseDate: model.releaseDate,
                                  artist: model.artist,
                                  upc: model.upc,
                                  series: series
        )
        modelContext.insert(hoerspiel)
    }
    
    // swiftlint: disable function_parameter_count
    /// Inserts a ``Hoerspiel`` in the modelContext from concrete types
    /// - Parameters:
    ///   - title: The title of the hoerpsiel
    ///   - albumID: The albumID of the hoerspiel
    ///   - played: Indicates whether or not a ``Hoerspiel`` was played to the end
    ///   - lastPlayed: Indicates when the playback for a  ``Hoerspiel`` was initiated
    ///   - playedUpTo: An Integer that indicates how far the hoerspiel was played up to
    ///   - showInUpNext: A boolean that indicates whether the hoerspiel is shown in the `Up Next` Section
    ///   - duration: A timeinterval that represents the total duration of the hoerspiel in seconds
    ///   - releaseDate: A date that represents the release date of the hoerspiel
    ///   - artist: A string that represents the name of the artist that published that hoerspiel
    ///   - upc: The Universal Product Code for the Hoerspiel
    public func insert(title: String,
                       albumID: String,
                       played: Bool = false,
                       lastPlayed: Date = Date.distantPast,
                       playedUpTo: Int = 0,
                       showInUpNext: Bool = false,
                       duration: TimeInterval,
                       releaseDate: Date,
                       artist: String,
                       upc: String,
                       seriesID: String
    ) throws {
        let series = try seriesFor(id: seriesID)
        modelContext.insert(Hoerspiel(title: title,
                                      albumID: albumID,
                                      played: played,
                                      lastPlayed: lastPlayed,
                                      playedUpTo: playedUpTo,
                                      showInUpNext: showInUpNext,
                                      duration: duration,
                                      releaseDate: releaseDate,
                                      artist: artist,
                                      upc: upc,
                                      series: series))
    }
    // swiftlint: enable function_parameter_count
    
    /// Inserts an array of codables into the modelContext
    /// - Parameter codables: The array of codables to insert
    /// - Parameter artist: The artist of all the codables
    /// - Returns: Returns the ``SendableHoerspiel`` that were added to disk
    public func insert(_ codables: [CodableHoerspiel], artist: Artist) throws -> [SendableHoerspiel] {
        var addedEntities = [SendableHoerspiel]()
        try modelContext.transaction {
            if let series = try modelContext.fetch(FetchDescriptor<Series>(predicate: #Predicate { series in
                series.musicItemID == artist.id.rawValue
            })).first {
                Logger.data.debug("Series currently has a count of \(series.hoerspiels?.count ?? 0)")
                let hoerspiele = codables.map { Hoerspiel($0) }
                for hoerspiel in hoerspiele {
                    modelContext.insert(hoerspiel)
                }
                series.hoerspiels?.append(contentsOf: hoerspiele)
                addedEntities = hoerspiele.map { SendableHoerspiel(hoerspiel: $0)}
                try modelContext.save()
            } else {
                let series = Series(name: artist.name, musicItemID: artist.id.rawValue)
                series.hoerspiels = codables.map { Hoerspiel($0) }
                modelContext.insert(series)
                try modelContext.save()
            }
        }
        return addedEntities
    }
    
#if DEBUG
    /// Populates the database with entries for the screenshots
    func populateForScreenshots() {
        try? modelContext.transaction {
            let series = Series(name: "Hörspielhase", musicItemID: "DEBUG")
            modelContext.insert(series)
            for track in screenshotNames {
                let hoerspiel = Hoerspiel(title: track,
                                          albumID: "DEBUG",
                                          duration: Double.random(in: 1800...5400),
                                          releaseDate: Date().advanced(by: TimeInterval(86400 * Int.random(in: -365 ... 10))),
                                          artist: "Hörspielhase",
                                          upc: "DEBUG",
                                          series: series)
                modelContext.insert(hoerspiel)
                
            }
            try modelContext.save()
        }
    }
    #endif
    
    /// Returns a random `PersistentIdentifier` of an entity matching the `FetchDescriptor`
    /// - Parameter fetchDescriptor: The `FetchDescriptor` to fetch for
    /// - Returns: Returns a `PersistentIdentifier` matching the `FetchDescriptor`
    public func fetchRandom(
        _ fetchDescriptor: @Sendable () -> FetchDescriptor<Hoerspiel>
    ) throws -> PersistentIdentifier {
        let fetchCount = try modelContext.fetchCount(fetchDescriptor())
        if fetchCount == 0 {
            throw DataBaseError.notEnoughEntities
        } else if fetchCount == 1 {
            guard let entity = try modelContext.fetch(fetchDescriptor()).first else {
                throw DataBaseError.noEntityMatchingDescriptor
            }
            return entity.persistentModelID
        } else {
            let offset = Int.random(in: 0..<fetchCount)
            var fetchDescriptor = fetchDescriptor()
            fetchDescriptor.fetchOffset = offset
            fetchDescriptor.fetchLimit = 1
            guard let entity = try modelContext.fetch(fetchDescriptor).first else {
                throw DataBaseError.noEntityMatchingDescriptor
            }
            return entity.persistentModelID
        }
    }
    
    /// Fetches the tracks for a `persistentIdentifier`
    /// - Parameter persistentIdentifier: The `persistentIdentifier` of the ``Hoerspiel`` to load the tracks from
    /// - Returns: Returns an array of ``SendableStoredTrack``
    public func fetchTracks(_ persistentIdentifier: PersistentIdentifier) throws -> [SendableStoredTrack] {
        guard let model = modelContext.model(for: persistentIdentifier) as? Hoerspiel else {
            throw DataBaseError.noModelForPersistentIdentifierFound
        }
        if let tracks = model.tracks, !tracks.isEmpty {
            return tracks.map { SendableStoredTrack($0)}
        }
        throw DataBaseError.propertyNotAvailable
    }
    
    /// Sets the tracks of a ``Hoerspiel``
    /// - Parameters:
    ///   - persistentIdentifier: The `persistentIdentifier` of the ``Hoerspiel``
    ///   - tracks: The tracks to set to
    public func setTracks(_ persistentIdentifier: PersistentIdentifier, _ tracks: [SendableStoredTrack]) throws {
        guard let model = modelContext.model(for: persistentIdentifier) as? Hoerspiel else {
            throw DataBaseError.noModelForPersistentIdentifierFound
        }
        model.tracks = []
        for track in tracks.sorted() {
            model.tracks?.append(StoredTrack(index: tracks.firstIndex(of: track)!,
                                             title: track.title,
                                             duration: track.duration,
                                             musicItemID: track.musicItemID,
                                             isrc: track.isrc,
                                             hoerspiel: model))
        }
        try modelContext.save()
    }
    
    /// Suggested Entities suitable for App Intents
    /// - Returns: Array of `HoerspielEntity`
    public func suggestedEntities() throws -> [HoerspielEntity] {
        let fetchDescriptor = FetchDescriptor<Hoerspiel>(predicate: #Predicate { hoerspiel in
            hoerspiel.showInUpNext
        }, sortBy: [SortDescriptor(\.lastPlayed, order: .reverse)])
        var hoerspiele = try modelContext.fetch(fetchDescriptor)
        
        if hoerspiele.isEmpty {
            var fetchDescriptor = FetchDescriptor<Hoerspiel>(sortBy: [SortDescriptor(\.releaseDate, order: .reverse)])
            fetchDescriptor.fetchLimit = 20
            hoerspiele = try modelContext.fetch(fetchDescriptor)
        }
        
        return hoerspiele.map {
            let fileURL = documentsDirectoryPath.appendingPathComponent("\($0.upc).jpg")
            let displayImage = DisplayRepresentation.Image(url: fileURL)
            return HoerspielEntity(name: $0.title,
                                   artist: $0.artist,
                                   releaseDate: $0.releaseDate,
                                   image: displayImage,
                                   id: $0.upc)
        }
        
    }
    
    /// Fetches the corresponding ``SendableSeries`` of all ``Series``
    /// - Returns: The corresponding array of ``SendableSeries``
    public func fetchAllSeries() throws -> [SendableSeries] {
        let fetchDescriptor = FetchDescriptor<Series>()
        let models = try modelContext.fetch(fetchDescriptor)
        return models.map { SendableSeries($0)}
    }
    
    /// Adds Entities from JSON at given urlString
    /// - Parameter urlString: The `URL`to load the entities as ``CodableHoerspiel`` from
    public func addEntities(from urlString: String) async throws {
        guard let url = URL(string: urlString) else {
            throw DataBaseError.urlUnWrapFailed
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        if let response = response as? HTTPURLResponse, response.statusCode != 200 {
            throw DataBaseError.httpCodeError(response.statusCode)
        }
        
        let decoded = try JSONDecoder().decode([CodableHoerspiel].self, from: data)
        Logger.data.debug("\(decoded.count)")
        try modelContext.transaction {
            for decode in decoded {
                modelContext.insert(Hoerspiel(decode))
            }
        }
        try modelContext.save()
        
    }
    
    /// Deletes every ``Hoerspiel`` with a given string as the artist
    /// - Parameter artist: The artist to delete its entites from
    ///
    /// This also deletes the locally stored images.
    public func deleteAllHoerspielsFromArtist(_ artist: String) throws {
        var upcDescriptor = FetchDescriptor<Hoerspiel>(predicate: #Predicate{ hoerspiel in
            hoerspiel.artist == artist
        })
        upcDescriptor.propertiesToFetch = [\.upc]
        let UPCs = try modelContext.fetch(upcDescriptor).map { $0.upc }
        
        for UPC in UPCs {
            let filename = documentsDirectoryPath.appendingPathComponent("\(UPC).jpg")
            do {
                try FileManager.default.removeItem(atPath: filename.path())
            } catch {
                Logger.data.warning("Couldn't remove image for \(UPC), \(error.localizedDescription) \(error)")
            }
        }
        
        let predicate = #Predicate<Hoerspiel> { hoerspiel in
            hoerspiel.artist == artist
        }
        
        try modelContext.delete(model: Hoerspiel.self, where: predicate)
    }
    
    /// Updates a ``Hoerspiel`` when the provided ``CodableHoerspiel`` has more recent values
    /// - Parameter codable: The ``CodableHoerspiel`` with possible more dates
    public func updateHoerspielWhenSuitable(
        _ codable: CodableHoerspiel
    ) async throws {
        let descriptor = FetchDescriptor<Hoerspiel>(predicate: #Predicate { hoerspiel in
            hoerspiel.upc == codable.upc
        })
        
        guard let model = try modelContext.fetch(descriptor).first else {
            throw DataBaseError.noEntityMatchingDescriptor
        }
        
        if model.lastPlayed.timeIntervalSince1970 < codable.lastPlayed.timeIntervalSince1970 {
            // If date from model is older than the codable date
            model.lastPlayed = codable.lastPlayed
            if model.playedUpTo == 0 {
                model.playedUpTo = codable.playedUpTo
            }
            if !model.played {
                model.played = codable.played
            }
        }
        try save()
    }
    
    /// Deletes all ``Hoerspiel`` entities and the ``Series`` associated with an artist
    /// - Parameter artist: The artist to delete
    public func deleteArtist(_ artist: Artist) throws {
        let fetchDescriptor = FetchDescriptor<Series>(predicate: #Predicate { series in
            series.musicItemID == artist.id.rawValue && series.name == artist.name
        })
        guard let model = try modelContext.fetch(fetchDescriptor).first else {
            throw DataBaseError.notEnoughEntities
        }
        modelContext.delete(model)
        try save()
    }
    
    /// All ``HoerspielEntity`` matching a search string
    /// - Parameter string: The string to perform search against
    /// - Returns: Returns all ``HoerspielEntity`` where the title contains the string
    public func entities(matching string: String) -> [HoerspielEntity] {
        do {
            let fetchDescriptor = FetchDescriptor(predicate: #Predicate<Hoerspiel> { hoerspiel in
                hoerspiel.title.localizedStandardContains(string)
            })
            
            let hoerspiele = try modelContext.fetch(fetchDescriptor)
            return hoerspiele.map {
                let fileURL = documentsDirectoryPath.appendingPathComponent("\($0.upc).jpg")
                let displayImage = DisplayRepresentation.Image(url: fileURL)
                return HoerspielEntity(name: $0.title,
                                       artist: $0.artist,
                                       releaseDate: $0.releaseDate,
                                       image: displayImage,
                                       id: $0.upc)
            }
        } catch {
            return []
        }
    }
    
    /// The `persistentIdentifier` for a `UPC`
    /// - Parameter upc: The input `UPC`
    /// - Returns: Returns the matching `persistentIdnetifier`
    public func identifierForUPC(upc: String) throws -> PersistentIdentifier {
        let hoerspiele = try modelContext.fetch(FetchDescriptor<Hoerspiel>(predicate: #Predicate { hoerspiel in
            hoerspiel.upc == upc
        }))
        
        if let identifier = hoerspiele.first?.persistentModelID {
            return identifier
        }
        throw DataBaseError.noEntityForPredefinedPredicate
    }
    
    /// Saves the modelContext if changes were detected
    public func save() throws {
        if modelContext.hasChanges {
            Logger.data.info("ModelContext has changes")
            try self.modelContext.save()
        }
    }
    
    /// Fetched the identifiers for a `FetchDescriptor`
    /// - Parameter descriptor: A closure used to construct the FetchDescriptor
    /// - Returns: Returns an array of `PersistentIdentifier` that match the given `FetchDescriptor`
    public func fetchIdentifiers<T>(_ descriptor: @Sendable () -> FetchDescriptor<T>) throws -> [PersistentIdentifier] {
        return try self.modelContext.fetchIdentifiers(descriptor())
    }
    /// Returns an array of typed models that match the criteria of the specified fetch descriptor.
    /// - Parameter descriptor: A fetch descriptor that provides the configuration for the fetch.
    /// - Returns: The array of typed models that satisfy the criteria of the fetch descriptor.
    /// If no models match the criteria, the array is empty.
    public func fetch(_ descriptor: @Sendable () -> FetchDescriptor<Hoerspiel>) throws -> [SendableHoerspiel] {
        try modelContext.fetch(descriptor()).map { SendableHoerspiel(hoerspiel: $0)}
    }
    /// Returns an array of typed models that match the criteria of the specified fetch descriptor.
    /// - Parameter descriptor: A fetch descriptor that provides the configuration for the fetch.
    /// - Returns: The array of typed models that satisfy
    /// the criteria of the fetch descriptor. If no models match the criteria, the array is empty.
    public func fetch(_ descriptor: @Sendable () -> FetchDescriptor<Series>) throws -> [SendableSeries] {
        try modelContext.fetch(descriptor()).map { SendableSeries($0)}
    }
    
    /// Fetched the count for a `FetchDescriptor`
    /// - Parameter descriptor: A closure used to construct the FetchDescriptor
    /// - Returns: Returns an Integer representing the count of entities that match the given `FetchDescriptor
    ///  - Throws: This function can forward the error thrown from `modelContext.fetchCount(:)`
    public func fetchCount<T>(_ descriptor: @Sendable () -> FetchDescriptor<T>) throws -> Int {
        return try self.modelContext.fetchCount(descriptor())
    }
    
    /// Outputs a specific property of an `Entity`
    /// - Parameters:
    ///   - persistentIdentifier: The `persistentIdentifier`of the `Entity` that should be read from
    ///   - keypath: The keypath of the property that should be read from
    /// - Returns: Returns the Value of requested property
    /// - Throws: If no model for the specified persistentIdentifer was found,
    /// `noModelForPersistentIdentifierFound` will be thrown.
    public func read<T>(
        _ persistentIdentifier: PersistentIdentifier,
        keypath: ReferenceWritableKeyPath<Hoerspiel, T>
    ) throws -> T {
        guard let result = modelContext.model(for: persistentIdentifier) as? Hoerspiel else {
            throw DataBaseError.noModelForPersistentIdentifierFound
        }
        return result[keyPath: keypath]
    }
    
    /// Returns the ``SendableHoerspiel`` for a `persistentIdentifier`
    /// - Parameter persistentIdentifier: The `persistentIdentifier` for the ``SendableHoerspiel``
    /// - Returns: The ``SendableHoerspiel`` matching the `persistentIdentifier`
    public func batchRead(_ persistentIdentifier: PersistentIdentifier) throws -> SendableHoerspiel {
        guard let hoerspiel = modelContext.model(for: persistentIdentifier) as? Hoerspiel else {
            throw DataBaseError.noModelForPersistentIdentifierFound
        }
        return SendableHoerspiel(hoerspiel: hoerspiel)
    }
    
    /// Returns the ``SendableHoerspiel`` for each `persistentIdentifier`
    /// - Parameter persistentIdentifiers: The array of `persistentIdentifier` for the ``SendableHoerspiel``
    /// - Returns: The array of ``SendableHoerspiel`` matching the array of `persistentIdentifier`
    public func batchRead(_ persistentIdentifiers: [PersistentIdentifier]) throws -> [SendableHoerspiel] {
        var returnSendables = [SendableHoerspiel]()
        for persistentIdentifier in persistentIdentifiers {
            guard let hoerspiel = modelContext.model(for: persistentIdentifier) as? Hoerspiel else {
                throw DataBaseError.noModelForPersistentIdentifierFound
            }
            returnSendables.append(SendableHoerspiel(hoerspiel: hoerspiel))
        }
        return returnSendables
    }
    
    /// All ``HoerspielEntity`` matching multiple `persistentIdentifier`
    /// - Parameter identifiers: The array of `persistentIdentifier`to load the array of ``HoerspielEntity`` for
    /// - Returns: Returns an array of ``HoerspielEntity``
    public func entities(for identifiers: [HoerspielEntity.ID]) async throws -> [HoerspielEntity] {
        
        var returnEntities = [HoerspielEntity]()
        
        for identifier in identifiers {
            if let hoerspiel = try modelContext.fetch(FetchDescriptor<Hoerspiel>(predicate: #Predicate { hoerspiel in
                hoerspiel.upc == identifier
            })).first {
                returnEntities.append(
                    HoerspielEntity(
                    name: hoerspiel.title,
                    artist: hoerspiel.artist,
                    releaseDate: hoerspiel.releaseDate,
                    id: hoerspiel.upc))
            }
        }
        return returnEntities
    }
    
    /// Fetches the ``SendableSeries`` for an ``SendableHoerspiel``
    /// - Parameter sendable: The ``SendableHoerspiel``
    /// - Returns: Returns the ``SendableSeries``
    public func series(for sendable: SendableHoerspiel) throws -> SendableSeries {
        guard let model = modelContext.model(for: sendable.persistentModelID) as? Hoerspiel else {
            throw DataBaseError.propertyInUnexpectedState
        }
        if let series = model.series {
            return SendableSeries(series)
        } else {
            throw DataBaseError.propertyNotAvailable
        }
    }
    
    /// Removes each model satisfying the given predicate from the persistent storage during the next save operation.
    /// - Warning: If you don’t provide a predicate,
    /// the context will remove all models of the specified type from the persistent storage.
    /// - Parameters:
    ///   - model: The type of the model to remove.
    ///   - predicate: The logical condition to use when determining if the context should remove a particular model.
    ///   The default value is nil.
    ///   - includeSubclasses: A Boolean value that indicates whether the context includes subclasses
    ///   of the specified model type when evaluating models to remove. The default value is true.
    public func delete<T>(
        model: T.Type,
        where predicate: Predicate<T>? = nil,
        includeSubclasses: Bool = true
    ) async throws where T: PersistentModel {
        try modelContext.delete(model: T.self, where: predicate, includeSubclasses: includeSubclasses)
        try save()
    }
    
    /// Updates a specified keypath of a ``Hoerspiel`` to a specified value
    ///
    /// - Parameters:
    ///   - persistentIdentifier: The `persistentIdentifier` of the ``Hoerspiel`` to change a value from
    ///   - keypath: The keypath to change
    ///   - value: The value to change to
    /// - Throws: If no model for the specified persistentIdentifer was found,
    /// `noModelForPersistentIdentifierFound` will be thrown.
    public func update<T: Hashable>(
        _ persistentIdentifier: PersistentIdentifier,
        keypath: ReferenceWritableKeyPath<Hoerspiel, T>,
        to value: T
    ) async throws {
        Logger.data.info("Updating \(keypath.debugDescription) of \(persistentIdentifier.hashValue)")
        guard let model = modelContext.model(for: persistentIdentifier) as? Hoerspiel else {
            throw DataBaseError.noModelForPersistentIdentifierFound
        }
        model[keyPath: keypath] = value
        
        try save()
    }
    
    /// All ``HoerspielEntity`` available
    /// - Returns: Returns all ``HoerspielEntity`` available
    public func allEntities() throws -> [HoerspielEntity] {
        let hoerspiele = try modelContext.fetch(FetchDescriptor<Hoerspiel>())
        let hoerspielEntities = hoerspiele.map {
            let fileURL = documentsDirectoryPath.appendingPathComponent("\($0.upc).jpg")
            let displayImage = DisplayRepresentation.Image(url: fileURL)
            return HoerspielEntity(name: $0.title,
                                   artist: $0.artist,
                                   releaseDate: $0.releaseDate,
                                   image: displayImage,
                                   id: $0.upc)
        }
        return hoerspielEntities
    }
    
    /// Fetches all ``SendableHoerspiel`` of an artist
    /// - Parameter artist: The artist to fetch for
    /// - Returns: The ``SendableHoerspiel`` of the artist
    public func fetchHoerspiels(of artist: Artist) throws -> [SendableHoerspiel] {
        let fetchDescriptor = FetchDescriptor<Series>(predicate: #Predicate { series in
            series.musicItemID == artist.id.rawValue
        })
        guard let series = try modelContext.fetch(fetchDescriptor).first else {
            throw DataBaseError.noSeriesForIDFound
        }
        return series.hoerspiels?.compactMap { SendableHoerspiel(hoerspiel: $0) } ?? []
        
    }
    
    /// Fetches an ``Hoerspiel`` that is a top hit for playback
    /// - Returns: Returns a ``SendableHoerspiel``
    ///
    /// This is either the most recently played ``Hoerspiel`` from Up Next or the most recently released ``Hoerspiel``
    public func fetchSuggestedHoerspielForPlaybck() throws -> SendableHoerspiel {
        var upNextHoerspielDescriptor = FetchDescriptor<Hoerspiel>(predicate: #Predicate { hoerspiel in
            hoerspiel.showInUpNext
        }, sortBy: [SortDescriptor(\Hoerspiel.lastPlayed)])
        upNextHoerspielDescriptor.fetchLimit = 1
        if let upNextHoerspiel = try modelContext.fetch(upNextHoerspielDescriptor).first {
            return SendableHoerspiel(hoerspiel: upNextHoerspiel)
        }
        let now = Date.now
        var overallFetchDescriptor = FetchDescriptor<Hoerspiel>(predicate: #Predicate { hoerspiel in
            hoerspiel.releaseDate < now
        }, sortBy: [SortDescriptor(\Hoerspiel.releaseDate, order: .reverse)])
        
        if let overallHoerspiel = try modelContext.fetch(overallFetchDescriptor).first {
            return SendableHoerspiel(hoerspiel: overallHoerspiel)
        }
        throw DataBaseError.notEnoughEntities
    }
    
    enum DataBaseError: Error {
        case noModelForPersistentIdentifierFound
        case noEntityForPredefinedPredicate
        case notEnoughEntities
        case noEntityMatchingDescriptor
        case propertyNotAvailable
        case propertyInUnexpectedState
        case urlUnWrapFailed
        case noSeriesForIDFound
        case httpCodeError(Int)
        
        public var errorDescription: String? {
            switch self {
            case .noModelForPersistentIdentifierFound:
                return "Es konnte kein Hörspiel für den Identifier gefunden werden"
            case .noEntityForPredefinedPredicate:
                return "Es konnte kein Hörspiel für das vorgefertigte Predicate gefunden werden"
            case .notEnoughEntities:
                return "Es konnten nicht genug Hörspiele gefunden werden"
            case .noEntityMatchingDescriptor:
                return "Es konnte kein Hörspiel passend zum Descriptor gefunden werden"
            case .propertyNotAvailable:
                return "Der Wert ist nicht verfügbar"
            case .propertyInUnexpectedState:
                return "Der Wert war in unerwartetem Zustand"
            case .urlUnWrapFailed:
                return "Die URL konnte nicht unwrapped werden"
            case .httpCodeError(let code):
                return "Die Anfrage gab \(code) zurück"
            case .noSeriesForIDFound:
                return "No Series for ID Found"
            }
        }
    }
}
// swiftlint:enable type_body_length

/// Serves to make ``DataManager`` accessible from within all views
@MainActor
@Observable final class DataManagerClass {
    /// The instance of the ``DataManager
    let manager: DataManager
    
    init(manager: DataManager) {
        self.manager = manager
    }
}


#if DEBUG
let screenshotNames = ["Der letzte Ruf des Nebelvogels",
                       "Das Phantom der verschlossenen Kammer",
                       "Geheimnisse unter dem Dorf",
                       "Die Uhr, die Mitternacht bringt",
                       "Jenseits der verbotenen Tür",
                       "Der Alchemist und der Ewige Funke",
                       "Rätsel im Wellenbruch",
                       "Der verborgene Pfad im Mondwald"
                       
]
#endif
