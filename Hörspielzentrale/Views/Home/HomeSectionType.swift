//
//  HomeSectionType.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 17.02.25.
//

import Defaults

/// The home section types
enum HomeSectionType: Codable, Defaults.Serializable, Identifiable {
    /// The id of the enum
    var id: Self {
        return self
    }
    
    case recentlyReleased, soonAvailable, brandNew, recentlyPlayed
    
    /// All types of the enum
    var allTypes: [HomeSectionType] {
        [.recentlyReleased, .soonAvailable, .brandNew, .recentlyPlayed]
    }
    
    /// The textual representation of the enum used for reordering
    var description: String {
        switch self {
        case .recentlyReleased:
            return "Neuheiten"
        case .soonAvailable:
            return "Bald verfügbar"
        case .brandNew:
            return "Neu erschienen"
        case .recentlyPlayed:
            return "Zuletzt gespielt"
        }
    }
}
