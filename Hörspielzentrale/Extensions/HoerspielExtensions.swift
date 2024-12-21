//
//  HoerspielExtensions.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 18.06.24.
//

import Foundation
import MusicKit
import OSLog
import SwiftData
import SwiftUI
import TelemetryDeck

extension PersistentIdentifier {
    // swiftlint: disable cyclomatic_complexity
    // swiftlint: disable function_body_length
    // swiftlint: disable large_tuple
    /// Calculates the correct starting point of a ``Hoerspiel``
    /// - Parameter dataHandler: The datahandler used for database access
    /// - Returns: Returns a tuple for the startpoint
    func calculateStartingPoint(
        _ dataHandler: DataManager
    ) async throws -> (
        tracks: [SendableStoredTrack],
        timeInterval: TimeInterval,
        startDate: Date,
        endDate: Date
    ) {
        let tracks = try await self.tracks(dataHandler)
        let duration = tracks.reduce(0) { $0 + ($1.duration)}
        guard let storedDuration = try? await dataHandler.read(self, keypath: \.duration) else {
            Logger.data.fault("Unable to get stored duration")
            throw CalculatingStartingPointError.unableToGetStoredDuration
        }
        if duration != storedDuration {
            try? await dataHandler.update(self, keypath: \.duration, to: duration)
        }
        var remainingTime: TimeInterval = 0
        guard let playedUpTo = try? await dataHandler.read(self, keypath: \.playedUpTo) else {
            Logger.data.fault("Unable to get playedUpTo")
            throw CalculatingStartingPointError.unableToGetPlayedUpTo
        }
        
        let smartskipenabled = UserDefaults.standard.bool(forKey: "smartskipenabled")
        if playedUpTo == 0 && smartskipenabled {
            var currentPoint: Double = 0
            let skipDisclaimer = UserDefaults.standard.bool(forKey: "smartskipdisclaimer")
            let skipIntro = UserDefaults.standard.bool(forKey: "smartskipintro")
            //            let skipMusic = UserDefaults.standard.bool(forKey: "smartskipmusic")
            
            let withDisclaimer = [1, 3, 4, 6, 19, 35]
            
            var startPoint: TimeInterval = 0
            
            var returnTracks = [SendableStoredTrack]()
            
            for track in tracks {
                returnTracks.append(track)
            }
            
            guard let releaseDate = try? await dataHandler.read(self, keypath: \.releaseDate) else {
                throw CalculatingStartingPointError.unableToGetReleaseDate
            }
            
            if skipIntro && releaseDate.isPast() {
                if tracks.first?.title.contains("Inhaltsangabe") == true {
                    if let trackDuration = tracks.first?.duration {
                        currentPoint += trackDuration
                    }
                    returnTracks.removeFirst()
                }
            }
            if skipDisclaimer {
                if let title = try? await dataHandler.read(self, keypath: \.title) {
                    let comp = title.components(separatedBy: " ")[safe: 1]
                    let rep = comp?.replacingOccurrences(of: ":", with: "")
                    if let rep = rep {
                        if let int = Int(rep), withDisclaimer.contains(int) {
                            startPoint += 42
                            currentPoint += 42
                        }
                    }
                }
            }
            let startDate = Date.now.advanced(by: Double(-currentPoint))
            let endDate = Date.now.advanced(by: duration)
            
            return (tracks: returnTracks,
                    timeInterval: startPoint,
                    startDate: startDate,
                    endDate: endDate)
        }
        
        remainingTime = TimeInterval(playedUpTo)
        
        for track in tracks {
            let trackDuration = track.duration
            if remainingTime > trackDuration {
                remainingTime -= trackDuration
            } else {
                guard let indexOfTrack = tracks.firstIndex(of: track) else {
                    Logger.data.fault("Unable to get track index from its own array")
                    throw CalculatingStartingPointError.unableToGetTrackIndex
                }
                let returnTracks = Array(tracks[indexOfTrack...])
                let startDate = Date.now.advanced(by: Double(-playedUpTo))
                let endDate = startDate.advanced(by: duration)
                return (tracks: returnTracks,
                        timeInterval: remainingTime,
                        startDate: startDate,
                        endDate: endDate)
            }
        }
        throw CalculatingStartingPointError.unableToFindMatchingTrack
    }
    // swiftlint: enable cyclomatic_complexity
    // swiftlint: enable function_body_length
    // swiftlint: enable large_tuple
    
    /// The ``SendableStoredTrack`` for a hoerspiel
    /// - Parameter dataManager: The dataManager used for database access
    /// - Returns: Returns an array of ``SendableStoredTrack``
    func tracks(_ dataManager: DataManager) async throws -> [SendableStoredTrack] {
        let storedTracks = try? await dataManager.fetchTracks(self)
        if let storedTracks, !storedTracks.isEmpty {
            Logger.data.info("Tracks were loaded from storage, count: \(storedTracks.count)")
            return storedTracks.sorted()
        }
        guard let tracks = try await self.album(dataManager)?.with(.tracks).tracks else {
            throw GettingAlbumError.appleMusicError
        }
        Logger.data.info("Tracks were loaded from Apple Music")
        let sendableTracks = tracks.map { SendableStoredTrack($0, index: tracks.firstIndex(of: $0)!)}
        try? await dataManager.setTracks(self, sendableTracks)
        return sendableTracks
    }
}

extension Array where Element == SendableStoredTrack {
    /// Sorts an array of ``SendableStoredTrack`` starting with the lowest index
    /// - Returns: The sorted array
    func sorted() -> [SendableStoredTrack] {
        self.sorted { $0.index < $1.index }
    }
}

/// An Error used to communicate Errors when calculating the starting point of a ``Hoerspiel``
enum CalculatingStartingPointError: Error {
    case unableToGetStoredDuration,
         unableToGetPlayedUpTo,
         unableToGetTrackIndex,
         unableToGetReleaseDate,
         unableToFindMatchingTrack
}

extension CalculatingStartingPointError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .unableToGetStoredDuration:
            return "Die Dauer des Hörspiels konnte nicht geladen werden"
        case .unableToGetPlayedUpTo:
            return "Der Hörfortschritt konnte nicht geladen werden"
        case .unableToGetTrackIndex:
            return "Der Index eines Tracks konnte nicht geladen werden"
        case .unableToGetReleaseDate:
            return "Das Veröffentlichungsdatum konnte nicht geladen werden. Dies ist für Smart Skip erforderlich"
        case .unableToFindMatchingTrack:
            return "Der entsprechende Titel konnte nicht gefunden werden"
        }
    }
}

extension SendableHoerspiel {
    /// Loads the corresponding metadata from `dreimetadaten.de`
    /// - Returns: Returns the ``MetaData``
    func loadMetaData() async throws -> MetaData {
        guard self.artist != "Die drei ???" || self.artist != "Die drei ??? Kids" else {
            throw MetaDataError.seriesNotSupported
        }
        let albumID = self.albumID
        
        guard let url = URL(string: "https://v2.dreimetadaten.de/index/apple-music/\(albumID)") else {
            throw MetaDataError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        let httpResponse = response as? HTTPURLResponse
        
        guard let httpResponse = httpResponse, httpResponse.statusCode == 200 else {
            
            Logger.metadata.error("Status count is not 200, \(httpResponse?.statusCode ?? 0)")
            
            throw MetaDataError.unknownError
        }
        do {
            let decodedData = try JSONDecoder().decode(MetaData.self, from: data)
            return decodedData
        } catch {
            throw MetaDataError.unexpectedResponse
        }
    }
    
    /// The episode number of self
    var episodeNumber: Int? {
        let numAsString = self.title.components(separatedBy: " ")[safe: 1]?.replacingOccurrences(of: ":", with: "")
        if let numAsString {
            return Int(numAsString)
        } else {
            return nil
        }
    }
    
    /// A bool tha indicates if self has a disclaimer
    var hasDisclaimer: Bool {
        if let episodeNumber = self.episodeNumber,
           self.artist == "Die drei ???",
           hoerspielNumbersWithDisclaimer.contains(episodeNumber) {
            return true
        } else {
            return false
        }
    }
    
}

/// An Error used to communicate `MetaData` loading errors
enum MetaDataError: Error, LocalizedError {
    case invalidURL
    case httpError
    case unknownError
    case unexpectedResponse
    case seriesNotSupported
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            "Die URL zum Laden der Metadaten ist ungültig"
        case .httpError:
            "Ein Problem mit der Netzwerk-Abfrage trat auf"
        case .unknownError:
            "Unbekannter Fehler"
        case .unexpectedResponse:
            "Der Server hat eine unerwartete Antwort zurückgegeben"
        case .seriesNotSupported:
            "Metadaten für diese Serie sind aktuell nicht verfügbar"
        }
    }
}

extension PersistentIdentifier {
    func album(_ dataHandler: DataManager) async throws -> Album? {
        let itemID = await MusicItemID(try dataHandler.read(self, keypath: \.albumID))
        let albumRequest = MusicCatalogResourceRequest<Album>(matching: \.id, equalTo: itemID)
        let albumResponse = try? await albumRequest.response()
        
        if let album = albumResponse?.items.first {
            return album
        } else {
            Logger.data.error("Unable to get response from albumRequest with id \(itemID)")
        }
        guard let title = try? await dataHandler.read(self, keypath: \.title) else {
            throw GettingAlbumError.unableToReadTitle
        }
        let searchRequest = MusicCatalogSearchRequest(term: title, types: [Album.self])
        let searchResponse = try? await searchRequest.response()
        if let album = searchResponse?.albums.first(where: { $0.title == title }) {
            do {
                try await dataHandler.update(self, keypath: \.albumID, to: album.id.rawValue)
                Logger.data.info("Updated album ID for \(title)")
            } catch {
                Logger.data.fullError(error, sendToTelemetryDeck: true)
            }
            return album
        }
        Logger.data.error("Couldn't get album with json nor get album with custom fetch for title \(title)")
        throw GettingAlbumError.secondOptionFailed
    }
}
