//
//  ExpandBottomSheet.swift
//  diedreifragezeichenplayer
//
//  Created by Philipp Steiner on 18.04.24.
//

import MediaPlayer
import MusicKit
import OSLog
import SwiftData
import SwiftUI
import TelemetryDeck

/// A full screen sheet used to control a running playback
struct PlaybackSheet: View {
    // MARK: - Properties
    /// The animation namespace of the animation
    var animation: Namespace.ID
    /// A bool indicating a running animation
    @Binding var animateContent: Bool
    /// The current offset of the entire sheet caused by pulling
    @State private var offsetY: CGFloat = 0
    /// An Observable Class responsible for data
    @Environment(DataManagerClass.self) var dataManager
    /// Referencing an `Observable` class responsible for playback
    @Environment(MusicManager.self) var musicManager
    /// An Observable Class responsible for navigation
    @Environment(NavigationManager.self) var navigation
    /// The current playback state
    @ObservedObject var state = ApplicationMusicPlayer.shared.state
    /// The backgroundColor of the ``Hoerspiel`` Cover used as the overall background
    var backgroundColor: Color {
        if let bgColor = musicManager.currentlyPlayingHoerspielCover?.averageColor {
            return Color(bgColor)
        } else {
            return Color.systemGray4
        }
    }
    /// Current playback progress in seconds
    @State private var progressValue = 0.0
    
    @Environment(\.colorScheme) var colorScheme
    
    // MARK: - View
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: animateContent ? deviceCornerRadius : 0, style: .continuous)
                .foregroundStyle(Color.clear)
            
            Rectangle()
            
                .fill(.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: animateContent ? deviceCornerRadius : 0, style: .continuous)
                        .fill(Color.systemBackground)
                )
                .overlay(
                    ZStack {
                        RoundedRectangle(cornerRadius: animateContent ? deviceCornerRadius : 0, style: .continuous)
                            .fill(backgroundColor)
                            .opacity(animateContent ? 1 : 0)
                        
                        RoundedRectangle(cornerRadius: animateContent ? deviceCornerRadius : 0, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .opacity(animateContent ? 1 : 0)
                    }
                )
                .overlay(alignment: .top) {
                    ZStack {
                        RoundedRectangle(cornerRadius: animateContent ? deviceCornerRadius : 15)
                            .fill(.ultraThickMaterial)
                            .shadow(radius: 3)
                            .padding(.horizontal, 10)
                        MusicInfo(
                            animateContent: $animateContent,
                            artwork: Image(musicManager.currentlyPlayingHoerspielCover), applyArtworkMGE: false,
                            animation: animation)
                    }
                    .frame(height: 60)
                    .allowsTightening(false)
                    .opacity(animateContent ? 0 : 1)
                }
                .matchedGeometryEffect(id: "BGVIEW", in: animation)
            PlaybackSheetMain(animateContent: $animateContent,
                              animation: animation,
                              backgroundColor: backgroundColor)
            
        }
        .contentShape(Rectangle())
        .offset(y: offsetY)
        .gesture(
            DragGesture(minimumDistance: 20)
                .onChanged( { value in
                    
                    let translationY = value.translation.height
                    offsetY = (translationY > 0 ? translationY : 0)
                }).onEnded( { _ in
                    withAnimation(.easeInOut(duration: 0.30)) {
                        if offsetY > UIScreen.main.bounds.height * 0.2 {
                            navigation.presentMediaSheet = false
                            animateContent = false
                        } else {
                            offsetY = .zero
                        }
                    }
                })
        )
        .ignoresSafeArea(.container, edges: .all)
        .trackNavigation(path: "PlaybackSheet")
    }
}

extension Color {
    /// Returns a color used for the playback controls
    /// - Parameter colorScheme: the current ColorScheme in the view
    /// - Returns: Returns the color for the playback controls
    func playbackControlColor(colorScheme: ColorScheme) -> Color {
        if colorScheme == .dark {
            return .white
        } else {
            return self.adaptedTextColor()
        }
    }
}
