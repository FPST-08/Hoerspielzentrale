//
//  InsertableHoerspiel.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 17.02.25.
//

import Foundation
import MusicKit

/// A hoerspiel that can be inserted into the database
struct InsertableHoerspiel {
    /// The title of the hoerspiel
    var title: String
    
    /// The albumID of the hoerspiel
    ///
    ///  The value looks similiar to  `1092529875`. It consists of numbers only but is returned and treated as a string.
    var albumID: String
    
    /// A timeinterval that represents the total duration of the hoerspiel in seconds
    var duration: TimeInterval
    
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
    
    var tracks: [SendableStoredTrack]
}
