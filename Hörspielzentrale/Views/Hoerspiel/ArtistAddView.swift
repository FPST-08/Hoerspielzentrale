//
//  ArtistAddView.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 09.02.25.
//

import MusicKit
import SwiftUI

/// A view used to add artists to the library
struct ArtistAddView: View {
    /// The artist to add
    let artist: Artist
    
    /// Referencing an `@Observable` class responsible for managing series
    @Environment(SeriesManager.self) var seriesManager
    
    /// The description presented to the user
    var description: String {
        if seriesManager.currentlyDownloadingArtist == artist {
            return "\(seriesManager.currentProgressLabel)"
        } else if seriesManager.seriesToDownload.contains(artist) {
            return """
\(seriesManager.currentlyDownloadingArtist?.name ?? "N/A") wird aktuell geladen. \ 
Anschließend wird \(artist.name) geladen
"""
        } else if seriesManager.selectedArtists.contains(where: { $0.id == artist.id }) {
            return "\(artist.name) ist bereits hinzugefügt"
        } else {
            return """
Diese Serie ist nicht zur Mediathek hinzugefügt. \
Um Hörspiele dieser Serie abspielen zu können, füge die Serie zur Mediathek hinzu. 

"""
        }
    }
    
    /// The title of the button
    var buttonTitle: String {
        if seriesManager.currentlyDownloadingArtist == artist {
            return "\(artist.name) lädt..."
        } else if seriesManager.seriesToDownload.contains(artist) {
            return "\(artist.name) wird geladen"
        } else if seriesManager.selectedArtists.contains(where: { $0.id == artist.id}) {
            return "\(artist.name) ist bereits hinzugefügt"
        } else {
            return "Hinzufügen"
        }
    }
    
    /// Whether the button should be disabled
    var disableButton: Bool {
        return seriesManager.currentlyDownloadingArtist == artist
        || seriesManager.seriesToDownload.contains(artist)
        || seriesManager.selectedArtists.contains(where: { artist.id == $0.id })
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15)
                .foregroundStyle(Color.accent)
            RoundedRectangle(cornerRadius: 15)
                .padding(1)
                .foregroundStyle(Color.systemBackground)
            VStack {
                Text(description)
                    .lineLimit(4, reservesSpace: true)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 5)
                Button {
                    seriesManager.downloadSeries(artist)
                } label: {
                    HStack {
                        if seriesManager.currentlyDownloadingArtist?.id == artist.id {
                            ProgressView()
                        } else {
                            Image(systemName: "plus.circle")
                        }
                        Text(buttonTitle)
                    }
                }
                .buttonStyle(BorderedProminentButtonStyle())
                .disabled(disableButton)
            }
            .padding()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
    }
}
