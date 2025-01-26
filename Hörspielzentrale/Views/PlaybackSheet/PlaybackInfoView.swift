//
//  PlaybackInfoView.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 26.01.25.
//

import SwiftData
import SwiftUI

/// A view used to display the title and series of the hoerspiel
struct PlaybackInfoView: View {
    /// Referencing an `Observable` class responsible for playback
    @Environment(MusicManager.self) var musicManager
    
    /// The background color
    let backgroundColor: Color
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(alignment: .center, spacing: 15) {
            VStack(alignment: .leading, spacing: 4) {
                Text(musicManager.currentlyPlayingHoerspiel?.title ?? "Keine Wiedergabe")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(backgroundColor.playbackControlColor(colorScheme: colorScheme))
                Text(musicManager.currentlyPlayingHoerspiel?.artist ?? "")
                    .foregroundStyle(
                        backgroundColor
                            .playbackControlColor(colorScheme: colorScheme)
                            .secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if let persistentIdentifier = musicManager.currentlyPlayingHoerspiel?.persistentModelID {
                HoerspielMenuView(persistentIdentifier: persistentIdentifier) {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(backgroundColor.playbackControlColor(colorScheme: colorScheme))
                        .padding(12)
                        .background(.ultraThinMaterial, in: Circle())
                }
            }
        }
    }
}
