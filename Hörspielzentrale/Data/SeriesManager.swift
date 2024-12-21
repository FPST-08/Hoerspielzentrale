//
//  SeriesManager.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 21.11.24.
//

@preconcurrency import MusicKit
import OSLog
import SwiftData
import SwiftUI

/// A observable class resposible for downloading series
@MainActor
@Observable
class SeriesManager {
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
        if currentlyDownloadingArtist != artist && seriesToDownload.contains(artist) {
            seriesToDownload.removeAll(where: { $0 == artist })
        } else if currentlyDownloadingArtist == artist {
            seriesToDownload.removeAll(where: { $0 == artist })
            currentDownloadTask?.cancel()
            currentProgressValue = 0.0
            currentlyDownloadingArtist = nil
            currentProgressLabel = "Download abgebrochen"
            if !seriesToDownload.isEmpty, let first = seriesToDownload.first {
                startDownload(first)
            }
            
        } else {
            Task {
                try await dataManager.deleteArtist(artist)
            }
        }
    }
    
    /// The current progress value from 0 to 1
    var currentProgressValue = 0.0
    
    /// The current textual description of the download process
    var currentProgressLabel = ""
    
    /// The currently downloading series
    var currentlyDownloadingArtist: Artist?
    
    private var currentDownloadTask: Task<(), Never>?
    
    /// Initiates the download for a series
    /// - Parameter artist: The series to start the download for
    private func startDownload(_ artist: Artist) {
        currentDownloadTask = Task {
            currentProgressValue = 0
            currentProgressLabel = "Download von \(artist.name) startet"
            currentlyDownloadingArtist = artist
            do {
                let albums = try await fetchAlbumsFor(artist)
                print(albums.count)
                let codables = await createCodableHoerspiel(from: albums).compactMap { $0 }
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
    
    /// Checks if all Hoerspiele are currently loaded and adds them if needed
    public func checkForNewReleases( // swiftlint:disable:this function_body_length
        _ continueInBackground: Bool = true
    ) async throws -> [CodableHoerspiel] {
        
        let allSeries = try await dataManager.fetch({FetchDescriptor<Series>()})
        // swiftlint:disable:next line_length
        var request = MusicCatalogResourceRequest<Artist>(matching: \.id, memberOf: allSeries.map { MusicItemID($0.musicItemID) })
        request.properties.append(.latestRelease)
        let response = try await request.response()
        
        var items = response.items
        var currentbadge = response.items
        
        while currentbadge.hasNextBatch {
            if let nextBatch = try await currentbadge.nextBatch() {
                currentbadge = nextBatch
                items += nextBatch
            }
        }
        
        var addedHoerspiels = [CodableHoerspiel]()
        
        for item in response.items {
            Logger.seriesManager.debug("Checking for \(item.name), latestRelease: \(item.latestRelease?.description ?? "N/A")") // swiftlint:disable:this line_length
            if let upc = item.latestRelease?.upc {
                Logger.seriesManager.debug("UPC of latest release is \(upc)")
                let count = try await dataManager.fetchCount({FetchDescriptor<Hoerspiel>(predicate: #Predicate { hoerspiel in // swiftlint:disable:this line_length
                    hoerspiel.upc == upc
                })})
                if count == 0 {
                    let withTracks = try await item.latestRelease?.with(.tracks)
                    guard let withTracks else {
                        break
                    }
                    let duration = withTracks.tracks?.reduce(0, { $0 + ($1.duration ?? 0) }) ?? 0
                    Logger.seriesManager.info("Found new Hoerspiel: \(withTracks.title)")
                    try await dataManager.insert(title: withTracks.title,
                                                 albumID: withTracks.id.rawValue,
                                                 duration: duration,
                                                 releaseDate: withTracks.releaseDate ?? Date.distantPast,
                                                 artist: withTracks.artistName,
                                                 upc: upc,
                                                 seriesID: item.id.rawValue)
                    addedHoerspiels.append(CodableHoerspiel(title: withTracks.title,
                                                            albumID: withTracks.id.rawValue,
                                                            duration: duration,
                                                            releaseDate: withTracks.releaseDate ?? Date.distantPast,
                                                            artist: withTracks.artistName,
                                                            upc: upc,
                                                            lastPlayedDate: Date.distantPast,
                                                            playedUpTo: 0,
                                                            played: false
                                                           ))
                    try await dataManager.save()
                    if continueInBackground {
                        Task {
                            _ = try await checkForExistenceOfAllAlbums(artist: item)
                            try await dataManager.save()
                        }
                    } else {
                        let added = try await checkForExistenceOfAllAlbums(artist: item)
                        addedHoerspiels.append(contentsOf: added)
                        try await dataManager.save()
                    }
                }
            }
        }
        return addedHoerspiels
        
    }
    
    /// Checks if all albums from an Artist exist and adds the missing ones
    /// - Parameter artist: The artist to check
    /// - Returns: Returns the added Hoerspiels
    public func checkForExistenceOfAllAlbums(artist: Artist) async throws -> [CodableHoerspiel] {
        let albums = try await fetchAlbumsFor(artist)
        let hoerspiels = try await dataManager.fetchHoerspiels(of: artist)
        
        //        let otherDiff = hoerspiels.filter { !albums.map { $0.upc }.contains($0.upc)}
        
        let diff = albums.filter { !hoerspiels.map { $0.upc }.contains($0.upc) }
        Logger.data.info("Found \(diff.count) albums that are not in the hoerspiel database")
        let codables = await createCodableHoerspiel(from: diff)
        
        try await dataManager.insert(codables, artist: artist)
        return codables
    }
    
    /// Creates ``CodableHoerspiel`` from an array of albums
    /// - Parameter albumsWithoutTracks: the albums
    /// - Returns: Returns an array of ``CodableHoerspiel`` to add to the
    ///
    /// The albums do not need to have the tracks prefetched. This function will fetch them
    public func createCodableHoerspiel(
        from albumsWithoutTracks: [Album]
    ) async -> [CodableHoerspiel] {
        
        var albums = [Album]()
        
        for chunk in albumsWithoutTracks.chunked(into: 25) {
            var requst = MusicCatalogResourceRequest<Album>(matching: \.upc, memberOf: chunk.map { $0.upc })
            requst.properties.append(.tracks)
            if let response = try? await requst.response() {
                albums.append(contentsOf: response.items)
            }
        }
        
        let codables = await albums.asyncMap { await enrichFromLibrary($0) }.compactMap { $0 }
        
        return codables
    }
    
    /// Creates a ``CodableHoerspiel`` from the provided album and the
    /// data from the Music Library if availabke
    /// - Parameter album: The album to enrich
    /// - Returns: A codable album with all properties set from either the album or the music library
    ///
    /// The tracks of the album have to be loaded beforehand. Otherwise this function returns nil
    private func enrichFromLibrary(_ album: Album) async -> CodableHoerspiel? {
        // swiftlint:disable:previous function_body_length
        guard let upc = album.upc else {
            assertionFailure()
            return nil
        }
        guard let tracks = album.tracks else {
            assertionFailure()
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
            return CodableHoerspiel(title: album.title,
                                    albumID: album.id.rawValue,
                                    duration: duration,
                                    releaseDate: releaseDate,
                                    artist: album.artistName,
                                    upc: upc,
                                    lastPlayedDate: Date.distantPast,
                                    playedUpTo: 0,
                                    played: false
            )
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
        
        return CodableHoerspiel(title: album.title,
                                albumID: album.id.rawValue,
                                duration: duration,
                                releaseDate: releaseDate,
                                artist: album.artistName,
                                upc: upc,
                                lastPlayedDate: lastPlayedDate,
                                playedUpTo: Int(playedUpTo),
                                played: played
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
