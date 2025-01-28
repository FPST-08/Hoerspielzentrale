//
//  HoerspielMusicDetailsView.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 03.12.24.
//

import MusicKit
import OSLog
import SwiftData
import SwiftUI

/// A view displaying Details about a ``Hoerspiel`` in the ``HoerspielDetailView``
struct HoerspielMusicDetailsView: View { // swiftlint:disable:this type_body_length
    // MARK: - Properties
    
    /// The fetched MetaData if available
    @State private var metadata: MetaData?
    
    /// The chapters of the ``Hoerspiel``
    @State private var chapters = [Chapter]()
    
    /// The ``SendableHoerspiel``
    @State var hoerspiel: SendableHoerspiel
    
    /// An Observable Class responsible for data
    @Environment(DataManagerClass.self) var dataManager
    
    /// Referencing an `Observable` class responsible for playback
    @Environment(MusicManager.self) var musicManager
    
    /// The series of the ``SendableHoerspiel``
    @State private var series: SendableSeries?
    
    /// The source of the ``Chapter``
    @State private var source: ChapterSource?
    
    /// The current viewstate
    @State private var state = ViewState.loading
    
    /// The surrounding hoerspiels of this hoerspiel
    @State private var surroundingHoerspiels = [SendableHoerspiel]()
    
    /// The currently playing chapter
    var currentlyPlayingChapter: Chapter? {
        guard let startDate = musicManager.startDate,
              musicManager.currentlyPlayingHoerspiel?.persistentModelID == hoerspiel.persistentModelID else {
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
        var shownChapterCount = UIDevice.isIpad ? 10 : 5
        guard let currentlyPlayingChapter else {
            return Array(chapters.prefix(shownChapterCount))
        }
        let chapterIndex = chapters.firstIndex(of: currentlyPlayingChapter) ?? chapters.startIndex
        
        if chapterIndex <= 2 {
            return Array(chapters.prefix(shownChapterCount))
        } else {
            return Array(chapters[chapterIndex - 2..<chapterIndex + min(shownChapterCount - 2, chapters.endIndex - chapterIndex )])
        }
    }
    
    // MARK: - View
    var body: some View {
        Group {
            switch state {
            case .failed(let error):
                ContentUnavailableView("Keine Daten verfügbar",
                                       systemImage: "exclamationmark.triangle",
                                       description: Text(error.localizedDescription))
            case .loading:
                ProgressView {
                    Text("Daten werden geladen")
                }
            case .finished:
                if UIDevice.isIpad {
                    VStack {
                        HStack(alignment: .top) {
                            chapterView
                                .frame(maxWidth: .infinity)
                            VStack(alignment: .leading) {
                                descriptionView
                                    .frame(maxWidth: .infinity)
                                infoView
                                .frame(maxWidth: .infinity)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        surroundingHoerspielView
                        
                        if let sprechrollen = metadata?.sprechrollen, !sprechrollen.isEmpty {
                            SectionHeader(title: "Sprecher")
                            SpeakerView(rollen: sprechrollen)
                        }
                        
                        if source == nil && hoerspiel.artist != "Die drei ???" && hoerspiel.artist != "Die drei ??? Kids" {
                            GroupBox("Mangelnde Daten") {
                                Text("""
    Für dieses Hörspiel sind nur Daten über Apple Music bekannt. 
    Wenn du eine bessere Datenquelle für dieses Hörspiel kennst, schreibe mir gerne über hoerspielzentrale@icloud.com
    """)
                            }
                            .padding(.horizontal)
                        }
                        Link(destination: URL(string: "music://music.apple.com/de/album/\(hoerspiel.albumID)")!) {
                            Label("In Apple Music öffnen", systemImage: "arrowshape.turn.up.right")
                                .padding([.horizontal, .bottom])
                        }
                        
                    }
                    
                } else {
                    VStack(alignment: .leading) {
                        chapterView
                        descriptionView
                        infoView
                        surroundingHoerspielView
                        if let sprechrollen = metadata?.sprechrollen, !sprechrollen.isEmpty {
                            SectionHeader(title: "Sprecher")
                            SpeakerView(rollen: sprechrollen)
                        }
                        
                        if source == nil && hoerspiel.artist != "Die drei ???" && hoerspiel.artist != "Die drei ??? Kids" {
                            GroupBox("Mangelnde Daten") {
                                Text("""
                            Für dieses Hörspiel sind nur Daten über Apple Music bekannt. 
                            Wenn du eine bessere Datenquelle für dieses Hörspiel kennst, schreibe mir gerne über hoerspielzentrale@icloud.com
                            """)
                            }
                            .padding(.horizontal)
                        }
                        Link(destination: URL(string: "music://music.apple.com/de/album/\(hoerspiel.albumID)")!) {
                            Label("In Apple Music öffnen", systemImage: "arrowshape.turn.up.right")
                                .padding([.horizontal, .bottom])
                        }
                    }
                }
            }
        }
        .task {
            if series == nil {
                series = try? await dataManager.manager.series(for: hoerspiel)
            }
#if DEBUG
            if hoerspiel.upc == "DEBUG" {
                chapters = [
                    Chapter(name: "Das Echo der Finsternis", start: 0, end: 600), // 10 Minuten
                    Chapter(name: "Die Spuren im Staub", start: 600, end: 1080), // 8 Minuten
                    Chapter(name: "Das zersprungene Glas", start: 1080, end: 1800), // 12 Minuten
                    Chapter(name: "Der nächtliche Besucher", start: 1800, end: 2400), // 10 Minuten
                    Chapter(name: "Die Kammer wird geöffnet", start: 2400, end: 3180), // 13 Minuten
                    Chapter(name: "Der Schatten erwacht", start: 3180, end: 3900), // 12 Minuten
                    Chapter(name: "Das Opfer der Wahrheit", start: 3900, end: 4500)  // 10 Minuten
                ]
                let sprechrollen: [Sprechrolle] = [
                    Sprechrolle(rolle: "Die Schriftstellerin", sprecher: "Elisabeth Falkner"),
                    Sprechrolle(rolle: "Der Detektiv", sprecher: "Victor Langfeld"),
                    Sprechrolle(rolle: "Der Wissenschaftler", sprecher: "Professor Albrecht Stein"),
                    Sprechrolle(rolle: "Die Hausherrin", sprecher: "Marlene Gruber"),
                    Sprechrolle(rolle: "Der Journalist", sprecher: "Jakob Lenner"),
                    Sprechrolle(rolle: "Die Musikerin", sprecher: "Sophie Winter"),
                    Sprechrolle(rolle: "Der Historiker", sprecher: "Konrad Weiß"),
                    Sprechrolle(rolle: "Die Spiritistin", sprecher: "Helene Sturm"),
                    Sprechrolle(rolle: "Der Erbe", sprecher: "Lukas von Hagen"),
                    Sprechrolle(rolle: "Die dunkle Präsenz", sprecher: "Das Phantom")
                ]
                let beschreibung = """
In der alten Villa einer illustren Gesellschaft verbirgt eine verschlossene Kammer ein dunkles Geheimnis. \ 
Mysteriöse Ereignisse, Misstrauen und ein unheimliches Phantom treiben die Gäste an ihre Grenzen.
"""
                metadata = MetaData(beschreibung: beschreibung,
                                    sprechrollen: sprechrollen)
            }
            state = .finished
#endif
            if chapters.isEmpty {
                let album = try? await hoerspiel.persistentModelID.album(dataManager.manager)?.with(.tracks)
                do {
                    
                    metadata = try? await hoerspiel.loadMetaData()
                    
                    if let metadata {
                        var offsetDuration = 0.0
                        if album?.tracks?.first?.title.contains("Inhaltsangabe") == true {
                            let inhaltsangabe = album?.tracks?.first
                            offsetDuration = inhaltsangabe?.duration ?? 0.0
                            Logger.metadata.info("\(hoerspiel.title) has an Intro")
                        }
                        
                        if let kapitel = metadata.kapitel {
                            if hoerspiel.hasDisclaimer {
                                offsetDuration += 42
                            }
                            for track in kapitel {
                                let start = offsetDuration + TimeInterval(track.start / 1000)
                                let end = offsetDuration + TimeInterval(track.end / 1000)
                                
                                chapters.append(Chapter(name: track.titel,
                                                        start: start,
                                                        end: end))
                            }
                            if offsetDuration > 0.0 {
                                let chapter = Chapter(name: "Start",
                                                      start: 0.0,
                                                      end: offsetDuration)
                                chapters.insert(chapter, at: 0)
                            }
                        }
                    }
                    
                    if chapters.isEmpty {
                        try await fetchTracks()
                    } else {
                        source = ChapterSource(name: "Dreimetadaten", url: URL(string: "http://dreimetadaten.de")!)
                    }
                    
                    let releaseDate = hoerspiel.releaseDate
                    let artist = hoerspiel.artist
                    
                    let next = try await dataManager.manager.fetch({
                        var fetchDescriptor = FetchDescriptor<Hoerspiel>(predicate: #Predicate<Hoerspiel> { hoerspiel in
                            hoerspiel.releaseDate < releaseDate && hoerspiel.artist == artist
                        }, sortBy: [SortDescriptor(\Hoerspiel.releaseDate, order: .reverse)])
                        fetchDescriptor.fetchLimit = 2
                        return fetchDescriptor
                    })
                    surroundingHoerspiels.append(contentsOf: next)
                    surroundingHoerspiels.append(hoerspiel)
                    let previous = try await dataManager.manager.fetch({
                        var fetchDescriptor = FetchDescriptor<Hoerspiel>(predicate: #Predicate<Hoerspiel> { hoerspiel in
                            hoerspiel.releaseDate > releaseDate && hoerspiel.artist == artist
                        }, sortBy: [SortDescriptor(\Hoerspiel.releaseDate)])
                        fetchDescriptor.fetchLimit = 2
                        return fetchDescriptor
                    })
                    surroundingHoerspiels.append(contentsOf: previous)
                    surroundingHoerspiels.sort { $0.releaseDate < $1.releaseDate }
                    
                    state = .finished
                    
                } catch {
                    state = .failed(error: error)
                    Logger.metadata.fullError(error, sendToTelemetryDeck: true)
                }
            }
        }
    }
    
    /// A view displaying the chapters
    var chapterView: some View {
        VStack(alignment: .leading) {
            if chapters.isEmpty {
                SectionHeader(title: "Kapitel")
                Text("Keine Kapitel verfügbar")
                    .padding(.horizontal)
            } else {
                SectionHeaderLink(title: "Kapitel") {
                    chapterList
                }
                
                ForEach(displayChapters, id: \.self) { chapter in
                    VStack {
                        Button {
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
                                             ? Color.primary
                                             : Color.accentColor)
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
    }
    
    /// A view displaying the surrounding Hoerspiels
    var surroundingHoerspielView: some View {
        Group {
            if !surroundingHoerspiels.isEmpty {
                SectionHeader(title: "Weiterhören")
                ScrollViewReader { value in
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(surroundingHoerspiels) { hoerspiel in
                                HoerspielDisplayView(hoerspiel, .rectangular)
                                    .id(hoerspiel.upc)
                            }
                            
                        }
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.viewAligned)
                    .scrollIndicators(.never)
                    .contentMargins(.leading, 20, for: .scrollContent)
                    .onAppear {
                        value.scrollTo(hoerspiel.upc, anchor: .leading)
                    }
                }
            }
        }
    }
    
    /// A view displaying the description
    var descriptionView: some View {
        VStack(alignment: .leading) {
            if metadata?.beschreibung != nil || metadata?.kurzbeschreibung != nil {
                SectionHeaderLink(title: "Beschreibung") {
                    List {
                        Text(metadata?.kurzbeschreibung ?? "")
                            .bold()
                        + Text(metadata?.kurzbeschreibung != nil && metadata?.beschreibung != nil ? " " : "")
                        + Text(metadata?.beschreibung ?? "")
                        Text("Die Beschreibung wurde von [dreimetadaten.de](https://dreimetadaten.de) geladen")
                    }
                    .listStyle(.plain)
                    .navigationTitle("Beschreibung")
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
            
            Group {
                Text(metadata?.kurzbeschreibung ?? "")
                    .bold()
                + Text(metadata?.kurzbeschreibung != nil && metadata?.beschreibung != nil ? " " : "")
                + Text(metadata?.beschreibung ?? "")
            }
            .padding(.horizontal)
            .foregroundStyle(.secondary)
            .lineLimit(7)
        }
    }
    
    /// A view displaying information
    var infoView: some View {
        DetailsInfoView(hoerspiel: hoerspiel, entries: [
            DetailsInfoDisplay(title: "Kapitel-Quelle",
                                 value: source?.name ?? "Apple Music",
                                 type: .link(link: source?.url ?? URL(string: "music://music.apple.com")!)),
        ])
    }
    
    /// Fetches the tracks from local storage or apple music
    func fetchTracks() async throws {
        if let tracks = try? await dataManager.manager.fetchTracks(hoerspiel.persistentModelID).sorted() {
            var previousSum: TimeInterval = 0
            for track in tracks {
                chapters.append(Chapter(name: track.title,
                                        start: previousSum,
                                        end: previousSum + track.duration))
                previousSum += track.duration
            }
        } else {
            let album = try await hoerspiel.persistentModelID.album(dataManager.manager)?.with(.tracks)
            var previousSum: TimeInterval = 0
            if let tracks = album?.tracks {
                for track in album?.tracks ?? [] {
                    if let duration = track.duration, duration != 0 {
                        chapters.append(Chapter(name: track.title,
                                                start: previousSum,
                                                end: previousSum + duration))
                        previousSum += duration
                    }
                }
                try? await dataManager.manager.setTracks(hoerspiel.persistentModelID, tracks.map { SendableStoredTrack($0, index: tracks.firstIndex(of: $0) ?? 0) })
                let duration = Double(tracks.reduce(0, { $0 + ($1.duration ?? 0)}))
                try await dataManager.manager.update(hoerspiel.persistentModelID,
                                                     keypath: \.duration,
                                                     to: duration)
                hoerspiel.duration = duration
            }
            
        }
    }
    
    /// The detail view list of chapters
    var chapterList: some View {
        List(chapters, id: \.self) { chapter in
            Button {
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
            }
            .font(.body)
        }
        .navigationTitle("Kapitel")
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(.plain)
    }
    
    /// The current view state
    enum ViewState {
        case loading, finished, failed(error: Error)
    }
}

/// A chapter of a Hoerspiel
struct Chapter: Hashable {
    
    /// The name of the chapter
    var name: String
    
    /// The start of the chapter
    var start: TimeInterval
    
    /// The end of the chapter
    var end: TimeInterval
}

/// The chapter source for fetched Chapters
struct ChapterSource {
    
    /// The name
    var name: String
    
    /// The url to link to
    var url: URL
}
