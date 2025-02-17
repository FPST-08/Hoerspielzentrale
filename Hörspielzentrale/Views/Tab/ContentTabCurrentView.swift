//
//  ContentTabCurrentView.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 15.02.25.
//

import SwiftData
import SwiftUI

/// The current tab view
@available(iOS 18, *)
struct ContentTabCurrentView: View {
    
    /// An Observable Class responsible for navigation
    @Environment(NavigationManager.self) var navigation
    
    /// All available series
    @Query var series: [Series]
    
    @AppStorage("tabViewCustomization") var customization: TabViewCustomization
    
    /// Referencing an `Observable` class responsible for playback
    @Environment(MusicManager.self) var musicmanager
    
    /// A boolean that indicates a currently running animation
    @Binding var animateContent: Bool
    
    /// The namespace of all animations related to the ``customBottomSheet()`` and ``ExpandBottomSheet`
    let animation: Namespace.ID
    
    var body: some View {
        TabView(selection: Bindable(navigation).selection) {
            Tab("Startseite", systemImage: "house", value: Selection.home) {
                HomeView()
            }
            .customizationID("Tab.Home")
            .customizationBehavior(.disabled, for: .sidebar, .tabBar)
            Tab("Mediathek", systemImage: "play.square.stack", value: Selection.library) {
                LibraryView()
            }
            .customizationID("Tab.Library")
            .customizationBehavior(.disabled, for: .sidebar, .tabBar)
            Tab(value: Selection.search, role: .search) {
                NewSearchView()
            }
            .customizationID("Tab.Search")
            if UIDevice.isIpad {
                TabSection("Serien") {
                    ForEach(series) { series in
                        Tab(series.name,
                            systemImage: "music.microphone",
                            value: Selection.series(id: series.musicItemID)) {
                            SeriesDetailView(series: SendableSeries(series))
                        }
                        .customizationID(series.musicItemID)
                    }
                }
                .defaultVisibility(.hidden, for: .tabBar)
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .tabViewCustomization($customization)
    }

    init(animateContent: Binding<Bool>, animation: Namespace.ID) {
        _animateContent = animateContent
        self.animation = animation
        
        _series = Query(sort: [SortDescriptor(\Series.name)])
    }
}
