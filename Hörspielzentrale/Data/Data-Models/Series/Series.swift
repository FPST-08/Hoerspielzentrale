//
//  Series.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 24.11.24.
//

import SwiftData

/// A struct that is used to safely pass around a ``Series``
struct CodableSeries: Codable, Sendable, Identifiable {
    /// A rebranded instance of `musicItemID`to conform to `Identifable`
    var id: String {
        musicItemID
    }
    
    /// The name of the artist
    var name: String
    
    /// The id of the artist
    var musicItemID: String
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.musicItemID = try container.decode(String.self, forKey: .id)
    }
    
    enum CodingKeys: String, CodingKey {
        case name, id
    }
    
    init (name: String, musicItemID: String) {
        self.name = name
        self.musicItemID = musicItemID
    }
    
    init(_ series: Series) {
        self.name = series.name
        self.musicItemID = series.musicItemID
    }
    
    init?(_ series: Series?) {
        if let series {
            self.name = series.name
            self.musicItemID = series.musicItemID
        }
        return nil
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(musicItemID, forKey: .id)
    }
}
