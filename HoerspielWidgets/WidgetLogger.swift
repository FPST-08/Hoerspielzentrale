//
//  WidgetLogger.swift
//  HoerspielWidgetsExtension
//
//  Created by Philipp Steiner on 02.10.24.
//

import OSLog

// swiftlint:disable trailing_whitespace
extension Logger {
    /// Used by the `TimelineProvider` for widgets
    static let widgets = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Widgets")
    
    /// A function to convienently log all errors
    ///
    /// - Tip: Do not overwrite the function and file parameter.
    /// They will be logged alongside the error to indicate its location
    func fullError(_ error: Error, function: String = #function, file: String = #file) {
        let errorString = """
    \(function) - \(file) - \(error.localizedDescription) 
    \(error)
    """
        self.error("\(errorString)")
    }
}
// swiftlint:enable trailing_whitespace
