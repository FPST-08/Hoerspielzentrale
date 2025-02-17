//
//  LibraryInlineSection.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 16.02.25.
//

import SwiftUI

/// A view to display an inline section in the library
struct LibraryInlineSection<Content: View>: View {
    
    /// The title of the section
    let title: String
    
    /// The system image of the section
    let systemImage: String
    
    /// The view to linkt to
    @ViewBuilder let content: Content
    
    var body: some View {
        NavigationLink {
            content
        } label: {
            VStack {
                HStack {
                    Image(systemName: systemImage)
                    Text(title)
                        .foregroundStyle(Color.primary)
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Color.secondary)
                        .font(.body)
                }
                .font(.title2)
                .padding(.horizontal)
                Divider()
            }
        }
    }
}
