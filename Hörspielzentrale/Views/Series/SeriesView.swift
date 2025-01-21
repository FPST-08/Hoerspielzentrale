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
    let series: SendableSeries
    
    /// An Observable Class responsible for data
    @Environment(DataManagerClass.self) var dataManager
    
    /// Referencing an `@Observable` class responsible for loading and caching covers
    @Environment(ImageCache.self) var imageCache
    
    /// Referencing an `Observable` class responsible for playback
    @Environment(MusicManager.self) var musicManager
    
    /// The image of the ``Series``
    @State private var seriesImage: UIImage?
    
    /// The dominant color of the `seriesImage`
    @State private var color = Color.primary
    
    /// An optional upcoming ``Hoerspiel``
    @State private var upcomingHoerspiel: SendableHoerspiel?
    
    /// The 10 most recent ``Hoerspiel`` published in this ``Series``
    @State private var mostRecentHoerspiels = [SendableHoerspiel]()
    
    /// The corresponding artist for this ``Series``
    @State private var artist: Artist?
    
    var body: some View {
        ScrollView {
            VStack {
                if let image = Image(seriesImage) {
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250, height: 250)
                        .cornerRadius(15)
                    
                } else {
                    RoundedRectangle(cornerRadius: 15)
                        .frame(width: 250, height: 250)
                        .foregroundStyle(Color.secondary)
                }
                ZStack {
                    Button {
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
                
                if let upcomingHoerspiel {
                    SectionHeader(title: "Bald verfügbar")
                    HoerspielDisplayView(upcomingHoerspiel, .rectangular)
                }
                
                HomeSection(title: "Als Nächstes", displaymode: .rectangular, fetchDescriptor: {
                    let id = series.musicItemID
                    var descriptor = FetchDescriptor<Hoerspiel>(predicate: #Predicate<Hoerspiel> { hoerspiel in
                        hoerspiel.showInUpNext && hoerspiel.series?.musicItemID == id
                    })
                    descriptor.sortBy = [SortDescriptor(\Hoerspiel.addedToUpNext, order: .reverse)]
                    descriptor.fetchLimit = 20
                    return descriptor
                }, destination: .hoerspielList)
                
                allHoerspielSection
                
                SeriesInfoView(series: series)
            }
        }
        .navigationTitle(series.name)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaPadding(.bottom, 60)
        .task {
            seriesImage = await imageCache.uiimage(for: series)
            color = Color(uiColor: seriesImage?.averageColor ?? UIColor.white)
            upcomingHoerspiel = try? await dataManager.manager.fetch({
                let id = series.musicItemID
                let now = Date.now
                var descriptor = FetchDescriptor<Hoerspiel>(predicate: #Predicate { hoerspiel in
                    hoerspiel.series?.musicItemID == id && hoerspiel.releaseDate > now
                })
                descriptor.fetchLimit = 1
                descriptor.sortBy = [SortDescriptor(\Hoerspiel.releaseDate, order: .reverse)]
                return descriptor
            }).first
            mostRecentHoerspiels = (try? await dataManager.manager.fetch({
                let id = series.musicItemID
                let now = Date.now
                var descriptor = FetchDescriptor<Hoerspiel>(predicate: #Predicate { hoerspiel in
                    hoerspiel.series?.musicItemID == id && hoerspiel.releaseDate < now
                })
                descriptor.fetchLimit = 10
                descriptor.sortBy = [SortDescriptor(\Hoerspiel.releaseDate, order: .reverse)]
                return descriptor
            })) ?? []
            do {
                var request = MusicCatalogResourceRequest<Artist>(matching: \.id,
                                                                  equalTo: MusicItemID(series.musicItemID))
                request.properties.append(contentsOf: [.similarArtists, .topSongs])
                let response = try await request.response()
                artist = response.items.first
                Logger.data.info("Topsongs count: \(artist?.topSongs?.count ?? 0)")
            } catch {
                Logger.metadata.fullError(error, sendToTelemetryDeck: true)
            }
        }
        .trackNavigation(path: "SeriesDetailView")
    }
    
    /// A view to display and link to all ``Hoerspiel``
    var allHoerspielSection: some View {
        Group {
            NavigationSection(destination: .allHoerspiels(series: series), title: "Alle Hörspiele")
            ScrollView(.horizontal) {
                LazyHStack {
                    ForEach(mostRecentHoerspiels) { hoerspiel in
                        HoerspielDisplayView(hoerspiel, .coverOnly)
                    }
                    NavigationLink {
                        AllHoerspielsView(series: series)
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 15)
                                .foregroundStyle(Color.white.opacity(0.3))
                            RoundedRectangle(cornerRadius: 15)
                                .foregroundStyle(Color.systemBackground)
                                .padding(1)
                            VStack {
                                Image(systemName: "chevron.forward")
                                    .font(.title)
                                    .fontWeight(.heavy)
                                Text("Alle anzeigen")
                                    .fontWeight(.medium)
                            }
                            
                        }
                        .frame(width: 120, height: 120)
                    }
                    
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollIndicators(.never)
            .contentMargins(.leading, 20, for: .scrollContent)
        }
    }
}
