//
//  SeriesTopSongsView.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 20.01.25.
//

import MusicKit
import OSLog
import SwiftData
import SwiftUI

/// A view used to display the top hits for a ``Series``
struct SeriesTopSongsView: View {
    /// The artist of the ``Hoerspiel``
    let artist: Artist
    
    /// The ``Hoerspiel`` that are considerd top hits
    @State private var topHoerspiele = [SendableHoerspiel]()
    
    /// An Observable Class responsible for data
    @Environment(DataManagerClass.self) var dataManager
    
    var body: some View {
        VStack {
            if !topHoerspiele.isEmpty {
                SectionHeaderLink(title: "Top-Hörspiele") {
                    ListView(hoerspiele: topHoerspiele)
                }
                ScrollView(.horizontal) {
                    LazyHStack {
                        ForEach(topHoerspiele) { hoerspiel in
                            HoerspielDisplayView(hoerspiel, .rectangular)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollIndicators(.never)
                .contentMargins(.leading, 20, for: .scrollContent)
            }
        }
        .task {
            do {
                let topSongs = artist.topSongs ?? []
                Logger.data.info("Topsongs count: \(topSongs.count)")
                var albums = [Album]()
                
                for song in topSongs {
                    var request = MusicCatalogResourceRequest<Song>(matching: \.isrc, equalTo: song.isrc)
                    request.properties.append(contentsOf: [.albums])
                    let response = try await request.response()
                    if let album = response.items.first?.albums?.first {
                        albums.append(album)
                    }
                    
                }
                Logger.data.info("Albums count: \(albums.count)")
                for album in albums {
                    let hoerspiel = try? await dataManager.manager.fetch({
                        let upc = album.upc ?? ""
                        var descriptor = FetchDescriptor<Hoerspiel>(predicate: #Predicate { hoerspiel in
                            hoerspiel.upc == upc
                        })
                        descriptor.fetchLimit = 1
                        return descriptor
                    }).first
                    
                    if let hoerspiel, !topHoerspiele.contains(hoerspiel) {
                        topHoerspiele.append(hoerspiel)
                    }
                }
            } catch {
                Logger.data.fullError(error, sendToTelemetryDeck: true)
            }
        }
    }
}
