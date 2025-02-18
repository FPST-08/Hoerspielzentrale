//
//  SeriesManager.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 21.11.24.
//

import Defaults
import DefaultsMacros
@preconcurrency import MusicKit
import OSLog
import SwiftData
import SwiftUI

// swiftlint:disable file_length
/// A observable class resposible for downloading series
@MainActor
@Observable
class SeriesManager {
    // swiftlint:disable:previous type_body_length
    /// The datamanager to perform database operations
    let dataManager: DataManager
    
    init(dataManager: DataManager) {
        self.dataManager = dataManager
    }
    
    /// The queue of series to download
    ///
    /// This should not directly be modified.
    private(set) var seriesToDownload = [Artist]() {
        didSet {
            if currentlyDownloadingArtist == nil {
                if let first = seriesToDownload.first {
                    startDownload(first)
                }
            }
        }
    }
    
    /// Adds a series to the download queue
    /// - Parameter series: The series to append to the queue
    func downloadSeries(_ artist: Artist) {
        seriesToDownload.append(artist)
    }
    
    /// Removes a series
    /// - Parameter series: The series to remove
    func removeSeries(_ artist: Artist) {
        if currentlyDownloadingArtist == artist {
            currentDownloadTask?.cancel()
            currentProgressValue = 0.0
            currentlyDownloadingArtist = nil
            currentProgressLabel = "Download abgebrochen"
            if !seriesToDownload.isEmpty, let first = seriesToDownload.first {
                startDownload(first)
            }
            
        }
        Task {
            try? await dataManager.deleteArtist(artist)
        }
        selectedArtists.removeAll(where: { $0 == artist })
        seriesToDownload.removeAll(where: { $0 == artist })
    }
    
    /// The current progress value from 0 to 1
    var currentProgressValue = 0.0
    
    /// The current textual description of the download process
    var currentProgressLabel = ""
    
    /// Artists that are already saved to storage
    var selectedArtists: [Artist] = []
    
    /// The currently downloading series
    var currentlyDownloadingArtist: Artist?
    
    private var currentDownloadTask: Task<(), Never>?
    
    /// The currently running task to update contents from the library
    private var currentLibraryTask: Task<(), Never>?
    
    /// Initiates the download for a series
    /// - Parameter artist: The series to start the download for
    private func startDownload(_ artist: Artist) {
        currentDownloadTask = Task {
            selectedArtists.append(artist)
            currentProgressValue = 0
            currentProgressLabel = "Download von \(artist.name) startet"
            currentlyDownloadingArtist = artist
            do {
                let albums = try await fetchAlbumsFor(artist)
                print(albums.count)
                let codables = await createInsertableHoerspiels(from: albums).compactMap { $0 }
                currentProgressLabel = "Speichern von \(codables.count) Hörspielen"
                currentProgressValue = 0.95
                print(codables.count)
                try await dataManager.insert(codables, artist: artist)
            } catch {
                Logger.data.fullError(error,
                                      additionalParameters: ["Series.Name": artist.name,
                                                             "Series.ID": artist.id.rawValue],
                                      sendToTelemetryDeck: true)
            }
            currentProgressValue = 1
            currentProgressLabel = ""
            seriesToDownload.removeAll(where: { $0 == artist })
            if !seriesToDownload.isEmpty {
                if let first = seriesToDownload.first {
                    startDownload(first)
                }
            } else {
                currentlyDownloadingArtist = nil
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                currentProgressValue = 0
            }
        }
    }
    
    /// Fetches all albums for an artist
    /// - Parameter artist: The artist
    /// - Returns: Returns the albums
    private func fetchAlbumsFor(_ artist: Artist) async throws -> [Album] {
        let artistWithAlbums = try await artist.with(.albums)
        
        var allAlbums = [Album]()
        
        guard var currentBadge = artistWithAlbums.albums else {
            print("Currentbadge war nicht drin")
            return []
        }
        allAlbums.append(contentsOf: currentBadge)
        
        currentProgressLabel = "Chunk mit \(currentBadge.first?.title ?? "N/A") wurde geladen"
        currentProgressValue = 0.1
        while currentBadge.hasNextBatch {
            if let nextBatch = try await currentBadge.nextBatch() {
                currentBadge = nextBatch
                allAlbums.append(contentsOf: nextBatch)
                currentProgressLabel = "Chunk mit \(currentBadge.first?.title ?? "N/A") wurde geladen"
                Logger.seriesManager.info("""
Fetching batch of \(currentBadge.first?.title ?? "N/A") by \(currentBadge.first?.artistName ?? "N/A")
""")
            } else {
                print("Couldn't load next batch")
                break
            }
        }
        currentProgressValue = 0.3
        return allAlbums
    }
    
    /// Fetches all Series and returns the corresponding artists
    /// - Returns: The corresponding artists
    nonisolated private func fetchAllArtists() async throws -> [Artist] {
        let allSeries = try await dataManager.fetchAllSeries()
        
        var artists = [Artist]()
        
        let chunked = allSeries.chunked(into: 50)
        for chunk in chunked {
            let ids = chunk.map { MusicItemID($0.musicItemID) }
            let request = MusicCatalogResourceRequest<Artist>(matching: \.id, memberOf: ids)
            let response = try await request.response()
            artists.append(contentsOf: response.items)
        }
        return artists
    }
    
    /// Fetches playback updates from the apple music library
    func fetchUpdatesFromMusicLibrary() async {
        currentLibraryTask?.cancel()
        currentLibraryTask = Task.detached {
            Logger.seriesManager.info("Fetching Updates from Apple Music")
                    do {
                        let artists = try await self.fetchAllArtists()
                        var albums = [Album]()
                        for artist in artists {
                            let artistAlbums = try await self.fetchAlbumsFor(artist)
                            albums.append(contentsOf: artistAlbums)
                        }
                        
                        albums = await self.fetchTracksForAlbums(albums)
                        
                        var insertables = [InsertableHoerspiel]()
                        
                        for album in albums {
                            Logger.seriesManager.info("Enriching \(album.title)")
                            if let enriched = await self.enrichFromLibrary(album) {
                                Logger.seriesManager.info("Retrieved data from \(enriched.title)")
                                insertables.append(enriched)
                            }
                        }
                        for insertable in insertables {
                            Logger.seriesManager.info("Updating \(insertable.title) with upc \(insertable.upc)")
                            do {
                                try await self.dataManager.updateHoerspielWhenSuitable(insertable)
                            } catch {
                                Logger.maintenance.fullError(error, sendToTelemetryDeck: false)
                            }
                        }
                    } catch {
                        Logger.maintenance.fullError(error, sendToTelemetryDeck: true)
                    }
        }
    }
    
    /// Checks if all Hoerspiele are currently loaded and adds them if needed
    public func checkForNewReleases() async throws {
        
        let allSeries = try await dataManager.fetch({FetchDescriptor<Series>()})
        
        var responseArtists = [Artist]()
        
        let chunked = allSeries.chunked(into: 50)
        for chunk in chunked {
            let ids = chunk.map { MusicItemID($0.musicItemID) }
            var request = MusicCatalogResourceRequest<Artist>(matching: \.id, memberOf: ids)
            request.properties.append(.latestRelease)
            let response = try await request.response()
            responseArtists.append(contentsOf: response.items)
        }
        
        for artist in responseArtists {
            Logger.seriesManager.debug("Checking for \(artist.name), latestRelease: \(artist.latestRelease?.description ?? "N/A")") // swiftlint:disable:this line_length
            if let upc = artist.latestRelease?.upc {
                Logger.seriesManager.debug("UPC of latest release is \(upc)")
                let count = try await dataManager.fetchCount({FetchDescriptor<Hoerspiel>(predicate: #Predicate { hoerspiel in // swiftlint:disable:this line_length
                    hoerspiel.upc == upc
                })})
                if count == 0 {
                    let withTracks = try await artist.latestRelease?.with(.tracks)
                    guard let withTracks else {
                        break
                    }
                    Logger.seriesManager.info("Found new Hoerspiel: \(withTracks.title)")
                    
                    let hoerspiel = await createInsertableHoerspiels(from: [withTracks])
                    _ = try await dataManager.insert(hoerspiel, artist: artist)
                    
                    try await dataManager.save()
                    Task {
                        _ = try await checkForExistenceOfAllAlbums(artist: artist)
                        try await dataManager.save()
                    }
                }
            }
        }
    }
    
    /// Checks if new releases are available
    /// 
    /// This function might take a while to complete
    /// - Returns: Returns all of the added ``SendableHoerspiel``
    @discardableResult public func checkForNewReleasesInBackground() async throws -> [SendableHoerspiel] {
        let allSeries = try await dataManager.fetch({FetchDescriptor<Series>()})
        
        var responseArtists = [Artist]()
        
        let chunked = allSeries.chunked(into: 50)
        for chunk in chunked {
            let ids = chunk.map { MusicItemID($0.musicItemID) }
            var request = MusicCatalogResourceRequest<Artist>(matching: \.id, memberOf: ids)
            request.properties.append(.latestRelease)
            let response = try await request.response()
            responseArtists.append(contentsOf: response.items)
        }
        
        var addedHoerspiels = [SendableHoerspiel]()
        
        for artist in responseArtists {
            Logger.seriesManager.debug("Checking for \(artist.name), latestRelease: \(artist.latestRelease?.description ?? "N/A")") // swiftlint:disable:this line_length
            if let upc = artist.latestRelease?.upc {
                Logger.seriesManager.debug("UPC of latest release is \(upc)")
                let count = try await dataManager.fetchCount({FetchDescriptor<Hoerspiel>(predicate: #Predicate { hoerspiel in // swiftlint:disable:this line_length
                    hoerspiel.upc == upc
                })})
                if count == 0 {
                    let added = try await checkForExistenceOfAllAlbums(artist: artist)
                    Logger.data.debug("Series of hoerspiels: \(added.map { $0.series?.name ?? "N/A"})")
                    addedHoerspiels.append(contentsOf: added)
                    try await dataManager.save()
                }
            }
        }
        return addedHoerspiels
    }
    
    /// Checks if all albums from an Artist exist and adds the missing ones
    /// - Parameter artist: The artist to check
    /// - Returns: Returns the added Hoerspiels
    public func checkForExistenceOfAllAlbums(artist: Artist) async throws -> [SendableHoerspiel] {
        let albums = try await fetchAlbumsFor(artist)
        let hoerspiels = try await dataManager.fetchHoerspiels(of: artist)
        let diff = albums.filter { !hoerspiels.map { $0.upc }.contains($0.upc) }
        Logger.data.info("Found \(diff.count) albums that are not in the hoerspiel database")
        let codables = await createInsertableHoerspiels(from: diff)
        return try await dataManager.insert(codables, artist: artist)
    }
    
    /// Creates ``CodableHoerspiel`` from an array of albums
    /// - Parameter albumsWithoutTracks: the albums
    /// - Returns: Returns an array of ``CodableHoerspiel`` to add to the
    ///
    /// The albums do not need to have the tracks prefetched. This function will fetch them
    public func createInsertableHoerspiels(
        from albumsWithoutTracks: [Album]
    ) async -> [InsertableHoerspiel] {
        
        var albums = [Album]()
        
        for chunk in albumsWithoutTracks.chunked(into: 25) {
            var requst = MusicCatalogResourceRequest<Album>(matching: \.upc, memberOf: chunk.map { $0.upc })
            requst.properties.append(.tracks)
            if let response = try? await requst.response() {
                albums.append(contentsOf: response.items)
                currentProgressLabel = """
Daten für \(response.items.first?.title ?? "N/A") und \(chunk.count - 1) \ 
weitere wurde geladen
"""
                currentProgressValue += (1 / (Double(albumsWithoutTracks.count) / 25)) * 0.6
            }
        }
        
        let codables = await albums.asyncMap { await enrichFromLibrary($0) }.compactMap { $0 }
        
        return codables
    }
    
    /// Fetches the tracks for all provided albums
    /// - Parameter albums: The albums to fetch the tracks for
    /// - Returns: The
    nonisolated public func fetchTracksForAlbums(_ albums: [Album]) async -> [Album] {
        var returnAlbums = [Album]()
        for chunk in albums.chunked(into: 25) {
            var requst = MusicCatalogResourceRequest<Album>(matching: \.upc, memberOf: chunk.map { $0.upc })
            requst.properties.append(.tracks)
            if let response = try? await requst.response() {
                returnAlbums.append(contentsOf: response.items)
            }
        }
        returnAlbums = returnAlbums.filter { album in
            album.tracks?.contains { $0.playParameters != nil } == true
        }
        return returnAlbums
    }
    
    /// Creates a ``CodableHoerspiel`` from the provided album and the
    /// data from the Music Library if availabke
    /// - Parameter album: The album to enrich
    /// - Returns: A codable album with all properties set from either the album or the music library
    ///
    /// The tracks of the album have to be loaded beforehand. Otherwise this function returns nil
    nonisolated private func enrichFromLibrary(_ album: Album) async -> InsertableHoerspiel? {
        // swiftlint:disable:previous function_body_length
        guard let upc = album.upc else {
            assertionFailure()
            return nil
        }
        guard let tracks = album.tracks else {
            assertionFailure()
            return nil
        }
        
        guard tracks.contains(where: { $0.playParameters != nil }) else {
            Logger.seriesManager.notice("All of the tracks have empty play parameters, returning nil")
            return nil
        }
        
        let duration = tracks.reduce(0, { $0 + ($1.duration ?? 0)})
        
        let releaseDate = album.releaseDate ?? Date.distantPast
        
        let chunkedTracks = tracks.chunked(into: 25)
        var tracksWithDate = [Track]()
        for chunk in chunkedTracks {
            var request = MusicLibraryRequest<Track>()
            request.filter(matching: \.id, memberOf: chunk.map { $0.id})
            do {
                let response = try await request.response()
                tracksWithDate.append(contentsOf: response.items)
            } catch {
                Logger.seriesManager.fullError(error, sendToTelemetryDeck: true)
            }
        }
        
        // Not all tracks are available in the music library.
        // Therefore return the
        if tracksWithDate.count != tracks.count {
            return InsertableHoerspiel(title: album.title,
                                       albumID: album.id.rawValue,
                                       duration: duration,
                                       releaseDate: releaseDate,
                                       artist: album.artistName,
                                       upc: upc,
                                       lastPlayed: Date.distantPast,
                                       playedUpTo: 0,
                                       played: false,
                                       tracks: tracks.asStoredTracks())
        }
        var currentIndex = 0
        
        var currentTrackDate: Date {
            tracksWithDate[safe: currentIndex]?.lastPlayedDate ?? Date.distantPast
        }
        var nextTrackDate: Date {
            tracksWithDate[safe: currentIndex + 1]?.lastPlayedDate ?? Date.distantPast
        }
        
        while currentTrackDate < nextTrackDate {
            currentIndex += 1
        }
        let tracksUpToCurrentIndex = tracksWithDate[..<currentIndex]
        
        let playedUpTo = tracksUpToCurrentIndex.reduce(0) { $0 + ($1.duration ?? 0) }
        let lastPlayedDate = tracksWithDate.map { $0.lastPlayedDate ?? Date.distantPast }.max() ?? Date.distantPast
        let played = tracksWithDate.last?.lastPlayedDate != nil
        
        return InsertableHoerspiel(title: album.title,
                                albumID: album.id.rawValue,
                                duration: duration,
                                releaseDate: releaseDate,
                                artist: album.artistName,
                                upc: upc,
                                lastPlayed: lastPlayedDate,
                                playedUpTo: Int(playedUpTo),
                                played: played,
                                   tracks: tracks.asStoredTracks()
        )
    }
}

extension MusicItemCollection<Track> {
    func chunked(into size: Int) -> [[Track]] {
        var tracks = [Track]()
        tracks.append(contentsOf: self)
        return tracks.chunked(into: 25)
    }
}
