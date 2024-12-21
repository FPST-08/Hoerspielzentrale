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
}
