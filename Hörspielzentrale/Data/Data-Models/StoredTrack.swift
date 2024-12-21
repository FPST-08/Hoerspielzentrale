//
//  StoredTrack.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 23.10.24.
//

import Foundation
import SwiftData

/// A track used for quick playback
@Model
class StoredTrack {
    /// The position of the track in the ``Hoerspiel``
    ///
    /// This value starts at 0
    var index: Int = 0
    
    /// The title of the track
    var title: String = ""
    
    /// The duration of the track
    ///
    /// This value is provided in seconds
    var duration: TimeInterval = 0
    
    /// The musicItemID of the track
    var musicItemID: String = ""
    
    /// The International Standard Recording Code (ISRC) for the song.
    var isrc: String = ""
    
    /// The inverse relationship to the corresponding ``Hoerspiel``
    var hoerspiel: Hoerspiel?
    
    /// Creates a ``SendableStoredTrack`` manually using standard data types
    /// - Parameters:
    ///   - index: The index of the track
    ///   - title: The title of the track
    ///   - duration: The duration of the track
    ///   - musicItemID: The raw `MusicItemID` of the Track
    ///   - isrc: The `isrc` of the track
    ///   - hoerspiel: The inverse relationship
    init(
        index: Int = 0,
        title: String = "",
        duration: TimeInterval = 0,
        musicItemID: String = "",
        isrc: String = "",
        hoerspiel: Hoerspiel
    ) {
        self.index = index
        self.title = title
        self.duration = duration
        self.musicItemID = musicItemID
        self.isrc = isrc
        self.hoerspiel = hoerspiel
    }
}
