//
//  PlayPreView.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 05.06.24.
//

import MusicKit
import OSLog
import SwiftData
import SwiftUI

/// A tiny view used to initiate playback
struct PlayPreView: View {
    // MARK: - Properties
    /// The overall background of the view
    let backgroundColor: Color
    
    /// The primary color of the view used in symbol and text
    let textColor: Color
    
    /// A `Query` used to update the view
    @Query private var hoerspiele: [Hoerspiel]
    
    /// Referencing an `Observable` class responsible for playback
    @Environment(MusicManager.self) var musicManager
    
    /// The current playback state
    @ObservedObject var state = ApplicationMusicPlayer.shared.state
    
    /// The persistentIdentifier of the ``Hoerspiel`` represented in this ``PlayPreView``
    let persistentIdentifier: PersistentIdentifier
    
    /// The time shown in the button
    @State private var timeString = String()

    /// The progress of the current value between 0 and 1
    @State private var progressValue = Double()
    
    var body: some View {
        if let hoerspiel = hoerspiele.first {
            Button(role: .none) {
                Task {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    await musicManager.togglePlayback(for: persistentIdentifier)
                }
            } label: {
                HStack {
                    Group {
                        if state.playbackStatus == .playing &&
                            musicManager.currentlyPlayingHoerspiel?.persistentModelID == hoerspiel.persistentModelID {
                            Image(systemName: "pause.fill")
                                .run(everyTimeInterval: 15) {
                                    updateView()
                                }
                        } else  if hoerspiel.played == true && hoerspiel.playedUpTo == 0 {
                            Image(systemName: "arrow.circlepath")
                        } else {
                            Image(systemName: "play.fill")
                        }
                    }
                    .frame(width: 18, height: 18)
                    .font(.callout)
                    
                    if hoerspiel.releaseDate.isFuture() {
                        Text("Vorschau")
                            .font(.body)
                    } else {
                        if hoerspiel.playedUpTo != 0 {
                            ProgressCapsuleView(progress: progressValue, color: textColor)
                        }
                        
                        Text(timeString)
                            .lineLimit(1)
                            .font(.body)
                        
                    }
                    
                }
                .foregroundStyle(textColor)
                .fontWeight(.medium)
                .padding(.horizontal, 6)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .foregroundStyle(backgroundColor)
                )
            }
            .buttonStyle(PlainButtonStyle())
            .onAppear(perform: updateView)
            .dynamicTypeSize(DynamicTypeSize.xSmall...DynamicTypeSize.accessibility1)
        }
    }
    
    // MARK: - Functions
    /// Updates the properties of the view to reflect current state
    func updateView() {
        guard let hoerspiel = hoerspiele.first else {
            return
        }
        
        var difference: Int = 0
        if let startDate = musicManager.startDate,
            let endDate = musicManager.endDate,
           musicManager.currentlyPlayingHoerspiel?.persistentModelID == persistentIdentifier {
            progressValue = Double(Int(Date.now - startDate)) / Double(hoerspiel.duration)
            difference = Int(endDate - Date())
        } else {
            progressValue = Double(hoerspiel.playedUpTo) / hoerspiel.duration
            difference = Int(hoerspiel.duration) - hoerspiel.playedUpTo
        }
        if difference >= 3600 {
            timeString = """
\(difference / 3600)h \((difference % 3600) / 60 == 0 ? "" : "\((difference % 3600) / 60) min")
"""
        } else if difference >= 60 {
            timeString = "\(difference / 60) min"
        } else {
            timeString = "1 min"
        }
        
    }
    
    init(backgroundColor: Color, textColor: Color, persistentIdentifier: PersistentIdentifier) {
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        _hoerspiele = Query(filter: #Predicate<Hoerspiel> { hoerspiel in
            hoerspiel.persistentModelID == persistentIdentifier
        })
        self.persistentIdentifier = persistentIdentifier
    }
}
