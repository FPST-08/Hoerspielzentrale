//
//  SleepTimerMenu.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 26.01.25.
//

import SwiftUI

/// A view that presents the sleep timer menu
struct SleepTimerMenu: View {
    
    /// Referencing an `Observable` class responsible for playback
    @Environment(MusicManager.self) var musicManager
    
    /// Options in minutes to set the sleep timer to
    let sleeptimerDurations = [0, 5, 10, 15, 30, 45, 60]
    
    /// The background color
    let backgroundColor: Color
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Menu {
            Picker("Schlaftimer", selection: Binding(
                get: {
                    return musicManager.sleepTimerDuration ?? 0
                },
                set: { value in
                    if value != 0 {
                        musicManager.startSleepTimer(for: value)
                    } else {
                        musicManager.stopSleepTimer()
                    }
                }
            )) {
                ForEach(sleeptimerDurations, id: \.self) { duration in
                    if duration == 60 {
                        Text("1 Stunde")
                            .tag(60)
                    } else if duration == 0 {
                        Text("Aus")
                            .tag(0)
                    } else {
                        Text("\(duration) min")
                            .tag(duration)
                    }
                }
            }
        } label: {
            Image(systemName: "moon.zzz\(musicManager.sleepTimerDuration == nil ? "" : ".fill")")
                .foregroundStyle(backgroundColor.playbackControlColor(colorScheme: colorScheme))
                .font(.headline)
        }
    }
}
