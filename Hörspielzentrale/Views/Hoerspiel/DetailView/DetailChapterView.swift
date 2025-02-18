//
//  DetailChapterView.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 31.01.25.
//

@preconcurrency import MusicKit
import OSLog
import SwiftUI

/// Displaying the 5 most important chapters and linking to a full list
struct DetailChapterView: View {
    // MARK: - Properties
    /// The corresponding hoerspiel
    let hoerspiel: SendableHoerspiel?
    
    /// The corresponding album
    let album: Album?
    
    /// The chapters of the ``Hoerspiel``
    @State private var chapters = [Chapter]()
    
    /// An Observable Class responsible for data
    @Environment(DataManagerClass.self) var dataManager
    
    /// Referencing an `Observable` class responsible for playback
    @Environment(MusicManager.self) var musicManager
    
    /// An Observable Class responsible for navigation
    @Environment(NavigationManager.self) var navigation
    
    /// The source of the chapters
    @State private var source: ChapterSource?
    
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
    
    /// The date when the current chapter will end
    var currentChapterEnding: Date? {
        guard let startDate = musicManager.startDate, let currentlyPlayingChapter else {
            return nil
        }
        return startDate.addingTimeInterval(currentlyPlayingChapter.end)
    }
    
    /// The chapters that should be displayed
    var displayChapters: [Chapter] {
        let shownChapterCount = UIDevice.isIpad ? 10 : 5
        guard let currentlyPlayingChapter else {
            return Array(chapters.prefix(shownChapterCount))
        }
        let chapterIndex = chapters.firstIndex(of: currentlyPlayingChapter) ?? chapters.startIndex
        
        if chapterIndex <= 2 {
            return Array(chapters.prefix(shownChapterCount))
        } else {
            return Array(chapters[chapterIndex - 2..<chapterIndex +
                                  min(shownChapterCount - 2, chapters.endIndex - chapterIndex )])
        }
    }
    
    // MARK: - View
    var body: some View {
        VStack(alignment: .leading) {
            if chapters.isEmpty {
                SectionHeader(title: "Kapitel")
                Text("Keine Kapitel verfügbar")
                    .padding(.horizontal)
            } else {
                SectionHeaderLink(title: "Kapitel") {
                    DetailChapterFullView(chapters: chapters, hoerspiel: hoerspiel, source: source)
                }
                ForEach(displayChapters, id: \.self) { chapter in
                    VStack {
                        Button {
                            if let hoerspiel {
                                Task {
                                    do {
                                        try await dataManager.manager.update(hoerspiel.persistentModelID,
                                                                             keypath: \.playedUpTo,
                                                                             to: Int(chapter.start))
                                        musicManager.startPlayback(for: hoerspiel.persistentModelID)
                                        requestReviewIfAppropriate()
                                    } catch {
                                        Logger.playback.fullError(error, sendToTelemetryDeck: true)
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Text(chapter.name)
                                    .lineLimit(1)
                                Spacer()
                                if currentlyPlayingChapter == chapter,
                                   let currentChapterEnding = currentChapterEnding {
                                    Text(currentChapterEnding, style: .timer)
                                } else {
                                    Text(Int(chapter.start).formatTime())
                                }
                                
                            }
                            .foregroundStyle(currentlyPlayingChapter == chapter
                                             ? Color.accentColor
                                             : Color.primary)
                            .lineLimit(1)
                        }
                        Divider()
                    }
                }
                .padding(.vertical, 2)
                .padding(.horizontal)
                Text("\(chapters.count) Kapitel verfügbar")
                    .padding(.horizontal)
            }
        }
        .task { // MARK: - Task
#if DEBUG
            if hoerspiel?.upc == "DEBUG" {
                chapters = [
                    Chapter(name: "Das Echo der Finsternis", start: 0, end: 600), // 10 Minuten
                    Chapter(name: "Die Spuren im Staub", start: 600, end: 1080), // 8 Minuten
                    Chapter(name: "Das zersprungene Glas", start: 1080, end: 1800), // 12 Minuten
                    Chapter(name: "Der nächtliche Besucher", start: 1800, end: 2400), // 10 Minuten
                    Chapter(name: "Die Kammer wird geöffnet", start: 2400, end: 3180), // 13 Minuten
                    Chapter(name: "Der Schatten erwacht", start: 3180, end: 3900), // 12 Minuten
                    Chapter(name: "Das Opfer der Wahrheit", start: 3900, end: 4500)  // 10 Minuten
                ]
            }
#endif
            do {
                if chapters.isEmpty {
                    var metadata: MetaData?
                    if let hoerspiel {
                        metadata = try? await hoerspiel.loadMetaData()
                    } else if let album {
                        metadata = try? await album.loadMetaData()
                    }
                    let tracks = try await dataManager.manager.fetchTracks(hoerspiel, album: album)
                    if let metadata {
                        var offsetDuration: TimeInterval = 0.0
                        if tracks.first?.title.contains("Inhaltsangabe") == true {
                            let duration = tracks.first?.duration ?? 0
                            offsetDuration += duration
                        }
                        if hoerspiel?.hasDisclaimer == true || album?.hasDisclaimer == true {
                            offsetDuration += 42
                        }
                        chapters = metadata.kapitel?.compactMap {
                            let start = (TimeInterval($0.start / 1000) + offsetDuration)
                            let end = (TimeInterval($0.end / 1000) + offsetDuration)
                            return Chapter(name: $0.titel,
                                           start: start,
                                           end: end)
                        } ?? []
                        
                        if offsetDuration != 0 {
                            chapters.insert(Chapter(name: "Start", start: 0, end: offsetDuration), at: 0)
                        }
                        guard let sourceURL = URL(string: "https://dreimetadaten.de") else {
                            assertionFailure()
                            return
                        }
                        source = ChapterSource(name: "dreimetadaten.de", url: sourceURL)
                    }
                    if chapters.isEmpty {
                        var passedDuration: TimeInterval = 0.0
                        chapters = tracks.map {
                            let chapter = Chapter(name: $0.title,
                                                  start: passedDuration,
                                                  end: passedDuration + $0.duration)
                            passedDuration += $0.duration
                            return chapter
                        }
                        guard let sourceURL = URL(string: "music://music.apple.com") else {
                            assertionFailure()
                            return
                        }
                        source = ChapterSource(name: "Apple Music", url: sourceURL)
                    }
                    
                }
            } catch {
                Logger.metadata.fullError(error, sendToTelemetryDeck: true)
            }
        }
    }
}

/// The chapter source for fetched Chapters
struct ChapterSource {
    
    /// The name
    var name: String
    
    /// The url to link to
    var url: URL
}
