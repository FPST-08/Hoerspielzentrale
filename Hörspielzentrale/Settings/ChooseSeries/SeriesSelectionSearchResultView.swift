//
//  OnboardingSeriesSearchResultView.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 22.11.24.
//

import MusicKit
import SwiftUI

/// A view to display search results
struct SeriesSelectionSearchResultView: View {
    // MARK: - Properties
    /// The series
    let series: Artist
    
    // MARK: - View
    var body: some View {
        HStack {
            if let artwork = series.artwork {
                ArtworkImage(artwork, width: 50)
                    .clipShape(Circle())
            } else {
                Circle()
                    .frame(width: 50)
                    .foregroundStyle(Color.gray)
            }
            Text(series.name)
            
        }
    }
}
