//
//  Series.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 24.11.24.
//

import SwiftData

/// A  class used to save Series in SwiftData
@Model
class Series: Identifiable {
    
    /// The name of the artist
    var name: String = ""
    
    /// The id of the artist
    var musicItemID: String = ""
    
    @Relationship(deleteRule: .cascade, inverse: \Hoerspiel.series) var hoerspiels: [Hoerspiel]? = []
    
    init(name: String = "",
         musicItemID: String = ""
    ) {
        self.name = name
        self.musicItemID = musicItemID
    }
    
    init(name: String,
         musicItemID: String,
         hoerspiels: [Hoerspiel]? = nil) {
        self.name = name
        self.musicItemID = musicItemID
        self.hoerspiels = hoerspiels
    }
}

extension Series {
    static var example = Series(name: "Die drei ??? Kids", musicItemID: "305761269")
}
