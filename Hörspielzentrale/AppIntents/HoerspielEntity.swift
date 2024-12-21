//
//  HoerspielEntity.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 07.09.24.
//

import AppIntents
import SwiftUI

/// An entity used by ShortCuts to reference Hoerspiele
struct HoerspielEntity: AppEntity {
    
    @AppDependency
    var datamanager: DataManager
    
    /// The title of the `Hoerspiel`
    var name: String
    
    /// The artist of the `Hoerspiel`
    var artist: String
    
    /// The release date of the `Hoerspiel`
    var releaseDate: Date
    
    /// The cover of the `Hoerspiel`
    ///
    /// If the image was never loaded from within the app, this will be nil
    var image: DisplayRepresentation.Image?
    
    /// The type display representation of the `Hoerspiel`.
    ///
    /// It is `Hörspiel` instead of `Hoerspiel`
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: LocalizedStringResource("Hörspiel"))
    }
    
    /// The display representation used to present `HoerspielEntities` visually
    ///
    /// The name of the `Hoerspiel` is used as the title, artist and releasedate serve as the subtitle
    /// and the cover is the image, if available.
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: LocalizedStringResource(stringLiteral: name),
                              subtitle: LocalizedStringResource(stringLiteral: """
\(artist) – \(releaseDate.formatted(date: .numeric, time: .omitted))
"""),
                              image: image)
        
    }
    
    /// The id used to identify ``HoerspielEntity``
    ///
    /// This is a UPC
    var id: String
    
    /// The Query to access a ``HoerspielEntity``
    static var defaultQuery = HoerspielEntityQuery()
    
}
