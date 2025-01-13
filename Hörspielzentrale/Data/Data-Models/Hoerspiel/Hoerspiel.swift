//
//  Hoerspiel.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 04.09.24.
//

import Foundation
import SwiftData

/// A class used to save Hoerspiele in SwiftData
@Model
final class Hoerspiel: Hashable, Identifiable {
    /// The title of the hoerspiel
    var title: String = "N/A"
    
    /// The albumID of the hoerspiel
    ///
    ///  The value looks similiar to  `1092529875`. It consists of numbers only
    ///  but is returned and treated as a string.
    var albumID: String = ""
    
    /// Indicates whether or not a ``Hoerspiel`` was played to the end
    ///
    /// This can be set manually by the user or automatically when the playback finished
    var played: Bool = false
    
    /// Indicates when the playback for a  ``Hoerspiel`` was initiated
    var lastPlayed: Date = Date.now
    
    /// An Integer that indicates how far the hoerspiel was played up to
    var playedUpTo: Int = 0
    
    /// A boolean that indicates whether the hoerspiel is shown in the `Up Next` Section
    ///
    /// This can be set manually by the user.
    /// - Note: Initiating a playback always sets this to `true`
    var showInUpNext: Bool = false
    
    /// The date this ``Hoerspiel`` was added to up next
    ///
    /// This is used to set the order for up next
    var addedToUpNext: Date = Date.distantPast
    
    /// A timeinterval that represents the total duration of the hoerspiel in seconds
    var duration: TimeInterval = 0
    
    /// A date that represents the release date of the hoerspiel
    ///
    /// - Note: This is not necessarily the date fetched from the Apple Music API.
    ///         It can also be fetched from dreimetadaten.de
    var releaseDate: Date = Date.now
    
    /// A string that represents the name of the artist that published that hoerspiel
    var artist: String = ""
    
    /// The Universal Product Code for the Hoerspiel
    var upc: String = ""
    
    @Relationship(deleteRule: .cascade, inverse: \StoredTrack.hoerspiel) var tracks: [StoredTrack]? = []
    
    var series: Series?
    
    /// Creates a ``Hoerspiel`` manually using standard data types
    init(title: String = "N/A",
         albumID: String = "",
         played: Bool = false,
         lastPlayed: Date = Date.now,
         playedUpTo: Int = 0,
         showInUpNext: Bool = false,
         addedToUpNext: Date = Date.distantPast,
         duration: TimeInterval = 0,
         releaseDate: Date = Date.now,
         artist: String = "",
         upc: String = "",
         tracks: [StoredTrack] = [],
         series: Series?
    ) {
        self.title = title
        self.albumID = albumID
        self.played = played
        self.lastPlayed = lastPlayed
        self.playedUpTo = playedUpTo
        self.showInUpNext = showInUpNext
        self.addedToUpNext = addedToUpNext
        self.duration = duration
        self.releaseDate = releaseDate
        self.artist = artist
        self.upc = upc
        self.tracks = tracks
        self.series = series
    }
    
    /// Creates a ``Hoerspiel`` from a ``SendableHoerspiel``
    init(from sendable: SendableHoerspiel, series: Series?) {
        self.title = sendable.title
        self.albumID = sendable.albumID
        self.upc = sendable.upc
        self.played = sendable.played
        self.lastPlayed = sendable.lastPlayed
        self.playedUpTo = sendable.playedUpTo
        self.showInUpNext = sendable.showInUpNext
        self.addedToUpNext = sendable.addedToUpNext
        self.duration = sendable.duration
        self.releaseDate = sendable.releaseDate
        self.artist = sendable.artist
        self.tracks = sendable.tracks.compactMap { StoredTrack($0) }
        self.series = series
    }
    
    /// Creates a ``Hoerspiel`` from a ``CodableHoerspiel``
    /// - Parameter codableHoerspiel: The original ``CodableHoerspiel``
    init(_ codableHoerspiel: CodableHoerspiel) {
        self.title = codableHoerspiel.title
        self.albumID = codableHoerspiel.albumID
        self.played = codableHoerspiel.played
        self.lastPlayed = codableHoerspiel.lastPlayed
        self.playedUpTo = codableHoerspiel.playedUpTo
        self.showInUpNext = false
        self.addedToUpNext = Date.distantPast
        self.duration = codableHoerspiel.duration
        self.releaseDate = codableHoerspiel.releaseDate
        self.artist = codableHoerspiel.artist
        self.upc = codableHoerspiel.upc
        self.tracks = []
    }
}

extension Hoerspiel {
    static var example = Hoerspiel(title: "Folge 17: Rettet Atlantis!",
                                   albumID: "1092526143",
                                   played: false,
                                   lastPlayed: Date.distantPast,
                                   playedUpTo: 0,
                                   showInUpNext: false,
                                   addedToUpNext: Date.distantPast,
                                   duration: 4725.989000000001,
                                   releaseDate: Date(timeIntervalSince1970: 1285891200),
                                   artist: "Die drei ??? Kids",
                                   upc: "886445747867",
                                   tracks: [],
                                   series: Series.example)
}
