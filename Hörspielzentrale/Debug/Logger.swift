//
//  Logger.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 24.09.24.
//

import Foundation
import OSLog
import TelemetryDeck

extension Logger {
    /// The subsystem used by all Loggers
    ///
    /// This is the `bundleIdentifier`
    static private let subsystem = Bundle.main.bundleIdentifier!
    /// Used by the `RunViewModifier`and `RunViewValueModifier` only
    static let runViewModifier = Logger(subsystem: subsystem, category: "RunViewModifier")
    
    /// Used when opening the app via an URL
    static let url = Logger(subsystem: subsystem, category: "URL")
    
    /// Used in regards to playback
    static let playback = Logger(subsystem: subsystem, category: "Playback")
    
    /// Used by the ``NetworkHelper`` only to indicate network changes
    static let network = Logger(subsystem: subsystem, category: "Network")
    
    /// Used to indicate navigation
    static let navigation = Logger(subsystem: subsystem, category: "Navigation")
    
    /// Only used when onboarding
    static let onboarding = Logger(subsystem: subsystem, category: "Onboarding")
    
    /// Used when interacting with local data such as an ``Hoerspiel``
    static let data = Logger(subsystem: subsystem, category: "Data")
    
    /// Used for ``MetaData``loading and processing
    static let metadata = Logger(subsystem: subsystem, category: "Metadata")
    
    /// Used for indicating authorization to apple music and playback capability
    static let authorization = Logger(subsystem: subsystem, category: "Authorization")
    
    /// Used by the ``CustomFeatureVoter``
    static let roadmap = Logger(subsystem: subsystem, category: "Roadmap")
    
    /// Used across all AppIntents
    static let appIntents = Logger(subsystem: subsystem, category: "AppIntents")
    
    /// Used by maintenance work in the background
    static let maintenance = Logger(subsystem: subsystem, category: "Maintenance")
    
    /// Used by the series manager
    static let seriesManager = Logger(subsystem: subsystem, category: "SeriesManager")
    
    /// Used by the imageCache class
    static let imageCache = Logger(subsystem: subsystem, category: "ImageCache")
    
    /// A function to convienently log all errors
    ///
    ///  This function will log the error to the console but also send this data to TelemetryDeck.
    ///
    /// - Parameters:
    ///   - error: The error to log
    ///   - function: The caller function
    ///   - file: The file of the caller function
    ///   - additionalParameters: Additional parameters send to TelemetryDeck
    ///
    /// - Tip: Do not overwrite the function and file parameter.
    /// They will be logged alongside the error to indicate its location
    func fullError(
        _ error: Error,
        function: String = #function,
        file: String = #file,
        additionalParameters: [String: String] = [:],
        sendToTelemetryDeck: Bool
    ) {
        let errorString = """
\(function) - \(file) - \(error.localizedDescription) 
\(error)
"""
        self.error("\(errorString)")
        if sendToTelemetryDeck {
            var parameters = [
                "function": function,
                "file": file,
                "error": "\(error)"
            ]
            parameters.merge(additionalParameters) { (_, new) in new }
            TelemetryDeck.errorOccurred(id: error.localizedDescription, parameters: parameters)
        }
    }
    
}
