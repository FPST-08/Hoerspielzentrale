//
//  ProgressCapsuleView.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 22.06.24.
//

import SwiftUI

/// A tiny view that indicates playback process
struct ProgressCapsuleView: View {
    // MARK: Properties
    /// The fraction that was already fulfilled
    /// - Important: Progress should always be between 0 and 1. Other values will cause undefined behaviour
    let progress: Double
    
    /// The color of the fulfilled portion of the Capsule
    let color: Color
    
    // MARK: - View
    var body: some View {
        HStack {
            ZStack(alignment: .center) {
                Capsule()
                    .fill(.progressCapsuleBackground)
                
                Capsule()
                
                    .fill(color)
                
                    .mask({
                        HStack {
                            Rectangle()
                            
                                .frame(width: progress * 20, alignment: .leading)
                            
                            Spacer(minLength: 0)
                        }
                    })
            }
            .frame(width: 20, height: 5)
        }
        
    }
    
    /// Initializes the  ProgressCapsuleView
    /// - Important: Progress should always be between 0 and 1. Other values will cause undefined behaviour
    /// - Parameters:
    ///   - progress: The fraction that was already fulfilled.
    ///   - color: The color of the fulfilled portion of the Capsule
    init(progress: Double, color: Color) {
        self.progress = progress
        self.color = color
    }
}
