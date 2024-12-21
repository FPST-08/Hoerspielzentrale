//
//  StopPlayback.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 07.09.24.
//

import AppIntents
import TelemetryDeck

/// An App Intent to stop the current playback
struct StopPlayback: AppIntent {
    /// The title of the AppIntent
    static let title: LocalizedStringResource = "Wiedergabe stoppen"
    
    /// A dependency to access the musicManager from an AppIntent
    @Dependency
    var musicmanager: MusicManager
    
    /// Stops the current playback and saves the listening Progress
    /// - Returns: Returns an IntentResult without values
    @MainActor
    func perform() async throws -> some IntentResult {
        musicmanager.musicplayer.stop()
        await musicmanager.saveListeningProgressAsync()
        TelemetryDeck.signal("AppIntent.Stop")
        return .result()
    }
    
    /// Specifies that the app will not be opened when running this AppIntent
    static var openAppWhenRun: Bool = false
    
    init() {
        TelemetryDeck.initialize(config: .init(appID: "CF8103B9-95DE-446F-8435-C740A2FAA8BE"))
    }
}
