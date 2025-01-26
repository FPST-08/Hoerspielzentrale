//
//  PlaybackControlsView.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 25.01.25.
//

import OSLog
import SwiftData
import SwiftUI

/// A view that presents all playback controls
struct PlaybackControlsView: View {
    /// Referencing an `Observable` class responsible for playback
    @Environment(MusicManager.self) var musicManager
    
    /// An Observable Class responsible for data
    @Environment(DataManagerClass.self) var dataManager
    
    /// The size
    let size: CGSize
    
    /// The background Color
    let backgroundColor: Color
    
    @Environment(\.colorScheme) var colorScheme
    
    /// A computet property simplifying an indication to disable the control buttons
    var disableButtons: Bool {
        if musicManager.currentlyPlayingHoerspiel == nil {
            return true
        } else {
            return false
        }
    }
    
    var body: some View {
        ZStack {
            HStack(spacing: size.width * 0.18) {
                Spacer()
                SleepTimerMenu(backgroundColor: backgroundColor)
            }
            HStack(spacing: size.width * 0.18) {
                Button {
                    Task {
                        await musicManager.saveListeningProgressAsync()
                        guard let persistentIdentifier = musicManager.currentlyPlayingHoerspiel?.persistentModelID,
                              let playedUpTo = try? await dataManager.manager.read(
                                persistentIdentifier,
                                keypath: \.playedUpTo
                              ) else {
                            return
                        }
                        try? await dataManager.manager.update(
                            persistentIdentifier,
                            keypath: \.playedUpTo,
                            to: playedUpTo - 15)
                        musicManager.startPlayback(for: persistentIdentifier)
                    }
                } label: {
                    Image(systemName: "gobackward.15")
                        .font(.title)
                    
                }
                .disabled(disableButtons)
                .foregroundStyle(disableButtons ? Color.gray : Color.white)
                
                PlayPauseButtonView()
                
                Button {
                    Task {
                        await musicManager.saveListeningProgressAsync()
                        guard let persistentIdentifier = musicManager.currentlyPlayingHoerspiel?.persistentModelID,
                              let playedUpTo = try? await dataManager.manager.read(
                                persistentIdentifier,
                                keypath: \.playedUpTo) else {
                            return
                        }
                        try? await dataManager.manager.update(
                            persistentIdentifier,
                            keypath: \.playedUpTo,
                            to: playedUpTo + 15)
                        musicManager.startPlayback(for: persistentIdentifier)
                    }
                } label: {
                    Image(systemName: "goforward.15")
                        .font(.title)
                    
                }
                .disabled(disableButtons)
                .foregroundStyle(disableButtons ? Color.gray : Color.white)
            }
            .frame(maxHeight: .infinity)
        }
        .frame(alignment: .bottom)
    }
}
