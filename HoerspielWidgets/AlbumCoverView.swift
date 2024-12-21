//
//  AlbumCoverView.swift
//  HoerspielWidgetsExtension
//
//  Created by Philipp Steiner on 02.07.24.
//

import SwiftUI
// swiftlint:disable trailing_whitespace
/// A view used to display covers and open a link on tap
struct AlbumCoverView: View {
    // MARK: - Properties
    /// The link to open when tapped
    let url: URL
    
    /// The image to show
    let image: Image
    // MARK: - View
    var body: some View {
        Link(destination: url) {
            image.resizable().scaledToFit()
        }
            
    }
    
    /// Initializes a ``AlbumCoverView`` from a ``DisplayHoerspiel``
    /// - Parameter displayHoerspiel: The ``DisplayHoerspiel`` that should be presented
    init(displayHoerspiel: DisplayHoerspiel) {
        self.url = displayHoerspiel.url
        self.image = displayHoerspiel.image
    }
}
// swiftlint:enable trailing_whitespace
