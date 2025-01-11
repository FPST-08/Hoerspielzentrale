//
//  DetailPlayButtonStyle.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 11.01.25.
//

import SwiftUI

/// A `ButtonStyle` used in ``HoerspielDetailView``
struct DetailPlayButtonStyle: ButtonStyle {
    
    /// The function that returns the button
    /// - Parameter configuration: A configuration from the button
    /// - Returns: Returns the button as a view
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .foregroundStyle(Material.regular)
            configuration.label
                .fontWeight(.medium)
                .foregroundStyle(Color.accentColor)
                .padding(.vertical, 10)
        }
        .padding(.vertical, 15)
    }
}
