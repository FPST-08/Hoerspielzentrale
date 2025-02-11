//
//  HoerspielInformationView.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 12.12.24.
//

import MusicKit
import SwiftUI

/// A view used to display Information
struct DetailsInfoView: View {
    // MARK: - Properties
    /// All info entries
    var entries = [DetailsInfoDisplay]()
    
    // MARK: - View
    var body: some View {
        VStack {
            SectionHeader(title: "Informationen")
            ForEach(entries) { entry in
                if entries.firstIndex(where: { $0.id == entry.id }) != 0 {
                    Divider()
                }
                HStack {
                    Text(entry.title)
                    Spacer()
                    switch entry.type {
                    case .link(let link):
                        Link(entry.value, destination: link)
                    case .plain:
                        Text(entry.value)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    /// Creates the view from a hoerspiel and any other additional entries
    /// - Parameters:
    ///   - hoerspiel: The hoerspiel
    ///   - entries: The additional entries
    init(
        hoerspiel: SendableHoerspiel,
        entries: [DetailsInfoDisplay] = [DetailsInfoDisplay]()
    ) {
        self.entries = [
            DetailsInfoDisplay(title: "Serie",
                                 value: hoerspiel.artist),
            DetailsInfoDisplay(title: "Erscheinungsdatum",
                                 value: hoerspiel.releaseDate.formatted(date: .long, time: .shortened)),
            DetailsInfoDisplay(title: "Dauer",
                                 value: hoerspiel.duration.formattedDuration()),
            DetailsInfoDisplay(title: "Zuletzt gespielt",
                                 value: hoerspiel.lastPlayed == Date.distantPast
                                 ? "Nie"
                                 : hoerspiel.lastPlayed.formatted(date: .long, time: .shortened))
        ]
        self.entries.append(contentsOf: entries)
    }
    
    /// Creates the view from additional entries
    /// - Parameter entries: The entries
    init(entries: [DetailsInfoDisplay]) {
        self.entries = entries
    }
}

/// A struct for ``HoerspielInfoView``
struct DetailsInfoDisplay: Identifiable {
    /// The title of the entry
    let title: String
    
    /// The label value of the entry
    let value: String
    
    /// The type of the entry
    var type: Variant
    
    /// A UUID to conform to Identifable
    let id = UUID()
    
    /// The variants of an entry
    enum Variant {
        case plain
        case link(link: URL)
    }
    
    init(
        title: String,
        value: String,
        type: Variant = .plain
    ) {
        self.title = title
        self.value = value
        self.type = type
    }
}
