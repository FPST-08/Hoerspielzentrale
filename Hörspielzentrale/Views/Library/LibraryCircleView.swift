//
//  LibraryCircleView.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 21.01.25.
//

import SwiftUI

/// A view to display a series as a circle
struct LibraryCircleView: View {
    /// The series to display
    let series: SendableSeries
    
    /// The image of the series
    @State private var image: Image?
    
    /// Referencing an `@Observable` class responsible for loading and caching covers
    @Environment(ImageCache.self) var imageCache
    
    /// Referencing an `Observable` class responsible for playback
    @Environment(MusicManager.self) var musicManager
    
    var body: some View {
        NavigationLink {
            SeriesDetailView(series: series)
        } label: {
            ZStack {
                Circle()
                    .foregroundStyle(Color.white.opacity(0.3))
                if let image = image {
                    image
                        .resizable()
                        .scaledToFit()
                        .clipShape(Circle())
                        .padding(1)
                } else {
                    Circle()
                        .foregroundStyle(Color.gray)
                        .padding(1)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contextMenu {
                Button {
                    Task {
                        await musicManager.playRandom(seriesNames: [series.name])
                    }
                } label: {
                    Label("Zufällig abspielen", systemImage: "dice")
                }
            }
        }
        .task {
            image = await imageCache.image(for: series)
        }
    }
}
