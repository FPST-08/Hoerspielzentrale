//
//  PlayHoerspiel.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 07.09.24.
//

import AppIntents
import OSLog
import TelemetryDeck

/// An App Intent to initiate a playback
struct PlayHoerspiel: AppIntent {
    /// The title of the AppIntent
    static let title: LocalizedStringResource = "Hörspiel abspielen"
    
    /// The hoerspiel to start the playback for
    @Parameter(title: "Hörspiel")
    var target: HoerspielEntity
    
    /// A dependency to access the database
    @Dependency
    var datamanager: DataManager
    
    /// A dependency to access the ``musicManager` from an AppIntent
    @Dependency
    var musicmanager: MusicManager
    
    /// Initiates a playback for a ``HoerspielEntity``
    /// - Returns: Returns an intentResult without values
    func perform() async throws -> some IntentResult {
        
        Logger.appIntents.info("UPC: \(target.id)")
        
        let identifer = try await datamanager.identifierForUPC(upc: target.id)
        
        await musicmanager.startPlayback(for: identifer)
        TelemetryDeck.signal("AppIntent.Play", parameters: ["Title": target.name])
        return .result()
    }
    
    /// The `parameterSummary` for the Intent
    static var parameterSummary: some ParameterSummary {
        Summary("Spiele \(\.$target) ab")
    }
    
    /// Specifies that the app will not be opened when running this AppIntent
    static var openAppWhenRun: Bool = false
    
    init() {
        TelemetryDeck.initialize(config: .init(appID: "CF8103B9-95DE-446F-8435-C740A2FAA8BE"))
    }
}
