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
struct HoerspielMusicDetailsView: View {
    // MARK: - Properties
    
    /// The fetched MetaData if available
    @State private var metadata: MetaData?
    
    /// The ``SendableHoerspiel``
    let hoerspiel: SendableHoerspiel?
    
    @State var album: Album?
    
    /// A bool indicating if the missing data view should be displayed
    let displayMissingDataView: Bool
    
    /// The albumID of the original source of truth
    let albumID: String
    
    /// An Observable Class responsible for data
    @Environment(DataManagerClass.self) var dataManager
    
    /// Referencing an `Observable` class responsible for playback
    @Environment(MusicManager.self) var musicManager
    
    /// The series of the ``SendableHoerspiel``
    @State private var series: SendableSeries?
    
    /// The current viewstate
    @State private var state = ViewState.loading
    
    /// The surrounding hoerspiels of this hoerspiel
    @State private var surroundingHoerspiels = [SendableHoerspiel]()
    
    // MARK: - View
    var body: some View {
        Group {
            switch state {
            case .loading:
                ProgressView {
                    Text("Daten werden geladen")
                }
            case .finished:
                if UIDevice.isIpad {
                    VStack {
                        HStack(alignment: .top) {
                            DetailChapterView(hoerspiel: hoerspiel, album: album)
                                .frame(maxWidth: .infinity)
                            VStack(alignment: .leading) {
                                descriptionView
                                    .frame(maxWidth: .infinity)
                                if let hoerspiel {
                                    DetailsInfoView(hoerspiel: hoerspiel)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        surroundingHoerspielView
                        
                        if let sprechrollen = metadata?.sprechrollen, !sprechrollen.isEmpty {
                            SectionHeader(title: "Sprecher")
                            SpeakerView(rollen: sprechrollen)
                        }
                        
                        if displayMissingDataView {
                            GroupBox("Mangelnde Daten") {
                                Text("""
    Für dieses Hörspiel sind nur Daten über Apple Music bekannt. 
    Wenn du eine bessere Datenquelle für dieses Hörspiel kennst, schreibe mir gerne über hoerspielzentrale@icloud.com
    """)
                            }
                            .padding(.horizontal)
                        }
                        Link(destination: URL(string: "music://music.apple.com/de/album/\(albumID)")!) {
                            Label("In Apple Music öffnen", systemImage: "arrowshape.turn.up.right")
                                .padding([.horizontal, .bottom])
                        }
                        
                    }
                    
                } else {
                    VStack(alignment: .leading) {
                        DetailChapterView(hoerspiel: hoerspiel, album: album)
                        descriptionView
                        if let hoerspiel {
                            DetailsInfoView(hoerspiel: hoerspiel)
                        }
                        surroundingHoerspielView
                        if let sprechrollen = metadata?.sprechrollen, !sprechrollen.isEmpty {
                            SectionHeader(title: "Sprecher")
                            SpeakerView(rollen: sprechrollen)
                        }
                        
                        if displayMissingDataView {
                            GroupBox("Mangelnde Daten") {
                                Text("""
                            Für dieses Hörspiel sind nur Daten über Apple Music bekannt. 
                            Wenn du eine bessere Datenquelle für dieses Hörspiel kennst, \ 
                            schreibe mir gerne über hoerspielzentrale@icloud.com
                            """)
                            }
                            .padding(.horizontal)
                        }
                        Link(destination: URL(string: "music://music.apple.com/de/album/\(albumID)")!) {
                            Label("In Apple Music öffnen", systemImage: "arrowshape.turn.up.right")
                                .padding([.horizontal, .bottom])
                        }
                    }
                }
            }
        }
        .task {
            if series == nil, let hoerspiel {
                series = try? await dataManager.manager.series(for: hoerspiel)
            }
#if DEBUG
            if hoerspiel?.upc == "DEBUG" {
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
#endif
            if metadata == nil {
                if let hoerspiel {
                    metadata = try? await hoerspiel.loadMetaData()
                } else if let album {
                    metadata = try? await album.loadMetaData()
                }
            }
            if let hoerspiel, surroundingHoerspiels.isEmpty {
                
                let releaseDate = hoerspiel.releaseDate
                let artist = hoerspiel.artist
                
                let next = (try? await dataManager.manager.fetch({
                    var fetchDescriptor = FetchDescriptor<Hoerspiel>(predicate: #Predicate<Hoerspiel> { hoerspiel in
                        hoerspiel.releaseDate < releaseDate && hoerspiel.artist == artist
                    }, sortBy: [SortDescriptor(\Hoerspiel.releaseDate, order: .reverse)])
                    fetchDescriptor.fetchLimit = 2
                    return fetchDescriptor
                })) ?? []
                surroundingHoerspiels.append(contentsOf: next)
                surroundingHoerspiels.append(hoerspiel)
                let previous = (try? await dataManager.manager.fetch({
                    var fetchDescriptor = FetchDescriptor<Hoerspiel>(predicate: #Predicate<Hoerspiel> { hoerspiel in
                        hoerspiel.releaseDate > releaseDate && hoerspiel.artist == artist
                    }, sortBy: [SortDescriptor(\Hoerspiel.releaseDate)])
                    fetchDescriptor.fetchLimit = 2
                    return fetchDescriptor
                })) ?? []
                surroundingHoerspiels.append(contentsOf: previous)
                surroundingHoerspiels.sort { $0.releaseDate < $1.releaseDate }
            }
            state = .finished
        }
    }
    
    /// A view displaying the surrounding Hoerspiels
    var surroundingHoerspielView: some View {
        Group {
            if let hoerspiel, !surroundingHoerspiels.isEmpty {
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
    
    /// The current view state
    enum ViewState {
        case loading, finished
    }
    
    /// Creates the view from a hoerspiel
    /// - Parameter hoerspiel: The hoerspiel
    init(_ hoerspiel: SendableHoerspiel) {
        self.hoerspiel = hoerspiel
        self.displayMissingDataView = (hoerspiel.artist != "Die drei ???"
                                       && hoerspiel.artist != "Die drei ??? Kids"
                                       && hoerspiel.upc != "DEBUG")
        self.albumID = hoerspiel.albumID
    }
    
    /// Creates the view from an album
    /// - Parameter album: The album
    init(_ album: Album) {
        self.album = album
        self.displayMissingDataView = (album.artistName != "Die drei ???"
                                       && album.artistName != "Die drei ??? Kids")
        self.albumID = album.id.rawValue
        self.hoerspiel = nil
    }
    
    /// Creates the view from an hoerspiel and an album
    /// - Parameters:
    ///   - hoerspiel: The hoerspiel
    ///   - album: The album
    init(
        _ hoerspiel: SendableHoerspiel?,
        _ album: Album?
    ) {
        if let hoerspiel {
            self.hoerspiel = hoerspiel
            self.album = album
            self.albumID = album?.id.rawValue ?? hoerspiel.albumID
            self.displayMissingDataView = (hoerspiel.artist != "Die drei ???"
                                           && hoerspiel.artist != "Die drei ??? Kids"
                                           && hoerspiel.upc != "DEBUG")
        } else if let album {
            self.hoerspiel = hoerspiel
            self.album = album
            self.albumID = album.id.rawValue
            self.displayMissingDataView = album.artistName != "Die drei ???" && album.artistName != "Die drei ??? Kids"
        } else {
            self.hoerspiel = hoerspiel
            self.album = album
            self.albumID = ""
            self.displayMissingDataView = false
            assertionFailure()
        }
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
