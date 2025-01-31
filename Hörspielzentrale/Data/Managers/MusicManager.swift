//
//  musicplayer.swift
//  diedreifragezeichenplayer
//
//  Created by Philipp Steiner on 03.04.24.
//

import Defaults
@preconcurrency import MediaPlayer
import MusicKit
import OSLog
import SwiftData
import SwiftUI
import TelemetryDeck
import WidgetKit

// swiftlint:disable file_length

/// A class resposible for all playback related actions
@MainActor
@Observable final class MusicManager {
    // swiftlint:disable:previous type_body_length
    init(dataManager: DataManager,
         navigation: NavigationManager,
         imageCache: ImageCache,
         networkHelper: NetworkHelper
    ) {
        self.dataManager = dataManager
        self.navigation = navigation
        self.imageCache = imageCache
        self.networkHelper = networkHelper
    }
    
    // MARK: - Proerties
    let dataManager: DataManager
    
    let navigation: NavigationManager
    
    let imageCache: ImageCache
    
    let networkHelper: NetworkHelper
    
    let musicplayer = MPMusicPlayerController.applicationMusicPlayer
    
    var startDate: Date?
    var initiatedDate: Date?
    var endDate: Date?
    var remainingTime: Double = 0
    
    /// The currently playing ``SendableHoerspiel``
    var currentlyPlayingHoerspiel: SendableHoerspiel?
    
    /// The cover of the currently playing ``SendableHoerspiel``
    var currentlyPlayingHoerspielCover: UIImage?
    
    var playbackDuration = 0.0
    
    var volume: Double = 0
    
    var timer = Timer.scheduledTimer(withTimeInterval: 0, repeats: false) { _ in }
    private(set) var sleeptimerDate: Date? {
        didSet {
            Logger.playback.info("Changed sleeptimerdate to \(self.sleeptimerDate?.formatted() ?? "nil")")
        }
    }
    private(set) var sleepTimerDuration: Int? {
        didSet {
            Logger.playback.info("Changed sleeptimerduration to \(self.sleepTimerDuration?.formatted() ?? "nil")")
        }
    }
    
    var showSleeptimer: Bool {
        sleeptimerDate != nil
    }
    
    var startedTrackID: MusicItemID?
    
    /// The task starting a playback
    var currentPlaybackTask: Task<Void, Never>?
    
    // MARK: Functions
    
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
    
    /// Starts a playback
    /// - Parameter persistentIdentifier: The `persistentIdentifier` of the ``Hoerspiel`` to play
    func startPlayback(for persistentIdentifier: PersistentIdentifier) {
        currentPlaybackTask?.cancel()
        currentPlaybackTask = Task {
            await initiatePlayback(for: persistentIdentifier)
        }
    }
    
    private func initiatePlayback(for persistentIdentifier: PersistentIdentifier) async {
        // swiftlint:disable:previous function_body_length
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
            
            let center = UNUserNotificationCenter.current()
            center.removeDeliveredNotifications(withIdentifiers: [hoerspiel.upc, "PR\(hoerspiel.upc)"])
            
            if !hoerspiel.showInUpNext {
                try await dataManager.update(persistentIdentifier, keypath: \.showInUpNext, to: true)
            }
            try? await dataManager.update(persistentIdentifier, keypath: \.lastPlayed, to: Date.now)
            try? await dataManager.update(persistentIdentifier, keypath: \.addedToUpNext, to: Date.now)
            
            let startPoint = try await persistentIdentifier.calculateStartingPoint(dataManager)
            musicplayer.stop()
            musicplayer.setQueue(with: startPoint.tracks.map { $0.musicItemID })
            try await musicplayer.prepareToPlay()
            musicplayer.currentPlaybackTime = startPoint.timeInterval
            musicplayer.play()
            currentlyPlayingHoerspiel = hoerspiel
            currentlyPlayingHoerspielCover = await imageCache.uiimage(for: hoerspiel, size: .fullResolution)
            startDate = startPoint.startDate
            initiatedDate = Date.now
            endDate = startPoint.endDate
            if let musicItemID = startPoint.tracks.first?.musicItemID {
                startedTrackID = MusicItemID(musicItemID)
            }
            Defaults[.timesPlaybackStarted] += 1
            let series = try? await dataManager.series(for: hoerspiel)
            TelemetryDeck.signal("Playback.starting", parameters: [
                "Hoerspiel": hoerspiel.title,
                "SeriesName": series?.name ?? "N/A",
                "SeriesID": series?.musicItemID ?? "N/A"
            ])
        } catch {
            let title = try? await dataManager.read(persistentIdentifier, keypath: \.title)
            switch networkHelper.connectionStatus {
            case .working:
                navigation.presentAlert(title: "Es ist ein Fehler aufgetreten",
                                        description: "Die Wiedergabe konnte nicht gestartet werden")
            case .notWorking:
                navigation.presentAlert(title: "Keine Verbindung zum Internet",
                                        description: """
Stelle eine Verbindung über Wifi oder Mobilfunk her, um dieses Hörspiel abspielen zu können
""")
            }
            
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
    /// - Parameter seriesNames: The series that are applicable
    func playRandom(seriesNames: [String]) async {
        await internalSaveListeningProgress()
        do {
            let id = try? await dataManager.fetchRandom {
                var descriptor = FetchDescriptor<Hoerspiel>()
                descriptor = FetchDescriptor(predicate: #Predicate<Hoerspiel> { hoerspiel in
                    if hoerspiel.playedUpTo != 0 || hoerspiel.played {
                        return false
                    } else if seriesNames.isEmpty {
                        return true
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
                        if seriesNames.isEmpty {
                            return true
                        } else {
                            return seriesNames.contains(hoerspiel.artist)
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
    
    /// Starts a sleeptimer that stops and saves the playback after the specified time
    /// - Parameter duration: The duration in minutes
    func startSleepTimer(for duration: Int) {
        TelemetryDeck.signal("Playback.startedSleepTimer", parameters: ["Duration": duration.formatted()])
        timer.invalidate()
        let timeInterval = TimeInterval(duration * 60)
        sleeptimerDate = Date().advanced(by: timeInterval)
        sleepTimerDuration = duration
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
    
    /// Stops a currently running sleeptimer
    ///
    /// To start a new timer, this does not need to be called before
    func stopSleepTimer() {
        sleeptimerDate = nil
        sleepTimerDuration = nil
        timer.invalidate()
    }
    
    /// Toggles the playback when appropriate or initiates a new playback
    func togglePlayback(for hoerspiel: PersistentIdentifier) async {
        if hoerspiel == currentlyPlayingHoerspiel?.persistentModelID, musicplayer.playbackState == .playing {
            musicplayer.pause()
            if let endDate {
                remainingTime = endDate - Date()
            }
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
            if let endDate {
                remainingTime = endDate - Date()
            }
        } else if musicplayer.playbackState == .paused || musicplayer.playbackState == .interrupted {
            musicplayer.play()
        } else {
            Task {
                let hoerspiel = try await dataManager.fetchSuggestedHoerspielForPlaybck()
                await initiatePlayback(for: hoerspiel.persistentModelID)
            }
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
