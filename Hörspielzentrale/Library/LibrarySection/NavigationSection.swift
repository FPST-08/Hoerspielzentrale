//
//  NavigationSection.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 18.10.24.
//

import SwiftUI

/// A header used to navigate to the ``ListView``
struct NavigationSection: View {
    // MARK: - Properties
    
    /// The hoerspiele displayed in the ``ListView``
    let hoerspiele: [SendableHoerspiel]
    
    /// The title of the section
    let title: String
    
    // MARK: - View
    var body: some View {
        NavigationLink {
            ListView(hoerspiele: hoerspiele)
                .navigationTitle(title)
        } label: {
            HStack(spacing: 5) {
                Text(title)
                    .foregroundStyle(Color.primary)
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundStyle(Color.primary.opacity(0.5))
                Spacer()
            }
            .padding(.leading, 15)
            .fontWeight(.bold)
            .font(.title2)
            .padding(.top, 5)
        }
    }
}
