//
//  CoverSizeModifier.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 15.11.24.
//

import SwiftUI

/// A view modifier to size the cover in the ``PlaybackSheet`` correctly
struct CoverSizeModifier: ViewModifier {
    
    /// The current orientation of the device
    @State private var orientation = UIDeviceOrientation.unknown
    
    /// The calculated with of the cover
    var width: Double {
        if UIDevice.current.userInterfaceIdiom == .pad {
            if orientation == .landscapeLeft || orientation == .landscapeRight {
                return UIScreen.main.bounds.width * 0.4
            } else {
                return UIScreen.main.bounds.height * 0.5
            }
        } else {
            return UIScreen.main.bounds.width * 0.9
        }
    }
    
    func body(content: Content) -> some View {
        content
            .frame(width: width, height: width)
            .onRotate { orientation in
                self.orientation = orientation
            }
    }
}

extension View {
    /// Adjusts the width and height of the cover  in the ``PlaybackSheet``
    func coverFrame() -> some View {
        modifier(CoverSizeModifier())
    }
}

/// A view modifier to size the controls in the ``PlaybackSheet`` correctly
struct PlayerViewSizeModifier: ViewModifier {
    
    /// The current orientation of the device
    @State private var orientation = UIDeviceOrientation.unknown
    
    /// The calculated with of the controls
    var width: Double {
        if UIDevice.current.userInterfaceIdiom == .pad {
            if orientation == .landscapeLeft || orientation == .landscapeRight {
                return min(UIScreen.main.bounds.width * 0.4, UIScreen.main.bounds.height * 0.6)
            } else {
                return UIScreen.main.bounds.height * 0.5
            }
        } else {
            return UIScreen.main.bounds.width * 0.9
        }
    }
    
    func body(content: Content) -> some View {
        content
            .frame(width: width)
            .onRotate { orientation in
                self.orientation = orientation
            }
    }
}

extension View {
    /// Adjusts the width of the controls in the ``PlaybackSheet``
    func playerViewSize() -> some View {
        modifier(PlayerViewSizeModifier())
    }
}
