//
//  RecentlySearchedInlineViews.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 05.02.25.
//

import Defaults
import MusicKit
import SwiftUI

struct RecentlySearchedInlineSeriesView: View {
    /// The series of the search result
    let series: SendableSeries
    
    /// Referencing an `@Observable` class responsible for loading and caching covers
    @Environment(ImageCache.self) var imageCache
    
    /// The corresponding image
    @State private var image: Image?
    
    @Default(.recentlySearched) var recentlySearched
    
    var body: some View {
        NavigationLink {
            SeriesDetailView(series: series)
                .onAppear {
                    let searchResult = SearchResult(series)
                    recentlySearched.removeAll { $0.id == searchResult.id }
                    recentlySearched.insert(searchResult, at: 0)
                    if recentlySearched.count > 20 {
                        recentlySearched.removeLast()
                    }
                }
        } label: {
            HStack {
                Group {
                    if let image {
                        image
                            .resizable()
                            .scaledToFit()
                    } else {
                        Rectangle()
                            .foregroundStyle(Color.gray)
                    }
                }
                .frame(width: 70, height: 70)
                .clipShape(.circle)
                VStack(alignment: .leading) {
                    Text(series.name)
                        .lineLimit(1)
                    Text("Serie")
                        .foregroundStyle(Color.secondary)
                }
            }
            .task {
                image = await imageCache.image(for: series)
            }
        }
    }
}

struct RecentlySearchedInlineHoerspielView: View {
    /// The hoerspiel of the search result
    let hoerspiel: SendableHoerspiel
    
    /// Referencing an `@Observable` class responsible for loading and caching covers
    @Environment(ImageCache.self) var imageCache
    
    /// The corresponding image
    @State private var image: Image?
    
    @Default(.recentlySearched) var recentlySearched
    
    var body: some View {
        NavigationLink {
            HoerspielDetailView(hoerspiel)
                .onAppear {
                    let searchResult = SearchResult(hoerspiel)
                    recentlySearched.removeAll { $0.id == searchResult.id }
                    recentlySearched.insert(searchResult, at: 0)
                    if recentlySearched.count > 20 {
                        recentlySearched.removeLast()
                    }
                }
        } label: {
            HStack {
                Group {
                    if let image {
                        image
                            .resizable()
                            .scaledToFit()
                    } else {
                        Rectangle()
                            .foregroundStyle(Color.gray)
                    }
                }
                .frame(width: 70, height: 70)
                .clipShape(.rect(cornerRadius: 5))
                VStack(alignment: .leading) {
                    Text(hoerspiel.title)
                        .lineLimit(1)
                    Text("\(hoerspiel.artist) · Hörspiel")
                        .foregroundStyle(Color.secondary)
                }
            }
            .task {
                image = await imageCache.image(for: hoerspiel)
            }
        }
        
    }
}

struct RecentlySearchedInlineAlbumView: View {
    /// The album of the search response
    let album: Album
    
    @Default(.recentlySearched) var recentlySearched
    
    var body: some View {
        NavigationLink {
            HoerspielDetailView(album)
                .onAppear {
                    let searchResult = SearchResult(album)
                    recentlySearched.removeAll { $0.id == searchResult.id }
                    recentlySearched.insert(searchResult, at: 0)
                    if recentlySearched.count > 20 {
                        recentlySearched.removeLast()
                    }
                }
        } label: {
            HStack {
                Group {
                    if let artwork = album.artwork {
                        ArtworkImage(artwork, width: 70, height: 70)
                    } else {
                        Rectangle()
                            .foregroundStyle(Color.gray)
                    }
                }
                .frame(width: 70, height: 70)
                .clipShape(.rect(cornerRadius: 5))
                VStack(alignment: .leading) {
                    Text(album.title)
                    Text("\(album.artistName) · Hörspiel")
                        .foregroundStyle(Color.secondary)
                }
            }
        }
        
    }
}

struct RecentlySearchedInlineArtistView: View {
    /// The artist of the search response
    let artist: Artist
    
    @Default(.recentlySearched) var recentlySearched
    
    var body: some View {
        NavigationLink {
            SeriesDetailView(artist: artist)
                .onAppear {
                    let searchResult = SearchResult(artist)
                    recentlySearched.removeAll { $0.id == searchResult.id }
                    recentlySearched.insert(searchResult, at: 0)
                    if recentlySearched.count > 20 {
                        recentlySearched.removeLast()
                    }
                }
        } label: {
            HStack {
                Group {
                    if let artwork = artist.artwork {
                        ArtworkImage(artwork, width: 70, height: 70)
                    } else {
                        Rectangle()
                            .foregroundStyle(Color.gray)
                    }
                }
                .frame(width: 70, height: 70)
                .clipShape(.circle)
                VStack(alignment: .leading) {
                    Text(artist.name)
                    Text("Serie")
                        .foregroundStyle(Color.secondary)
                }
            }
        }
    }
}
