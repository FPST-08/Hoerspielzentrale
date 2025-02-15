//
//  ContentTabLegacyView.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 15.02.25.
//

import SwiftUI

/// The tab view prior to iOS 18
struct ContentTabLegacyView: View {
    
    /// An Observable Class responsible for navigation
    @Environment(NavigationManager.self) var navigation
    
    /// A boolean that indicates a currently running animation
    @Binding var animateContent: Bool
    
    /// The namespace of all animations related to the ``customBottomSheet()`` and ``ExpandBottomSheet`
    let animation: Namespace.ID

    var body: some View {
        TabView(selection: Bindable(navigation).selection) {
            HomeView()
                .tabItem { Label("Startseite", systemImage: "house.fill") }
                .tag(Selection.home)
                .playbackBottomSheet(animateContent: $animateContent,
                                     animation: animation)
            LibraryView()
                .tabItem { Label("Mediathek", systemImage: "play.square.stack")}
                .tag(Selection.library)
                .playbackBottomSheet(animateContent: $animateContent,
                                     animation: animation)
            NewSearchView()
                .tabItem { Label("Suche", systemImage: "magnifyingglass") }
                .tag(Selection.newSearch)
                .playbackBottomSheet(animateContent: $animateContent,
                                     animation: animation)
            SearchView()
                .tabItem { Label("Alte Suche", systemImage: "magnifyingglass") }
                .tag(Selection.search)
                .playbackBottomSheet(animateContent: $animateContent,
                                     animation: animation)
        }
        .toolbar(.visible, for: .tabBar)
    }
}
