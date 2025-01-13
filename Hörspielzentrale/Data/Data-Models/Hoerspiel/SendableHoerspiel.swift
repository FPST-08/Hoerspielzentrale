//
//  SendableHoerspiel.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 04.09.24.
//

import Foundation
import SwiftData

/// A struct that is used to safely pass around a ``Hoerspiel``
struct SendableHoerspiel: Sendable, Hashable, Codable, Identifiable {
    /// The title of the hoerspiel
    var title: String
    
    /// The albumID of the hoerspiel
    ///
    ///  The value looks similiar to  `1092529875`. It consists of numbers only but is returned and treated as a string.
    var albumID: String
    
    /// Indicates whether or not a ``Hoerspiel`` was played to the end
    ///
    /// This can be set manually by the user or automatically when the playback finished
    var played: Bool = false
    
    /// Indicates when the playback for a  ``Hoerspiel`` was initiated
    var lastPlayed: Date = Date.distantPast
    
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
    var duration: TimeInterval
    
    /// A date that represents the release date of the hoerspiel
    ///
    /// - Note: This is not necessarily the date fetched from the Apple Music API.
    /// It can also be fetched from dreimetadaten.de
    var releaseDate: Date
    
    /// A string that represents the name of the artist that published that hoerspiel
    var artist: String
    
    /// A `persistentIdentifier` that represents the `persistentModelID`of the corresponding hoerspiel
    var persistentModelID: PersistentIdentifier
    
    /// The persistentModelID rebranded as an ID to conform to `Identifiable`
    var id: PersistentIdentifier {
        return persistentModelID
    }
    
    /// The Universal Product Code for the Hoerspiel
    var upc: String
    
    /// The tracks for the Hoerspiel
    var tracks: [SendableStoredTrack]
    
    var series: SendableSeries?
    
    /// Creates a ``SendableHoerspiel``manually using standard data types and a `persistentIdentifier`
    /// - Parameters:
    ///   - title: The title of the hoerspiel
    ///   - albumID: The id of the corresponding album from MusicKit as a String
    ///   - played: A boolean that indicates whether this hoerspiel has previously been played til the end
    ///   - lastPlayed: A date that indicates when the playback was last initiated for that hoerspiel
    ///   - playedUpTo: An Integer that indicates how far the hoerspiel was played to
    ///   - showInUpNext: A boolean that indicates whether the hoerspiel is shown in the `Up Next` Section
    ///   - duration: A timeinterval that represents the total duration of the hoerspiel
    ///   - releaseDate: A date that represents the release date of the hoerspiel
    ///   - artist: A string that represents the name of the artist that published that hoerspiel
    ///   - persistentModelID: A `persistentIdentifier` that represents
    ///   the `persistentModelID` of the corresponding hoerspiel
    ///   - upc: The Universal Product Code for the Hoerspiel
    ///   - tracks: The stored tracks of the ``SendableHoerspiel``
    ///   - series: The series of the ``SendableHoerspiel``
    /// - Note: A `persistentIdentifier` can not be created from other data types or decoded
    init(title: String,
         albumID: String,
         played: Bool,
         lastPlayed: Date,
         playedUpTo: Int,
         showInUpNext: Bool,
         addedToUpNext: Date = Date.distantPast,
         duration: TimeInterval,
         releaseDate: Date,
         artist: String,
         persistentModelID: PersistentIdentifier,
         upc: String,
         tracks: [SendableStoredTrack],
         series: SendableSeries?
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
        self.persistentModelID = persistentModelID
        self.upc = upc
        self.tracks = tracks
        self.series = series
    }
    
    /// Creates a ``SendableHoerspiel`` from a ``Hoerspiel`` that can safely be passed around.
    /// - Parameter hoerspiel: This is the original source of truth that gets copied
    init(hoerspiel: Hoerspiel) {
        self.title = hoerspiel.title
        self.albumID = hoerspiel.albumID
        self.played = hoerspiel.played
        self.lastPlayed = hoerspiel.lastPlayed
        self.playedUpTo = hoerspiel.playedUpTo
        self.showInUpNext = hoerspiel.showInUpNext
        self.addedToUpNext = hoerspiel.addedToUpNext
        self.duration = hoerspiel.duration
        self.releaseDate = hoerspiel.releaseDate
        self.artist = hoerspiel.artist
        self.persistentModelID = hoerspiel.persistentModelID
        self.upc = hoerspiel.upc
        self.tracks = hoerspiel.tracks?.compactMap( { SendableStoredTrack($0)}) ?? []
        if let series = hoerspiel.series {
            self.series = SendableSeries(series)
        } else {
            assertionFailure()
            self.series = nil
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: SendableHoerspiel, rhs: SendableHoerspiel) -> Bool {
        lhs.id == rhs.id
    }
    
}

extension SendableHoerspiel {
    static var example = SendableHoerspiel(hoerspiel: Hoerspiel.example)
}
