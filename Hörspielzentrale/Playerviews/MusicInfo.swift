//
//  MusicInfo.swift
//  diedreifragezeichenplayer
//
//  Created by Philipp Steiner on 18.04.24.
//

import MediaPlayer
import MusicKit
import OSLog
import SwiftData
import SwiftUI

/// A small bar suitable for displaying at the bottom screen
struct MusicInfo: View {
    // MARK: - Properties
    /// A bool indicating a running animation
    @Binding var animateContent: Bool
    
    /// The cover of the currently playing ``Hoerspiel``
    let artwork: Image?
    
    /// The animation namespace of the animation
    var animation: Namespace.ID
    /// The current playback state
    @ObservedObject var state = ApplicationMusicPlayer.shared.state
    
    var persistentIdentifier: PersistentIdentifier? {
        musicManager.currentlyPlayingHoerspiel?.persistentModelID
    }
    /// Referencing an `Observable` class responsible for playback
    @Environment(MusicManager.self) var musicManager
    
    /// An Observable Class responsible for data
    @Environment(DataManagerClass.self) var dataManager
    
    /// An Observable Class responsible for navigation
    @Environment(NavigationManager.self) var navigation
    
    var isPlaying: Bool {
#if DEBUG
        if musicManager.currentlyPlayingHoerspiel?.upc == "DEBUG" {
            return true
        }
#endif
        return state.playbackStatus == .playing
    }
    
    // MARK: - View
    var body: some View {
        HStack(alignment: .center) {
            ZStack {
                if let artwork = artwork {
                    artwork
                        .resizable()
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(
                            cornerRadius: navigation.presentMediaSheet ? 15 : 5,
                            style: .continuous))
                } else {
                    RoundedRectangle(cornerRadius: !animateContent ? 15 : 5, style: .continuous)
                        .foregroundStyle(Color.gray)
                }
            }
            .matchedGeometryEffect(id: "ARTWORK", in: animation)
            .frame(width: 45, height: 45)
            Text(musicManager.currentlyPlayingHoerspiel?.title ?? "Keine Wiedergabe")
                .fontWeight(.semibold)
                .lineLimit(1)
                .padding(.horizontal, 15)
            Spacer(minLength: 0)
            
            Button {
                if musicManager.currentlyPlayingHoerspiel != nil {
                    musicManager.togglePlayback()
                } else {
                    Task {
                        do {
                            let hoerspiel = try await dataManager.manager.fetchSuggestedHoerspielForPlaybck()
                            await musicManager.startPlayback(for: hoerspiel.persistentModelID)
                        } catch {
                            Logger.data.fullError(error, sendToTelemetryDeck: true)
                        }
                    }
                }
            } label: {
                Image(systemName: "\(isPlaying ? "pause" : "play").fill")
                    .font(.title2)
            }
//            .disabled(state.playbackStatus != .paused && state.playbackStatus != .playing)
            Button {
                Task {
                    await musicManager.saveListeningProgressAsync()
                    guard let persistentIdentifier = persistentIdentifier,
                          let playedUpTo = try? await dataManager.manager.read(
                            persistentIdentifier,
                            keypath: \.playedUpTo
                          ) else {
                        return
                    }
                    try? await dataManager.manager.update(
                        persistentIdentifier,
                        keypath: \.playedUpTo,
                        to: playedUpTo + 15)
                    await musicManager.startPlayback(for: persistentIdentifier)
                }
            } label: {
                Image(systemName: "goforward.15")
                    .font(.title2)
            }
            .disabled(state.playbackStatus != .paused && state.playbackStatus != .playing)
            .foregroundStyle(state.playbackStatus != .paused && state.playbackStatus != .playing
                             ? Color.gray
                             : Color.white)
            .padding(.leading, 25)
        }
        
        .foregroundStyle(.primary)
        .padding(.horizontal)
        .padding(.bottom, 5)
        .frame(height: 70)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.30)) {
                navigation.presentMediaSheet = true
            }
        }
        
    }
}
