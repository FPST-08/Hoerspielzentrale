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
        ContentTabView(animateContent: $animateContent)
            .playbackBottomSheet(animateContent: $animateContent,
                                 animation: animation,
                                 condition: UIDevice.runsIOS18OrNewer)
        .overlay {
            if navigation.presentMediaSheet {
                PlaybackSheet(animation: animation,
                              animateContent: $animateContent)
                .transition(.asymmetric(insertion: .identity, removal: .offset(y: -5)))
                .environment(\.dynamicTypeSize, .large)
            }
        }
        .alert(navigation.alertTitle, isPresented: Bindable(navigation).alertPresented) {
            Button("Ok", role: .cancel, action: { })
        } message: {
            Text(navigation.alertDescription ?? "")
        }
        .musicSubscriptionSheet(isPresented: Bindable(navigation).musicSubscriptionSheetPresented,
                                itemID: navigation.musicItemID)
        .onScrubbing {
            Task {
                await musicmanager.calculateDatesWhilePlaying()
            }
        }
    }
}
