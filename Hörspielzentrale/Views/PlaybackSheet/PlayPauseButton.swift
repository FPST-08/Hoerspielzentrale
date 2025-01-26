//
//  PlayPauseButton.swift
//  diedreifragezeichenplayer
//
//  Created by Philipp Steiner on 26.05.24.
//

import MediaPlayer
import MusicKit
import SwiftUI

/// A View used as the button in ``PlaybackSheet``
struct PlayPauseButtonView: View {
    /// The current playback state
    @ObservedObject var state = ApplicationMusicPlayer.shared.state
    
    /// Referencing an `Observable` class responsible for playback
    @Environment(MusicManager.self) var musicManager
    
    /// A computed property simplifiying the access to the playback state
    var isPlaying: Bool {
        #if DEBUG
        if musicManager.currentlyPlayingHoerspiel?.upc == "DEBUG" {
            return true
        }
        #endif
        return state.playbackStatus == .playing
    }
    
    /// The size of the overall area used to calculate the size of the button
    let size = UIScreen.main.bounds.size
    
    var body: some View {
        Button {
            musicManager.togglePlayback()
        } label: {
            ZStack {
                Image(systemName: "pause.fill")
                    .font(size.height < 300 ? .largeTitle : .system(size: 50))
                    .scaleEffect(isPlaying ? 1 : 0)
                    .opacity(isPlaying ? 1 : 0)
                    .animation(.interpolatingSpring(stiffness: 170, damping: 15), value: isPlaying)
                
                Image(systemName: "play.fill")
                    .font(size.height < 300 ? .largeTitle : .system(size: 50))
                    .scaleEffect(isPlaying ? 0 : 1)
                    .opacity(isPlaying ? 0 : 1)
                    .animation(.interpolatingSpring(stiffness: 170, damping: 15), value: isPlaying)
            }
            .foregroundStyle(Color.white)
        }
    }
}
