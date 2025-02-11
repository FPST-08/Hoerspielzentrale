//
//  AlbumDisplayView.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 07.02.25.
//

import MusicKit
import SwiftUI

/// A view used to display a `Album` in multiple ways
struct AlbumDisplayView: View {
    /// The `Album` to display
    let album: Album
    
    /// The dominant color of the cover
    @State private var dominantColor = Color.gray
    
    var body: some View {
        NavigationLink {
            HoerspielDetailView(album)
        } label: {
            HStack(spacing: 0) {
                if let artwork = album.artwork {
                    ArtworkImage(artwork, width: 125, height: 125)
                        .cornerRadius(15)
                        .padding(8)
                } else {
                    RoundedRectangle(cornerRadius: 15)
                        .foregroundStyle(Color.gray)
                        .frame(width: 125)
                        .frame(maxHeight: .infinity)
                        .padding(8)
                }
                VStack(alignment: .leading) {
                    Text(album.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(dominantColor.adaptedTextColor())
                        .padding(.top, 5)
                        .multilineTextAlignment(.leading)
                    Text(album.editorialNotes?.standard ?? "")
                        .font(.subheadline)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(dominantColor.adaptedTextColor().secondary)
                    Spacer()
                }
                .padding(.vertical, 8)
                Spacer()
            }
            .frame(width: 350, height: 150)
            .background {
                RoundedRectangle(cornerRadius: 15)
                    .foregroundStyle(dominantColor)
                    
            }
            .shadow(radius: 5)
            .padding(.vertical)
            .task {
                if let backgroundColor = album.artwork?.backgroundColor {
                    dominantColor = Color(backgroundColor)
                }
                
            }
        }
        
    }
}
