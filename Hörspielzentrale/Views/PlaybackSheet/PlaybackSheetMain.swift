//
//  PlaybackSheetMain.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 26.01.25.
//

import SwiftUI

/// A view that wraps all foreground views of the playback sheet
struct PlaybackSheetMain: View {
    
    /// A bool indicating a currently running animation
    @Binding var animateContent: Bool
    
    /// The namespace for animations
    let animation: Namespace.ID
    
    /// The background color
    let backgroundColor: Color
    
    @Environment(\.safeAreaInsets) var safeAreaInsets
    
    var body: some View {
        VStack(spacing: 15) {
            Capsule()
                .fill(.gray)
                .frame(width: 40, height: 5)
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : UIScreen.main.bounds.height)
            PlaybackCoverView(animation: animation)
            PlaybackPlayerView(backgroundColor: backgroundColor)
            .offset(y: animateContent ? 0 : UIScreen.main.bounds.height)
        }
        
        .padding(.top, safeAreaInsets.top + (safeAreaInsets.bottom == 0 ? 10 : 0))
        .padding(.bottom, safeAreaInsets.bottom == 0 ? 10 : safeAreaInsets.bottom)
        .padding(.horizontal, 25)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .clipped()
        .onAppear {
            withAnimation(.easeInOut(duration: 0.30)) {
                animateContent = true
            }
        }
    }
}
