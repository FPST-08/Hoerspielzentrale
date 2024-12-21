//
//  SendableSeries.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 29.11.24.
//

import Defaults
import Foundation
import SwiftData

/// A struct that is used to safely pass around a ``Series``
struct SendableSeries: Codable, Sendable, Identifiable, Defaults.Serializable {
    /// A rebranded instance of `musicItemID`to conform to `Identifable`
    var id: String {
        musicItemID
    }
    
    /// The name of the artist
    var name: String
    
    /// The id of the artist
    var musicItemID: String
    
    var persistentModelID: PersistentIdentifier
    
    init (name: String, musicItemID: String, persistentModelID: PersistentIdentifier) {
        self.name = name
        self.musicItemID = musicItemID
        self.persistentModelID = persistentModelID
    }
    
    init(_ series: Series) {
        self.name = series.name
        self.musicItemID = series.musicItemID
        self.persistentModelID = series.persistentModelID
    }
    
    init?(_ series: Series?) {
        if let series {
            self.name = series.name
            self.musicItemID = series.musicItemID
            self.persistentModelID = series.persistentModelID
        }
        return nil
    }
}
