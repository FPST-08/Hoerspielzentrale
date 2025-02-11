//
//  SeriesView.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 20.01.25.
//

import MusicKit
import OSLog
import SwiftData
import SwiftUI
import TelemetryDeck

/// A view used to display details about a ``Series``
struct SeriesDetailView: View {
    /// The ``Series`` to display details about
    @State private var series: SendableSeries?
    
    /// An Observable Class responsible for data
    @Environment(DataManagerClass.self) var dataManager
    
    /// Referencing an `@Observable` class responsible for loading and caching covers
    @Environment(ImageCache.self) var imageCache
    
    /// Referencing an `Observable` class responsible for playback
    @Environment(MusicManager.self) var musicManager
    
    @Environment(SeriesManager.self) var seriesManager
    
    /// The image of the ``Series``
    @State private var seriesImage: UIImage?
    
    /// The dominant color of the `seriesImage`
    @State private var color = Color.primary
    
    /// The corresponding artist for this ``Series``
    @State private var artist: Artist?
    
    @State private var albums: [Album]?
    
    let name: String
    
    let musicItemID: String
    
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Daten werden geladen")
            } else {
                ScrollView {
                    VStack {
                        if let image = Image(seriesImage) {
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 250, height: 250)
                                .cornerRadius(15)
                                .padding()
                        } else {
                            RoundedRectangle(cornerRadius: 15)
                                .frame(width: 250, height: 250)
                                .foregroundStyle(Color.secondary)
                                .padding()
                        }
                        if let series {
                            ZStack {
                                Button {
                                    playMostRecentHoerspiel()
                                } label: {
                                    Label("Neueste Folge", systemImage: "play.circle")
                                }
                                .buttonStyle(ProminentButtonStyle())
                                HStack {
                                    Spacer()
                                    Button {
                                        Task {
                                            await musicManager.playRandom(seriesNames: [series.name])
                                        }
                                    } label: {
                                        Image(systemName: "dice")
                                    }
                                    .buttonStyle(ProminentButtonStyle())
                                    .padding(.horizontal)
                                }
                            }
                        }
                        if let series {
                            SeriesDetailUpcomingView(series: series)
                            HomeSection(title: "Als Nächstes", displaymode: .rectangular, fetchDescriptor: {
                                let id = series.musicItemID
                                // swiftlint:disable:next line_length
                                var descriptor = FetchDescriptor<Hoerspiel>(predicate: #Predicate<Hoerspiel> { hoerspiel in
                                    hoerspiel.showInUpNext && hoerspiel.series?.musicItemID == id
                                })
                                descriptor.sortBy = [SortDescriptor(\Hoerspiel.addedToUpNext, order: .reverse)]
                                descriptor.fetchLimit = 20
                                return descriptor
                            }, destination: .hoerspielList)
                        }
                        
                        if let series {
                            SeriesDetailHoerspielView(series: series)
                            SeriesInfoView(series: series)
                                .padding(.vertical)
                        }
                        if let artist, series == nil {
                            ArtistAddView(artist: artist)
                                .onChange(of: seriesManager.currentProgressValue) { _, _ in
                                    // swiftlint:disable:next line_length
                                    let currentlyNotDownloadingArtist = seriesManager.currentlyDownloadingArtist != artist
                                    let isPartOfSelectedArtists = seriesManager.selectedArtists.contains(where: { $0.id == artist.id })
                                    // swiftlint:disable:previous line_length
                                    if  currentlyNotDownloadingArtist && isPartOfSelectedArtists {
                                        Task {
                                            series = await fetchSeries(artist: artist)
                                        }
                                    }
                                }
                            if let albums {
                                ScrollView(.horizontal) {
                                    HStack {
                                        ForEach(albums, id: \.self) { album in
                                            AlbumDisplayView(album: album)
                                        }
                                    }
                                }
                                .contentMargins(20, for: .scrollContent)
                            }
                        }
                        Link(destination: URL(string: "music://music.apple.com/de/artist/\(musicItemID)")!) {
                            Label("In Apple Music öffnen", systemImage: "arrowshape.turn.up.right")
                                .padding([.horizontal, .bottom])
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
        .navigationTitle(name)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaPadding(.bottom, 60)
        .task {
            if let artist, series == nil {
                series = await fetchSeries(artist: artist)
            }
            isLoading = false
            if let series {
                Logger.data.info("Fetching image for series")
                seriesImage = await imageCache.uiimage(for: series)
            } else {
                Logger.data.info("Loading url for artist artwork")
                guard let artworkURL = artist?.artwork?.url(width: 512, height: 512) else {
                    Logger.data.info("Failed loading url for artist artwork")
                    return
                }
                Logger.data.info("Loading data from url")
                guard let (data, _) = try? await URLSession.shared.data(from: artworkURL) else {
                    Logger.data.info("URLSession failed")
                    return
                }
                Logger.data.info("Converting data to uiimage")
                guard let uiimage = UIImage(data: data) else {
                    return
                }
                Logger.data.info("Fetching image for artist")
                seriesImage = uiimage
            }
            color = Color(uiColor: seriesImage?.averageColor ?? UIColor.gray)
            do {
                if series == nil {
                    let batch = try await artist?.with(.albums).albums
                    albums = Array(batch ?? [])
                }
            } catch {
                Logger.data.fullError(error, sendToTelemetryDeck: true)
            }
        }
        .trackNavigation(path: "SeriesDetailView")
    }
    
    /// Fetches the series corresponding to an artist
    /// - Parameter artist: The initial artist
    /// - Returns: The corresponding series
    func fetchSeries(artist: Artist) async -> SendableSeries? {
        Logger.data.info("Fetching series for artist")
        let id = artist.id.rawValue
        let series = try? await dataManager.manager.fetch({
            var fetchDescriptor = FetchDescriptor<Series>(predicate: #Predicate<Series> { series in
                series.musicItemID == id
            })
            fetchDescriptor.fetchLimit = 1
            return fetchDescriptor
        }).first
        return series
    }
    
    /// Plays the most recent hoerspiel if the series is available
    func playMostRecentHoerspiel() {
        if let series {
            Task {
                if let hoerspiel = try? await dataManager.manager.fetch({
                    let id = series.musicItemID
                    let now = Date.now
                    var descriptor = FetchDescriptor<Hoerspiel>(predicate: #Predicate { hoerspiel in
                        hoerspiel.series?.musicItemID == id && hoerspiel.releaseDate < now
                    })
                    descriptor.fetchLimit = 1
                    descriptor.sortBy = [SortDescriptor(\Hoerspiel.releaseDate, order: .reverse)]
                    return descriptor
                }).first {
                    musicManager.startPlayback(for: hoerspiel.persistentModelID)
                }
            }
        }
    }
    
    /// Creates the view from a series
    /// - Parameter series: The series
    init(series: SendableSeries) {
        self.series = series
        self.name = series.name
        self.musicItemID = series.musicItemID
    }
    
    /// Creates the view from an artist
    /// - Parameter artist: The artist
    init(artist: Artist) {
        self.artist = artist
        self.name = artist.name
        self.musicItemID = artist.id.rawValue
    }
}
