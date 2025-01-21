//
//  LibrarySectionView.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 19.10.24.
//

import SwiftData
import SwiftUI

/// A reusable Section of the ``HomeView``
struct HomeSection: View {
    // MARK: - Properties
    
    /// The title of the section
    let title: String
    
    @Query var hoerspiele: [Hoerspiel]
    
    /// The current display mode
    let displaymode: DisplayMode
    
    let destination: Destination
    
    /// The current view state
    @State private var viewState: ViewState = .loading
    
    // MARK: - View
    var body: some View {
        Group {
            if hoerspiele.isEmpty {
                EmptyView()
            } else {
                switch destination {
                case .hoerspielList:
                    NavigationSection(destination:
                            .hoerspielList(hoerspiele: hoerspiele.map {
                                SendableHoerspiel(hoerspiel: $0)
                            }), title: title)
                case .series(let series):
                    NavigationSection(destination: .series(series: series), title: series.name)
                }
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
    
    enum Destination {
        case hoerspielList
        case series(series: SendableSeries)
    }
    
    init(title: String,
         displaymode: DisplayMode,
         fetchDescriptor: @escaping () -> FetchDescriptor<Hoerspiel>,
         destination: Destination = .hoerspielList
    ) {
        self.title = title
        self.displaymode = displaymode
        self.destination = destination
        _hoerspiele = Query(fetchDescriptor())
    }
}
