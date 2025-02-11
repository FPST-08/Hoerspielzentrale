//
//  RecentlySearchedView.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 05.02.25.
//

import Defaults
import SwiftUI

/// Displaying the recently searched entries
struct RecentlySearchedView: View {
    @Default(.recentlySearched) var recentlySearched
    
    /// Referencing an `@Observable` class responsible for loading and caching covers
    @Environment(ImageCache.self) var imageCache
    
    var body: some View {
        if !recentlySearched.isEmpty {
            HStack {
                Text("Zuletzt gesucht")
                Spacer()
                Button("Löschen") {
                    recentlySearched = []
                }
                .buttonStyle(PlainButtonStyle())
                .foregroundStyle(Color.accent)
            }
            ForEach(recentlySearched, id: \.self) { entry in
                switch entry {
                case .album(let album):
                    RecentlySearchedInlineAlbumView(album: album)
                case .series(let series):
                    RecentlySearchedInlineSeriesView(series: series)
                case .hoerspiel(let hoerspiel):
                    RecentlySearchedInlineHoerspielView(hoerspiel: hoerspiel)
                case .artist(let artist):
                    RecentlySearchedInlineArtistView(artist: artist)
                }
            }
        }
    }
}
