//
//  MusicSubscriptionSheet.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 10.08.24.
//

import Foundation
import MusicKit
import SwiftUI

extension View {
    /// Streamlines the presentation of a `musicSubscriptionOffer`
    /// - Parameters:
    ///   - isPresented: Boolean Binding to show and hide sheet
    ///   - itemID: `itemID` of item that should be presented`
    /// - Returns: Returns a view with attached modifier
    /// - Note: itemID can be nil in which case standard apple music graphics will be displayed
    func musicSubscriptionSheet(isPresented: Binding<Bool>, itemID: MusicItemID?) -> some View {
        modifier(MusicSubscriptionSheet(isPresented: isPresented, itemID: itemID))
    }
}
/// Viewmodifier-Struct of `musicSubscriptionSheet`
struct MusicSubscriptionSheet: ViewModifier {
    /// Boolean Binding to show and hide sheet
    @Binding var isPresented: Bool
    /// `itemID` of item that should be presented
    let itemID: MusicItemID?
    
    func body(content: Content) -> some View {
        content
            .musicSubscriptionOffer(isPresented: $isPresented, options: MusicSubscriptionOffer.Options(itemID: itemID))
    }
}
