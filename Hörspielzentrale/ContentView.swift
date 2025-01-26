//
//  ContentView.swift
//  diedreifragezeichenplayer
//
//  Created by Philipp Steiner on 14.04.24.
//

import BackgroundTasks
import Combine
import MediaPlayer
import MusicKit
import OSLog
import SwiftUI

/// The entry view of the app
struct ContentView: View {
    // MARK: - Properties
    
    /// Referencing an `Observable` class responsible for playback
    @Environment(MusicManager.self) var musicmanager
    
    /// The namespace of all animations related to the ``customBottomSheet()`` and ``ExpandBottomSheet`
    @Namespace private var animation
    /// An Observable Class responsible for navigation
    @Environment(NavigationManager.self) var navigation
    
    /// A boolean that indicates a currently running animation
    @State private var animateContent = false
    
    // MARK: - View
    var body: some View {
        TabView(selection: Bindable(navigation).selection) {
            HomeView()
                .tabItem { Label("Startseite", systemImage: "house.fill") }
                .tag(Selection.home)
            
            LibraryView()
                .tabItem { Label("Mediathek", systemImage: "play.square.stack")}
                .tag(Selection.library)
            
            SearchView()
                .tabItem { Label("Suche", systemImage: "magnifyingglass") }
                .tag(Selection.search)
        }
        .safeAreaInset(edge: .bottom) {
            if !navigation.searchPresented || !navigation.presentMediaSheet {
                customBottomSheet()
            }
        }
        .overlay {
            if navigation.presentMediaSheet {
                PlaybackSheet(animation: animation,
                              animateContent: $animateContent)
                .transition(.asymmetric(insertion: .identity, removal: .offset(y: -5)))
                .environment(\.dynamicTypeSize, .large)
            }
        }
        .alert(isPresented: Bindable(navigation).searchPresented) {
            Alert(
                title: Text(navigation.alertTitle),
                message: navigation.alertDescription != nil ? Text(navigation.alertDescription!) : nil)
        }
        .sheet(isPresented: Bindable(navigation).showSeriesAddingSheet) {
            NavigationStack {
                SeriesSelectionView {
                    navigation.showSeriesAddingSheet = false
                }
            }
        }
        .musicSubscriptionSheet(isPresented: Bindable(navigation).musicSubscriptionSheetPresented,
                                itemID: navigation.musicItemID)
        
    }
    
    // MARK: - Functions
    
    /// Creation of the botton sheet seen at the bottom screen
    /// - Returns: Returns the view of the bottom Sheet
    @ViewBuilder
    func customBottomSheet() -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: animateContent ? deviceCornerRadius : 15)
                .fill(Color.systemGray4)
                .shadow(radius: 3)
                .padding(.horizontal, 10)
                .overlay {
                    MusicInfo(animateContent: $animateContent,
                              artwork: Image(musicmanager.currentlyPlayingHoerspielCover),
                              applyArtworkMGE: true,
                              animation: animation)
                }
        }
        .matchedGeometryEffect(id: "BGVIEW", in: animation)
        .frame(height: 60)
        .offset(y: bottomSheetOffset)
    }
    
    /// The offset of the bottomSheet
    var bottomSheetOffset: CGFloat {
        if !UIDevice.isIpad {
            return -49
        }
        if UIScreen.safeArea?.bottom == 0 {
            return -10
        } else {
            return 0
        }
    }
}
