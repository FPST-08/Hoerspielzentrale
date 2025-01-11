//
//  SendableStoredTrack.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 23.10.24.
//

import Foundation
import MusicKit

/// A track used for quick playback
struct SendableStoredTrack: Sendable, Identifiable, Codable, Hashable {
    /// The position of the track in the ``Hoerspiel``
    ///
    /// This value starts at 0
    var index: Int = 0
    
    /// The title of the track
    var title: String
    
    /// The duration of the track
    ///
    /// This value is provided in seconds
    var duration: TimeInterval = 0
    
    /// The musicItemID of the track
    var musicItemID: String = ""
    
    /// The International Standard Recording Code (ISRC) for the song.
    var isrc: String = ""
    
    /// The `isrc` rebranded as an ID to conform to `Identifiable`
    var id: String {
        isrc
    }
    
    /// Creates a ``SendableStoredTrack`` manually using standard data types
    /// - Parameters:
    ///   - index: The index of the track
    ///   - title: The title of the track
    ///   - duration: The duration of the track
    ///   - musicItemID: The raw `MusicItemID` of the Track
    ///   - isrc: The `isrc` of the track
    init(
        index: Int = 0,
        title: String = "",
        duration: TimeInterval = 0,
        musicItemID: String = "",
        isrc: String = ""
    ) {
        self.index = index
        self.title = title
        self.duration = duration
        self.musicItemID = musicItemID
        self.isrc = isrc
    }
    
    /// Creates a ``SendableStoredTrack`` from a ``StoredTrack`` that can safely be passed around.
    /// - Parameter storedTrack: This is the original source of truth that gets copied
    init(_ storedTrack: StoredTrack) {
        self.index = storedTrack.index
        self.title = storedTrack.title
        self.duration = storedTrack.duration
        self.musicItemID = storedTrack.musicItemID
        self.isrc = storedTrack.isrc
    }
    
    /// Creates a ``SendableStoredTrack`` from a `Track`
    /// - Parameter track: The original source of truth
    /// - Parameter index: The index of the track
    init(
        _ track: Track,
        index: Int
    ) {
        self.index = index
        self.title = track.title
        self.duration = track.duration ?? 0
        self.musicItemID = track.id.rawValue
        self.isrc = track.isrc ?? ""
    }
}
