//
//  MetaDataCodable.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 01.07.24.
//

import Foundation

/// A struct used to decode the `JSON-Response` from dreimetadaten.de
struct MetaData: Codable {
    /// The describtion of the ``Hoerspiel``
    var beschreibung: String?
    
    /// The short description of the ``Hoerspiel``
    var kurzbeschreibung: String?
    
    /// The ``Kapitel`` of the ``Hoerspiel``
    var kapitel: [Kapitel]?  = []
    
    /// The ``Sprechrolle`` of the ``Hoerspiel``
    var sprechrollen: [Sprechrolle]? = []
    
    /// The corresponding links to the ``Hoerspiel``
    var links: Links?      = Links()
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.beschreibung = try container.decodeIfPresent(String.self, forKey: .beschreibung)
        self.kurzbeschreibung = try container.decodeIfPresent(String.self, forKey: .kurzbeschreibung)
        self.kapitel = try container.decodeIfPresent([Kapitel].self, forKey: .kapitel)
        self.sprechrollen = try container.decodeIfPresent([Sprechrolle].self, forKey: .sprechrollen)
        self.links = try container.decodeIfPresent(Links.self, forKey: .links)
    }
    
    init(beschreibung: String? = nil,
         kurzbeschreibung: String? = nil,
         kapitel: [Kapitel]? = nil,
         sprechrollen: [Sprechrolle]? = nil,
         links: Links? = nil) {
        self.beschreibung = beschreibung
        self.kurzbeschreibung = kurzbeschreibung
        self.kapitel = kapitel
        self.sprechrollen = sprechrollen
        self.links = links
    }
}

/// A struct used to decode Sprechrollen
///
/// This is used to decode and display the Speakers fetched from `dreimetadaten.de`
struct Sprechrolle: Codable, Hashable {
    var rolle: String
    var sprecher: String
}

/// A ``Kapitel`` of a ``Hoerspiel``
struct Kapitel: Codable, Hashable {
    /// The name of the ``Kapitel``
    var titel: String
    
    /// The start of the kapitel in ms
    var start: Int
    
    /// The end of the kapitel in ms
    var end: Int
}

/// A struct used to decode ``Links`` of a ``Hoerspiel``
struct Links: Codable {
    /// The link to apple music
    var appleMusic: String?
    
    /// The link to the product page
    var dreifragezeichen: String?
}
