//
//  musicplayer.swift
//  diedreifragezeichenplayer
//
//  Created by Philipp Steiner on 03.04.24.
//

@preconcurrency import MediaPlayer
import MusicKit
import OSLog
import SwiftData
import SwiftUI
import TelemetryDeck
import WidgetKit

/// A class resposible for all playback related actions
@MainActor
@Observable final class MusicManager {
    init(dataManager: DataManager, navigation: NavigationManager, imageCache: ImageCache) {
        self.dataManager = dataManager
        self.navigation = navigation
        self.imageCache = imageCache
    }
    
    // MARK: - Proerties
    let dataManager: DataManager
    
    let navigation: NavigationManager
    
    let imageCache: ImageCache
    
    let musicplayer = MPMusicPlayerController.applicationMusicPlayer
    
    var startDate: Date?
    var initiatedDate: Date?
    var endDate: Date?
    
    /// The currently playing ``SendableHoerspiel``
    var currentlyPlayingHoerspiel: SendableHoerspiel?
    
    /// The cover of the currently playing ``SendableHoerspiel``
    var currentlyPlayingHoerspielCover: UIImage?
    
    var playbackDuration = 0.0
    
    var volume: Double = 0
    
    var timer = Timer.scheduledTimer(withTimeInterval: 0, repeats: false) { _ in }
    var sleeptimerDate: Date?
    
    var showSleeptimer: Bool {
        sleeptimerDate != nil
    }
    
    var startedTrackID: MusicItemID?
    
    // MARK: Functions
    
    func startPlayback(for persistentIdentifier: PersistentIdentifier) async {
        await initiatePlayback(for: persistentIdentifier)
    }
    
    /// Retroactively calculates `startDate`, `endDate`and `initiatedDate`
    func calculateDatesWhilePlaying() async {
        do {
            guard let currentlyPlayingTrack = musicplayer.nowPlayingItem else {
                return
            }
            
            guard let currentPlayingTrackAlbumTitle = currentlyPlayingTrack.albumTitle else {
                return
            }
            
            guard let identifier = try await dataManager.fetchIdentifiers({
                FetchDescriptor<Hoerspiel>(predicate: #Predicate { hoerspiel in
                    hoerspiel.title == currentPlayingTrackAlbumTitle
                })}).first else {
                return
            }
            
            let duration = try await dataManager.read(identifier, keypath: \.duration)
            
            let tracks = try await identifier.tracks(dataManager).sorted()
            
            var currentPlayBackTime = self.musicplayer.currentPlaybackTime
            
            guard let currentTrack = tracks.firstIndex(where: {
                $0.title == currentlyPlayingTrack.title ?? ""
            }) else {
                return
            }
            var sumOfAlreadyPlayedTracks: TimeInterval = 0
            for index in 0..<currentTrack {
                sumOfAlreadyPlayedTracks += tracks[index].duration
            }
            currentPlayBackTime += sumOfAlreadyPlayedTracks
            startDate = Date.now - currentPlayBackTime
            endDate = Date.now + (duration - currentPlayBackTime)
            initiatedDate = Date.now
        } catch {
            Logger.playback.fullError(error, sendToTelemetryDeck: true)
        }
    }
    
    private func initiatePlayback(for persistentIdentifier: PersistentIdentifier) async {
#if DEBUG
        guard let hoerspiel = try? await dataManager.batchRead(persistentIdentifier) else {
            return
        }
        
        if hoerspiel.upc == "DEBUG" {
            startDate = Date().advanced(by: -2310)
            endDate = Date().advanced(by: 2190)
            currentlyPlayingHoerspiel = hoerspiel
            currentlyPlayingHoerspielCover = UIImage(color: .random)
            return
        }
#endif
        do {
            let subscription = try await MusicSubscription.current
            
            guard subscription.canPlayCatalogContent else {
                Logger.authorization.info("User cannot play catalog content")
                
                if subscription.canBecomeSubscriber, let album = try await persistentIdentifier.album(dataManager) {
                    navigation.presentMusicSubscriptionSheet(itemID: album.id.rawValue)
                } else {
                    navigation.presentAlert(
                        title: "Es ist ein Fehler aufgetreten",
                        description: "Es können keine Hörspiele abgespielt werden")
                }
                return
            }
            
            let hoerspiel = try await dataManager.batchRead(persistentIdentifier)
            
            if !hoerspiel.showInUpNext {
                try await dataManager.update(persistentIdentifier, keypath: \.showInUpNext, to: true)
            }
            try? await dataManager.update(persistentIdentifier, keypath: \.lastPlayed, to: Date.now)
            
            let startPoint = try await persistentIdentifier.calculateStartingPoint(dataManager)
            musicplayer.stop()
            musicplayer.setQueue(with: startPoint.tracks.map { $0.musicItemID })
            try await musicplayer.prepareToPlay()
            musicplayer.currentPlaybackTime = startPoint.timeInterval
            musicplayer.play()
            currentlyPlayingHoerspiel = hoerspiel
            currentlyPlayingHoerspielCover = await imageCache.uiimage(for: hoerspiel)
            startDate = startPoint.startDate
            initiatedDate = Date.now
            endDate = startPoint.endDate
            if let musicItemID = startPoint.tracks.first?.musicItemID {
                startedTrackID = MusicItemID(musicItemID)
            }
            
            let series = try? await dataManager.series(for: hoerspiel)
            TelemetryDeck.signal("Playback.starting", parameters: [
                "Hoerspiel": hoerspiel.title,
                "SeriesName": series?.name ?? "N/A",
                "SeriesID": series?.musicItemID ?? "N/A"
            ])
        } catch {
            let title = try? await dataManager.read(persistentIdentifier, keypath: \.title)
            Logger.playback.fullError(error, additionalParameters: [
                "Hoerspiel": title ?? "N/A",
                "Error": String("\(error)"),
                "Error.Description": error.localizedDescription
            ], sendToTelemetryDeck: true)
        }
    }
    
    /// Plays a seemingly random ``Hoerspiel``
    ///
    /// If possible it prefers a ``Hoerspiel`` where the playback has not been initialized yet
    /// and the series is currently displayed. If that is not possible, it tries to play a ``Hoerspiel``
    /// where the series is currently displayed. The last attempt tries to play any ``Hoerspiel`` from the database
    func playRandom() async {
        await internalSaveListeningProgress()
        do {
            let displayedArtists = UserDefaults.standard[.displayedSortArtists]
            let seriesNames = displayedArtists.map { $0.name }
            let id = try? await dataManager.fetchRandom {
                var descriptor = FetchDescriptor<Hoerspiel>()
                descriptor = FetchDescriptor(predicate: #Predicate<Hoerspiel> { hoerspiel in
                    if hoerspiel.playedUpTo != 0 || hoerspiel.played {
                        return false
                    } else {
                        return seriesNames.contains(hoerspiel.artist)
                    }
                })
                return descriptor
            }
            if let id {
                await initiatePlayback(for: id)
            } else {
                let backUPID = try? await dataManager.fetchRandom {
                    var descriptor = FetchDescriptor<Hoerspiel>()
                    descriptor = FetchDescriptor(predicate: #Predicate<Hoerspiel> { hoerspiel in
                        if hoerspiel.series != nil {
                            return seriesNames.contains(hoerspiel.artist)
                        } else {
                            return false
                        }
                    })
                    return descriptor
                }
                if let backUPID {
                    await initiatePlayback(for: backUPID)
                } else {
                    let finalID = try await dataManager.fetchRandom { FetchDescriptor<Hoerspiel>() }
                    await initiatePlayback(for: finalID)
                }
            }
        } catch {
            navigation.presentAlert(title: "Es konnte keine zufällige Wiedergabe gestartet werden",
                                    description: "Grund: \(error.localizedDescription)")
            Logger.data.fullError(error, sendToTelemetryDeck: true)
        }
    }
    
    func startSleepTimer(for duration: Int) {
        TelemetryDeck.signal("Playback.startedSleepTimer", parameters: ["Duration": duration.formatted()])
        timer.invalidate()
        let timeInterval = TimeInterval(duration * 60)
        sleeptimerDate = Date.now.advanced(by: timeInterval)
        timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { [self] _ in
            Task(priority: .high) {
                await MainActor.run {
                    sleeptimerDate = nil
                    musicplayer.pause()
                    
                }
                await saveListeningProgressAsync()
                
            }
        }
    }
    
    /// Toggles the playback when appropriate or initiates a new playback
    func togglePlayback(for hoerspiel: PersistentIdentifier) async {
        if hoerspiel == currentlyPlayingHoerspiel?.persistentModelID, musicplayer.playbackState == .playing {
            musicplayer.pause()
        } else if hoerspiel == currentlyPlayingHoerspiel?.persistentModelID && musicplayer.playbackState != .playing {
            musicplayer.play()
        } else {
            await internalSaveListeningProgress()
            await initiatePlayback(for: hoerspiel)
        }
    }
    
    /// Toggles the playback
    func togglePlayback() {
        if musicplayer.playbackState == .playing {
            musicplayer.pause()
        } else {
            musicplayer.play()
        }
    }
    
    func saveListeningProgressAsync() async {
        await internalSaveListeningProgress()
    }
    
    // swiftlint: disable function_body_length
    private func internalSaveListeningProgress() async {
        if musicplayer.playbackState != .playing {
            startDate = nil
            initiatedDate = nil
            endDate = nil
        }
        
        Logger.playback.info("Saving listening progress of \(self.currentlyPlayingHoerspiel?.title ?? "N/A")")
        do {
            if let currentlyPlayingHoerspiel {
                let persistentIdentifier = currentlyPlayingHoerspiel.persistentModelID
                
                // Signal to TelemetryDeck that a playback was saved
                TelemetryDeck.signal("Playback.saving",
                                     parameters: [
                                        "Hoerspiel": currentlyPlayingHoerspiel.title
                                     ])
                
                let tracks = try await persistentIdentifier.tracks(dataManager)
                
                // Unwrapping NowPlayingItem
                guard let nowPlayingItem = self.musicplayer.nowPlayingItem else {
                    Logger.playback.error("Nowplayingitem is nil, unable to save")
                    return
                }
                // Check if combination of condition is met to mark Hoerspiel as finished
                
                // Playhead is at the utmost start
                let isAtBeginningOfTrack = self.musicplayer.currentPlaybackTime == 0
                // Current track is the same track as the first track of the previously set queue
                let isFirstTrackOfQueue = self.startedTrackID == MusicItemID(nowPlayingItem.playbackStoreID)
                // Current track is the Intro, used for Prerelease-Checking
                let isFirstTrack = nowPlayingItem.title == tracks.first?.title
                // Releasedate is in the future, therefore must be a prerelase
                let isPreRelease = try await dataManager.read(persistentIdentifier,
                                                              keypath: \.releaseDate).isFuture()
                
                // If either condition for Prelease or finished Hoerspiel are met
                let isFinished = (isAtBeginningOfTrack && isFirstTrackOfQueue) || (isFirstTrack && isPreRelease)
                
                if isFinished {
                    // Set played property to true if Hoerspiel is finished
                    if isAtBeginningOfTrack && isFirstTrackOfQueue {
                        try await dataManager.update(persistentIdentifier,
                                                     keypath: \.played,
                                                     to: true)
                    }
                    // Remove from Up Next
                    try await dataManager.update(persistentIdentifier,
                                                 keypath: \.showInUpNext,
                                                 to: false)
                    // Set playhead to start for next playback
                    try await dataManager.update(persistentIdentifier,
                                                 keypath: \.playedUpTo,
                                                 to: 0)
                    
                    // Clearing current Hoerspiel and its cover
                    self.currentlyPlayingHoerspiel = nil
                    self.currentlyPlayingHoerspielCover = nil
                } else {
                    // Current position of the playhead in the current track
                    var currentPlayBackTime = self.musicplayer.currentPlaybackTime
                    // Unwrapping current track by title
                    guard let currentTrackIndex = tracks.firstIndex(where: {
                        $0.title == nowPlayingItem.title ?? ""
                    }) else {
                        Logger.playback.error("Couldn't get current track index from album, returning")
                        TelemetryDeck.errorOccurred(
                            id: "Playback.CurrentTrackIndexNotFound",
                            parameters: [
                                "Hoerspiel": currentlyPlayingHoerspiel.title,
                                "NowPlayingTitle": nowPlayingItem.title ?? "N/A"])
                        return
                    }
                    // Adding track duration up to current track
                    for index in 0..<currentTrackIndex {
                        currentPlayBackTime += tracks[index].duration
                    }
                    
                    // Hoerspiel is almost finished
                    if currentPlayBackTime + 60 >= currentlyPlayingHoerspiel.duration {
                        try await dataManager.update(persistentIdentifier,
                                                     keypath: \.played,
                                                     to: true)
                        try await dataManager.update(persistentIdentifier,
                                                     keypath: \.playedUpTo,
                                                     to: 0)
                        try await dataManager.update(persistentIdentifier,
                                                     keypath: \.showInUpNext,
                                                     to: false)
                    } else { // Setting property as usual
                        try await dataManager.update(
                            persistentIdentifier,
                            keypath: \.playedUpTo,
                            to: Int(currentPlayBackTime))
                    }
                }
            }
        } catch {
            Logger.playback.fullError(error,
                                      additionalParameters: ["Hoerspiel": currentlyPlayingHoerspiel?.title ?? "N/A"],
                                      sendToTelemetryDeck: true)
        }
    }
    // swiftlint: enable function_body_length
}
