//
//  RegularPlaybackState.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 31.01.25.
//

import MusicKit
import OSLog
import SwiftUI

extension View {
    /// Adds a modifier for this view that fires an action when
    /// the playback was changed manually
    /// - Parameter block: A closure to run when the playback was changed manually
    /// - Returns: A view that fires an action when the playback was changed maually.
    func onScrubbing(
        _ block: (@escaping () -> Void)
    ) -> some View {
        modifier(ManualPlaybackChangeModifier(block: block))
    }
}

/// A Modifier to detect manual changes to the playback
struct ManualPlaybackChangeModifier: ViewModifier {
    /// The block to run after detecting a change
    let block: ( () -> Void)
    
    /// The old value of the playbacktime
    @State private var oldValue: Double?
    
    /// The old index of the nowPlayingItem in the queue
    @State private var oldIndex: Int?
    
    /// The duration of the nowPlayingItem
    @State private var oldDuration: TimeInterval?
    
    /// Referencing an `Observable` class responsible for playback
    @Environment(MusicManager.self) var musicmanager
    
    /// The current playback state
    @ObservedObject var state = ApplicationMusicPlayer.shared.state
    
    func body(content: Content) -> some View {
        content
            .run(everyTimeInterval: 1) {
                if musicmanager.lastProgrammaticChange?.advanced(by: 2).isFuture() == true {
                    return
                }
                let newValue = musicmanager.musicplayer.currentPlaybackTime
                let newIndex = musicmanager.musicplayer.indexOfNowPlayingItem
                if let oldValue, let oldIndex, let oldDuration {
                    if newIndex < oldIndex {
                        Logger.playback.info("Detected skipping back a track")
                        block()
                    } else if (oldValue + 1.1) >= oldDuration && oldIndex + 1 == newIndex {
                        Logger.playback.info("Detected ending of a track")
                        block()
                    } else if (oldValue + 1.1) < oldDuration && oldIndex < newIndex {
                        Logger.playback.info("Detected skipping forward")
                        block()
                    } else if (oldValue + 1.1) <= newValue || oldValue > newValue {
                        Logger.playback.info("Detected scrubbing")
                        block()
                    }
                }
                oldValue = newValue
                oldIndex = musicmanager.musicplayer.indexOfNowPlayingItem
                oldDuration = musicmanager.musicplayer.nowPlayingItem?.playbackDuration ?? 0
            }
            .onChange(of: state.playbackStatus) { _, _ in
                oldValue = nil
                oldDuration = nil
                oldIndex = musicmanager.musicplayer.indexOfNowPlayingItem
            }
            .onChange(of: musicmanager.lastProgrammaticChange) { _, _ in
                oldValue = nil
                oldDuration = nil
                oldIndex = musicmanager.musicplayer.indexOfNowPlayingItem

            }
    }
}
