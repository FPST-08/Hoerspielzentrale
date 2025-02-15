//
//  ContentTabView.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 13.02.25.
//

import Defaults
import SwiftData
import SwiftUI

/// A wrapper for both options of tab views
struct ContentTabView: View {
    
    /// A boolean that indicates a currently running animation
    @Binding var animateContent: Bool
    
    /// The namespace of all animations related to the ``customBottomSheet()`` and ``ExpandBottomSheet`
    @Namespace private var animation
    
    var body: some View {
        if #available(iOS 18, *) {
            ContentTabCurrentView(animateContent: $animateContent,
                                  animation: animation)
            
        } else {
            ContentTabLegacyView(animateContent: $animateContent,
                                 animation: animation)
        }
    }
}
