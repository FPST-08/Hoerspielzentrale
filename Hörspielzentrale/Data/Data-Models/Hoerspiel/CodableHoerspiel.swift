//
//  DataModel.swift
//  diedreifragezeichenplayer
//
//  Created by Philipp Steiner on 02.04.24.
//
import Foundation
import MusicKit

/// A struct ueed to do  decode Hoerspiele from `JSON`
///
/// It includes all properties that are not user-specific
struct CodableHoerspiel: Codable {
    /// The title of the hoerspiel
    var title: String = "N/A"
    
    /// The albumID of the hoerspiel
    ///
    ///  The value looks similiar to  `1092529875`. It consists of numbers only but is returned and treated as a string.
    var albumID: String = ""
    
    /// A timeinterval that represents the total duration of the hoerspiel in seconds
    var duration: TimeInterval = 0
    
    /// A date that represents the release date of the hoerspiel
    ///
    /// - Note: This is not necessarily the date fetched from the Apple Music API.
    /// It can also be fetched from dreimetadaten.de
    var releaseDate: Date
    
    /// A string that represents the name of the artist that published that hoerspiel
    var artist: String
    
    /// The Universal Product Code for the Hoerspiel
    var upc: String
    
    /// Indicates when the playback for a  ``Hoerspiel`` was initiated
    var lastPlayed: Date
    
    /// An Integer that indicates how far the hoerspiel was played up to
    var playedUpTo: Int
    
    /// Indicates whether or not a ``Hoerspiel`` was played to the end
    ///
    /// This can be set manually by the user or automatically when the playback finished
    var played: Bool
    
    /// Creates a ``CodableHoerspiel`` manually using standard data types
    /// - Parameters:
    ///   - title: The title of the hoerspiel
    ///   - albumID: The id of the corresponding album from MusicKit as a String
    ///   - duration: A timeinterval that represents the total duration of the hoerspiel
    ///   - releaseDate: A date that represents the release date of the hoerspiel
    ///   - artist: A string that represents the name of the artist that published that hoerspiel
    ///   - upc: The Universal Product Code for the Hoerspiel
    ///   - lastPlayed: A date that indicates when the playback was last initiated for that hoerspiel
    ///   - playedUpTo: An Integer that indicates how far the hoerspiel was played to
    ///   - played: A boolean that indicates whether this hoerspiel has previously been played til the end
    init(title: String,
         albumID: String,
         duration: TimeInterval,
         releaseDate: Date,
         artist: String,
         upc: String,
         lastPlayed: Date,
         playedUpTo: Int,
         played: Bool
    ) {
        self.title = title
        self.albumID = albumID
        self.duration = duration
        self.releaseDate = releaseDate
        self.artist = artist
        self.upc = upc
        self.lastPlayed = lastPlayed
        self.playedUpTo = playedUpTo
        self.played = played
    }
    /// Creates a ``CodableHoerspiel`` from a ``Hoerspiel``
    init(hoerspiel: Hoerspiel) {
        self.title = hoerspiel.title
        self.albumID = hoerspiel.albumID
        self.duration = hoerspiel.duration
        self.releaseDate = hoerspiel.releaseDate
        self.artist = hoerspiel.artist
        self.upc = hoerspiel.upc
        self.lastPlayed = hoerspiel.lastPlayed
        self.playedUpTo = hoerspiel.playedUpTo
        self.played = hoerspiel.played
    }
    
    /// Optionally creates a ``CodableHoerspiel`` from an Artist
    /// - Parameter album: The album to get the data from
    init?(_ album: Album) {
        guard let upc = album.upc else { return nil }
        guard album.tracks?.isEmpty == false else { return nil }
        self.title = album.title
        self.albumID = album.id.rawValue
        self.duration = album.tracks?.reduce(0, { $0 + ($1.duration ?? 0)}) ?? 0
        self.releaseDate = album.releaseDate ?? Date.distantPast
        self.artist = album.artistName
        self.upc = upc
        self.lastPlayed = Date.distantPast
        self.playedUpTo = 0
        self.played = false
    }
}

/// A sstruct used to quickly fetch `UPC`and `title`of a ``Hoerspiel``
struct UPCJSON: Codable {
    /// The title of the ``Hoerspiel``
    let title: String
    /// The upc of the ``Hoerspiel``
    let upc: String
}

extension CodableHoerspiel {
    static var example = CodableHoerspiel(title: "Folge 17: Rettet Atlantis!",
                                          albumID: "1092526143",
                                          duration: 4725.989000000001,
                                          releaseDate: Date(timeIntervalSince1970: 1285891200),
                                          artist: "Die drei ??? Kids",
                                          upc: "886445747867",
                                          lastPlayed: Date.distantPast,
                                          playedUpTo: 0,
                                          played: false)
}
