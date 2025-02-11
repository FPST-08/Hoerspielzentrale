//
//  SearchResult.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 10.02.25.
//

import Defaults
import Foundation
import MusicKit

/// The search results
enum SearchResult: Codable, Defaults.Serializable, Hashable {
    case series(SendableSeries)
    case hoerspiel(SendableHoerspiel)
    case artist(Artist)
    case album(Album)
    
    /// Creates the search result from a hoerspiel
    /// - Parameter hoerspiel: The hoerspiel
    init(_ hoerspiel: SendableHoerspiel) {
        self = .hoerspiel(hoerspiel)
    }
    
    /// Creates a search result from a series
    /// - Parameter series: The series
    init(_ series: SendableSeries) {
        self = .series(series)
    }
    
    /// Creates a search result from an artist
    /// - Parameter artist: The artist
    init(_ artist: Artist) {
        self = .artist(artist)
    }
    
    /// Creates a search result from an album
    /// - Parameter album: The album
    init(_ album: Album) {
        self = .album(album)
    }
    
    /// The title of self
    var title: String {
        switch self {
        case .series(let series):
            return series.name
        case .hoerspiel(let hoerspiel):
            return hoerspiel.title
        case .artist(let artist):
            return artist.name
        case .album(let album):
            return album.title
        }
    }
    
    /// The id of self
    var id: String {
        switch self {
        case .series(let series):
            return series.id
        case .hoerspiel(let hoerspiel):
            return hoerspiel.albumID
        case .artist(let artist):
            return artist.id.rawValue
        case .album(let album):
            return album.id.rawValue
        }
    }
}
