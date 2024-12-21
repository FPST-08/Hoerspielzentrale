//
//  DetailPlayButtonStyle.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 21.08.24.
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

/// A button style used for big primary buttons
struct PrimaryButtonStyle: ButtonStyle {
    /// Indicating if the button should be indicating a loading state
    let loading: Bool
    
    /// The color of the button
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        Group {
            HStack {
                Spacer()
                
                if !loading {
                    configuration
                        .label
                        .font(.headline.weight(.semibold))
                        .padding(.vertical)
                } else {
                    ProgressView()
                        .font(.headline.weight(.semibold))
                        .padding(.vertical)
                }
                
                Spacer()
            }
        }
        .foregroundColor(.white)
        .background(loading ? .gray : color)
        .cornerRadius(14)
        .opacity(loading || configuration.isPressed ? 0.5 : 1)
        .opacity(configuration.isPressed ? 0.5 : 1)
    }
    
    init(
        loading: Bool,
        color: Color = Color(UIColor(red: 44/256, green: 44/256, blue: 46/256, alpha: 1))
    ) {
        self.loading = loading
        self.color = color
    }
}
