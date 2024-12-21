//
//  OpenHoerspiel.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 07.09.24.
//

import AppIntents
import OSLog
import SwiftUI
import TelemetryDeck

/// An App Intent to initiate a playback
struct OpenHoerspiel: AppIntent {
    /// The title of the AppIntent
    static let title: LocalizedStringResource = "Hörspiel öffnen"
    
    /// The hoerspiel to open
    @Parameter(title: "Hörspiel")
    var target: HoerspielEntity
    
    /// A dependecy to access the `navigationManager` from an AppIntent
    @Dependency
    var navigation: NavigationManager
    
    /// Opens  a ``HoerspielEntity``
    /// - Returns: Returns an intentResult without values
    @MainActor
    func perform() async throws -> some IntentResult {
        Logger.appIntents.info("Opening \(target.id)")
        await navigation.openHoerspiel(upc: target.id)
        TelemetryDeck.signal("AppIntent.Open", parameters: ["Title": target.name])
        return .result()
    }
    /// The `parameterSummary` for the Intent
    static var parameterSummary: some ParameterSummary {
        Summary("Öffne \(\.$target)")
    }
    /// Specifies that the app will be opened when running this AppIntent
    static var openAppWhenRun: Bool = true
    
    init() {
        TelemetryDeck.initialize(config: .init(appID: "CF8103B9-95DE-446F-8435-C740A2FAA8BE"))
    }
}
