//
//  GetInfo.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 07.09.24.
//

import AppIntents
import SwiftUI
import TelemetryDeck

/// An App Intent to access hoerspiel specific information
struct GetInfo: AppIntent {
    /// The title of the AppIntent
    static var title: LocalizedStringResource = "Hörspiel-Informationen"
    
    /// The hoerspiel to access information from
    @Parameter(title: "Hörspiel")
    var target: HoerspielEntity
    
    /// The detail to access
    @Parameter(title: "Detail")
    var value: Value
    
    /// A dependency to access the database
    @Dependency
    var datamanager: DataManager
    
    /// A dependency to access covers
    @Dependency
    var imagecache: ImageCache
    
    /// Gets information for a ``HoerspielEntity``
    /// - Returns: Returns the requested value
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let identifier = try await datamanager.identifierForUPC(upc: target.id)
        
        let hoerspiel = try await datamanager.batchRead(identifier)
        
        var returnValue = String()
        
        switch value {
        case .description:
            do {
                let metadata = try await hoerspiel.loadMetaData()
                returnValue = metadata.beschreibung ?? "N/A"
            } catch {
                returnValue = "Keine Beschreibung verfügbar"
            }
        case .releaseDate:
            returnValue = hoerspiel.releaseDate.formatted(date: .numeric, time: .omitted)
        case .name:
            returnValue = hoerspiel.title
        case .series:
            returnValue = hoerspiel.artist
        case .albumID:
            returnValue = hoerspiel.albumID
        case .upc:
            returnValue = hoerspiel.upc
        }
        TelemetryDeck.signal("AppIntent.Info", parameters: ["Value": value.localizedStringResource.key])
        return .result(value: returnValue)
    }
    /// The `parameterSummary` for the Intent
    static var parameterSummary: some ParameterSummary {
        Summary("\(\.$value) zu \(\.$target) abrufen")
    }
    
    init() {
        TelemetryDeck.initialize(config: .init(appID: "CF8103B9-95DE-446F-8435-C740A2FAA8BE"))
    }
}

/// A enum that represents all values to request from the App Intent
enum Value: String, AppEnum {
    case name, releaseDate, series, description, albumID, upc
    
    /// The default display representation 
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Wert"
    
    /// The textual representation of every value
    static var caseDisplayRepresentations: [Value: DisplayRepresentation] = [
        .description: "Beschreibung",
        .name: "Titel",
        .series: "Serie",
        .releaseDate: "Erscheinungsdatum",
        .albumID: "AlbumID",
        .upc: "Universal Product Code"
            
    ]
}
