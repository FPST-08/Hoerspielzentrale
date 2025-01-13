//
//  Defaults.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 13.12.24.
//

import Defaults

extension Defaults.Keys {
    static let sortFilter = Key<SortingType>("SortFilter", default: SortingType.releaseDate)
    
    static let displayedSortArtists = Key<[SendableSeries]>("DisplayedSortArtists", default: [])
    
    static let sendNotificationsForPreRelease = Key<Bool>("SendNotificationsForPreRelease", default: true)
    
    static let seriesWithDiabledNotifications = Key<[SendableSeries]>("SeriesWithDisabledNotifications", default: [])
    
    static let notificationsEnabled = Key<Bool>("NotificationsEnabled", default: true)
    
    static let timesPlaybackStarted = Key<Int>("TimesPlaybackStarted", default: 0)
}

/// An enum used for communicating the sorting property
enum SortingType: Codable, Defaults.Serializable {
    case duration
    case releaseDate
    case title
    case lastPlayed
}
