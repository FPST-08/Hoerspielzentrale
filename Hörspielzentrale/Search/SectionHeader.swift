//
//  SectionHeader.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 11.12.24.
//

import SwiftUI

/// A view to indicate a Section with a link to another view
struct SectionHeaderLink<Content: View>: View {
    // MARK: - Properties
    /// The title of the section
    let title: String
    
    /// The destination to navigate to
    @ViewBuilder let destination: Content
    
    // MARK: - View
    var body: some View {
        NavigationLink {
            destination
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

/// A view to indicate a Section
struct SectionHeader: View {
    // MARK: - Properties
    
    /// The title of the section
    let title: String
    
    // MARK: . View
    var body: some View {
        HStack(spacing: 5) {
            Text(title)
                .foregroundStyle(Color.primary)
            Spacer()
        }
        .padding(.leading, 15)
        .fontWeight(.bold)
        .font(.title2)
        .padding(.top, 5)
    }
}
