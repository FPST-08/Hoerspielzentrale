//
//  VolumeExtensions.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 18.06.24.
//

import Foundation
import MediaPlayer
import OSLog
import SwiftUI
import UIKit

/// A `View-Modifier`to hide the volume HUD
struct VolumeViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            VolumeView()
                .frame(width: 0, height: 0)
            content
        }
    }
    
    struct VolumeView: UIViewRepresentable {
        func makeUIView(context: Context) -> MPVolumeView {
            let volumeView = MPVolumeView(frame: CGRect.zero)
            volumeView.alpha = 0.001
            return volumeView
        }
        func updateUIView(_ uiView: MPVolumeView, context: Context) { }
    }
}
extension View {
    /// Hides the volume HUD
    /// - Returns: Returns the view with an invisible `MPVolumeView` to hide the volume HUD
    func hideVolumeHUD() -> some View {
        modifier(VolumeViewModifier())
    }
}

/// Sets the volume to a specified value
/// - Parameter value: The value to set the volume to
///
/// - Note: The volume is specifed from 0 to 1
func setVolume(to value: Double) {
    
    DispatchQueue.main.async {
        let logger = Logger(subsystem: "Hörspielzentrale", category: "Volume")
        let volumeView = MPVolumeView()
        
        let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.03) {
            
            slider?.setValue(Float(value), animated: false)
            
            logger.info("Value should have changed to \(value) now")
//            action()
            
        }
    }
    
}
