//
//  LibrarySectionView.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 19.10.24.
//

import SwiftData
import SwiftUI

/// A reusable Section of the ``LibraryView``
struct LibrarySectionView: View {
    // MARK: - Properties
    
    /// The title of the section
    let title: String
    
    @Query var hoerspiele: [Hoerspiel]
    
    /// The current display mode
    let displaymode: DisplayMode
    
    /// The current view state
    @State private var viewState: ViewState = .loading
    
    /// The width of the loading tile
    var width: CGFloat {
        switch displaymode {
        case .rectangular:
            UIScreen.screenWidth * 0.9
        case .coverOnly:
            130
        case .big:
            UIScreen.screenWidth * 0.9
        }
    }
    
    /// The height of the loading tile
    var height: CGFloat {
        switch displaymode {
        case .rectangular:
            140
        case .coverOnly:
            130
        case .big:
            UIScreen.screenWidth * 0.9
        }
    }
    
    // MARK: - View
    var body: some View {
        Group {
            if hoerspiele.isEmpty {
                EmptyView()
            } else {
                NavigationSection(hoerspiele: hoerspiele.map { SendableHoerspiel(hoerspiel: $0) }, title: title)
                ScrollView(.horizontal) {
                    LazyHStack {
                        ForEach(hoerspiele) { hoerspiel in
                            HoerspielDisplayView(SendableHoerspiel(hoerspiel: hoerspiel), displaymode)
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
    
    enum ViewState {
        case loading, finished, hidden
    }
    
    init(title: String,
         fetchDescriptor: @escaping () -> FetchDescriptor<Hoerspiel>,
         displaymode: DisplayMode
    ) {
        self.title = title
        self.displaymode = displaymode
        self.viewState = viewState
        _hoerspiele = Query(fetchDescriptor())
    }
}
