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
        trackIndex: Int,
        timeInterval: TimeInterval,
        startDate: Date,
        endDate: Date
    ) {
        guard let hoerspiel = try? await dataHandler.model(for: self) else {
            throw CalculatingStartingPointError.unableToGetModel
        }
        let tracks = try await dataHandler.fetchTracks(hoerspiel, album: nil)
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
            
            guard let firstReturnTrack = returnTracks.first else {
                throw CalculatingStartingPointError.unableToGetTrackIndex
            }
            guard let trackIndex = tracks.firstIndex(of: firstReturnTrack) else {
                throw CalculatingStartingPointError.unableToGetTrackIndex
            }
            
            return (tracks: returnTracks,
                    trackIndex: trackIndex,
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
                
                let startDate = Date.now.advanced(by: Double(-playedUpTo))
                let endDate = startDate.advanced(by: duration)
                return (tracks: tracks,
                        trackIndex: indexOfTrack,
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
}

/// An Error used to communicate Errors when calculating the starting point of a ``Hoerspiel``
enum CalculatingStartingPointError: Error {
    case unableToGetStoredDuration,
         unableToGetPlayedUpTo,
         unableToGetTrackIndex,
         unableToGetReleaseDate,
         unableToFindMatchingTrack,
         unableToGetModel
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
        case .unableToGetModel:
            return "Das entsprechende Hörspiel wurde nicht gefunden"
        }
    }
}

extension SendableHoerspiel {
    /// Loads the corresponding metadata from `dreimetadaten.de`
    /// - Returns: Returns the ``MetaData``
    func loadMetaData() async throws -> MetaData {
        try await loadMetaDataInternal(artistName: self.artist, albumID: self.albumID)
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

extension Album {
    /// Loads the corresponding metadata from `dreimetadaten.de`
    /// - Returns: Returns the ``MetaData``
    func loadMetaData() async throws -> MetaData {
        try await loadMetaDataInternal(artistName: self.artistName, albumID: self.id.rawValue)
    }
    
    /// A bool tha indicates if self has a disclaimer
    var hasDisclaimer: Bool {
        if let episodeNumber = self.episodeNumber,
           self.artistName == "Die drei ???",
           hoerspielNumbersWithDisclaimer.contains(episodeNumber) {
            return true
        } else {
            return false
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
}

/// Loads the corresponding metadata from `dreimetadaten.de`
/// - Returns: Returns the ``MetaData``
private func loadMetaDataInternal(artistName: String, albumID: String) async throws -> MetaData {
    guard artistName != "Die drei ???" || artistName != "Die drei ??? Kids" else {
        throw MetaDataError.seriesNotSupported
    }
    
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

extension SendableHoerspiel {
    func album(_ dataManager: DataManager) async throws -> Album {
        do {
            let request = MusicCatalogResourceRequest<Album>(matching: \.upc, equalTo: self.upc)
            let response = try await request.response()
            if let album = response.items.first(where: { $0.upc == self.upc }) {
                await updateValues(album: album, dataManager)
                Logger.data.info("Fetched album via upc")
                return album
            }
            Logger.data.warning("Unable to fetch album \(self.title) via upc \(self.upc)")
        }
        do {
            let request = MusicCatalogResourceRequest<Album>(matching: \.id, equalTo: MusicItemID(self.albumID))
            let response = try await request.response()
            if let album = response.items.first(where: { $0.id.rawValue == self.albumID }) {
                await updateValues(album: album, dataManager)
                Logger.data.info("Fetched album via albumID")
                return album
            }
            Logger.data.warning("Unable to fetch album \(self.title) via id \(self.albumID)")
        }
        do {
            let request = MusicCatalogSearchRequest(term: self.title, types: [Album.self])
            let response = try await request.response()
            if let album = response.albums.first(where: { $0.title == self.title && $0.artistName == self.artist }) {
                await updateValues(album: album, dataManager)
                return album
            }
            Logger.data.warning("Unable to fetch album \(self.title) via title")
        }
        throw GettingAlbumError.unableToLoadAlbumViaDifferentMethods
    }
    
    private func updateValues(album: Album, _ dataManager: DataManager) async {
        if let upc = album.upc {
            try? await dataManager.update(self.persistentModelID, keypath: \.upc, to: upc)
        }
        try? await dataManager.update(self.persistentModelID, keypath: \.albumID, to: album.id.rawValue)
    }
}
