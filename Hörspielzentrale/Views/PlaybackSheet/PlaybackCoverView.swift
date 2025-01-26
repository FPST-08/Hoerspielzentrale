//
//  PlaybackCoverView.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 26.01.25.
//

import MusicKit
import SwiftUI

/// A view displaying the cover for playbacks
struct PlaybackCoverView: View {
    /// The namespace for animations
    let animation: Namespace.ID
    
    /// Referencing an `Observable` class responsible for playback
    @Environment(MusicManager.self) var musicManager
    
    /// The current playback state
    @ObservedObject var state = ApplicationMusicPlayer.shared.state
    
    /// A boolean that indicates a currently running playback
    var isPlaying: Bool {
#if DEBUG
        if musicManager.currentlyPlayingHoerspiel?.upc == "DEBUG" {
            return true
        }
#endif
        return state.playbackStatus == .playing
    }
    
    var body: some View {
        Group {
            if let cover = Image(musicManager.currentlyPlayingHoerspielCover) {
                cover
                    .resizable()
                    .cornerRadius(15)
                    .shadow(radius: 10)
                    .scaleEffect(isPlaying ? 1 : 0.7)
                    .animation(.spring(duration: 0.5, bounce: 0.3), value: state.playbackStatus)
                
            } else {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .foregroundStyle(Color.gray)
                    .cornerRadius(15)
                    .shadow(radius: 10)
            }
        }
        .matchedGeometryEffect(id: "ARTWORK", in: animation, isSource: true)
        .coverFrame()
        .padding(.vertical, UIScreen.main.bounds.height < 700 ? 10 : 30)
    }
}
