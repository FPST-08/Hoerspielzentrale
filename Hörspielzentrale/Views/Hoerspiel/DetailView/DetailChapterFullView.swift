//
//  DetailChapterFullView.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 31.01.25.
//

import OSLog
import SwiftUI

/// Displaying all chapters in a list
struct DetailChapterFullView: View {
    /// The corresponding chapters
    let chapters: [Chapter]
    
    /// The corresponding hoerspiel
    let hoerspiel: SendableHoerspiel?
    
    /// The corresponding chapter source
    let source: ChapterSource?
    
    /// An Observable Class responsible for data
    @Environment(DataManagerClass.self) var dataManager
    
    /// Referencing an `Observable` class responsible for playback
    @Environment(MusicManager.self) var musicManager
    
    /// An Observable Class responsible for navigation
    @Environment(NavigationManager.self) var navigation
    
    /// The date when the current chapter will end
    var currentChapterEnding: Date? {
        guard let startDate = musicManager.startDate, let currentlyPlayingChapter else {
            return nil
        }
        return startDate.addingTimeInterval(currentlyPlayingChapter.end)
    }
    
    /// The currently playing chapter
    var currentlyPlayingChapter: Chapter? {
        guard let startDate = musicManager.startDate,
              musicManager.currentlyPlayingHoerspiel?.persistentModelID == hoerspiel?.persistentModelID else {
            return nil
        }
        
        for chapter in chapters {
            let startTime = startDate.advanced(by: chapter.start)
            let endTime = startDate.advanced(by: chapter.end)
            
            if startTime.isPast() && endTime.isFuture() {
                return chapter
            }
        }
        return nil
    }
    
    var body: some View {
        List {
            ForEach(chapters, id: \.self) { chapter in
                Button {
                    if let hoerspiel {
                        Task {
                            do {
                                try await dataManager.manager.update(hoerspiel.persistentModelID,
                                                                     keypath: \.playedUpTo,
                                                                     to: Int(chapter.start))
                                musicManager.startPlayback(for: hoerspiel.persistentModelID)
                            } catch {
                                Logger.playback.fullError(error, sendToTelemetryDeck: true)
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(chapter.name)
                        Spacer()
                        if currentlyPlayingChapter == chapter,
                           let currentChapterEnding = currentChapterEnding {
                            Text(currentChapterEnding, style: .timer)
                        } else {
                            Text(Int(chapter.start).formatTime())
                        }
                    }
                    .foregroundStyle(currentlyPlayingChapter == chapter ? .red : .primary)
                }
            }
            if let source {
                Link("Die Kapitel wurden von \(source.name) geladen", destination: source.url)
                    .foregroundStyle(Color.red)
            }
        }
        .navigationTitle("Kapitel")
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(.plain)
        .safeAreaPadding(.bottom, 60)
    }
}
