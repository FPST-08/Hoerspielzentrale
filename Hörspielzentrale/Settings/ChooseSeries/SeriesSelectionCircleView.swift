//
//  SeriesSelectionCircleView.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 22.11.24.
//
import MusicKit
import SwiftUI

/// A view to display a currently selected series
struct SeriesSelectionCircleView: View {
    // MARK: - Properties
    /// The series to present
    let series: Artist
    
    @Environment(SeriesManager.self) var seriesManager
    
    /// The current progress of the download
    ///
    /// If series is either fully downloaded or awaiting a download this value is 1
    var progress: CGFloat {
        if seriesManager.currentlyDownloadingArtist == series {
            return seriesManager.currentProgressValue
        } else {
            return 1
        }
    }
    // MARK: - View
    var body: some View {
        VStack {
            if let artwork = series.artwork {
                ArtworkImage(artwork, width: 100)
                    .clipShape(Circle())
                    .overlay {
                        if seriesManager.currentlyDownloadingArtist != series
                            && seriesManager.seriesToDownload.contains(series) {
                            Circle()
                                .foregroundStyle(Color.white.opacity(0.5))
                        }
                    }
                    .progressClock(value: seriesManager.currentProgressValue,
                                   color: Color.white.opacity(0.5),
                                   width: 100,
                                   height: 100,
                                   disabled: seriesManager.currentlyDownloadingArtist != series
                    )
            } else {
                ZStack {
                    Circle()
                        .foregroundStyle(Color.gray)
                    ProgressView()
                }
            }
            Text(series.name)
                .lineLimit(1)
        }
    }
}
