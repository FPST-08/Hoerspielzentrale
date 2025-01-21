//
//  NavigationSection.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 18.10.24.
//

import SwiftData
import SwiftUI

/// A header used to navigate to the ``ListView``
struct NavigationSection: View {
    // MARK: - Properties
    
    let destination: Destination
    
    /// The title of the section
    let title: String
    
    // MARK: - View
    var body: some View {
        NavigationLink {
            switch destination {
            case .hoerspielList(let hoerspiele):
                ListView(hoerspiele: hoerspiele)
                                .navigationTitle(title)
            case .series(let series):
                SeriesDetailView(series: series)
            case .allHoerspiels(let series):
                AllHoerspielsView(series: series)
            }
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
            .padding(.top, 10)
        }
    }
    
    /// The destination of the `NavigationLink`
    enum Destination {
        case hoerspielList(hoerspiele: [SendableHoerspiel])
        case series(series: SendableSeries)
        case allHoerspiels(series: SendableSeries)
    }
}
