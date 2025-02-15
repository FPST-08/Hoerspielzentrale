//
//  CustomBottomSheet.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 15.02.25.
//

import SwiftUI

/// The bottom sheet
struct CustomBottomSheet: View {
    /// A boolean that indicates a currently running animation
    @Binding var animateContent: Bool
    
    /// The namespace of all animations related to the ``customBottomSheet()`` and ``ExpandBottomSheet`
    let animation: Namespace.ID
    
    /// Referencing an `Observable` class responsible for playback
    @Environment(MusicManager.self) var musicmanager
    
    var body: some View {
        RoundedRectangle(cornerRadius: animateContent ? deviceCornerRadius : 15)
            .matchedGeometryEffect(id: "BGVIEW", in: animation)
            .foregroundStyle(Color.systemGray4)
            .shadow(radius: 3)
            .padding(.horizontal, 10)
            .overlay {
                MusicInfo(animateContent: $animateContent,
                          artwork: Image(musicmanager.currentlyPlayingHoerspielCover),
                          applyArtworkMGE: true,
                          animation: animation)
            }
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

/// The bottom sheet modifier
struct CustomBottomSheetViewModifier: ViewModifier {
    
    /// An Observable Class responsible for navigation
    @Environment(NavigationManager.self) var navigation
    
    @Binding var animateContent: Bool
    
    let animation: Namespace.ID
    
    /// A condition to apply this modifier
    let condition: Bool
    
    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom) {
                if (!navigation.searchPresented || !navigation.presentMediaSheet) && condition {
                    CustomBottomSheet(animateContent: $animateContent,
                                      animation: animation)
                }
            }
    }
}

extension View {
    func playbackBottomSheet(animateContent: Binding<Bool>,
                             animation: Namespace.ID,
                             condition: Bool = true
    ) -> some View {
        modifier(CustomBottomSheetViewModifier(
            animateContent: animateContent,
            animation: animation,
            condition: condition))
    }
}
