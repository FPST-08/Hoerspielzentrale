//
//  NumbersExtensions.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 18.06.24.
//

import Foundation

extension Date {
    static func - (lhs: Date, rhs: Date) -> TimeInterval {
        return lhs.timeIntervalSinceReferenceDate - rhs.timeIntervalSinceReferenceDate
    }
    /// A string of the time intervals since the reference date
    public var rawValue: String {
            self.timeIntervalSinceReferenceDate.description
        }
}

extension TimeInterval {
    /// Formatting self like "1 Stunde und 23 Minuten" or "12 Minuten"
    func formattedDuration() -> String {
        // Convert the time interval to total seconds
        let totalSeconds = Int(self)

        // Calculate hours, minutes, and seconds
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60

        // Construct the formatted string
        var components: [String] = []

        if hours > 0 {
            components.append("\(hours) Stunde" + (hours == 1 ? "" : "n"))
        }
        if minutes >= 0 {
            components.append("\(minutes) Minute" + (minutes == 1 ? "" : "n"))
        }

        return components.joined(separator: " und ")
    }
}
extension Int {
    /// Format self in seconds to either 1:23:45 or 12:34
    /// - Returns: Returns a string with the corresponding formatting
    func formatTime() -> String {
        // Calculate hours, minutes and seconds
        let hours = self / 3600
        let minutes = (self % 3600) / 60
        let remainingSeconds = self % 60
        
        // Format the time as a string
        if hours > 0 {
            // Format as "h:mm:ss"
            return String(format: "%d:%02d:%02d", hours, minutes, remainingSeconds)
        } else {
            // Format as "mm:ss"
            return String(format: "%02d:%02d", minutes, remainingSeconds)
        }
    }
}

extension Date {
    /// Creates a date from given parameters
    /// - Parameters:
    ///   - day: The day of the month
    ///   - month: The month
    ///   - year: The year
    /// - Returns: Returns a date with specified parameters. Time will be 00:00
    static func from(day: Int, month: Int, year: Int) -> Date {
        var dateComponents = DateComponents()
        dateComponents.day = day
        dateComponents.month = month
        dateComponents.year = year
        
        let calendar = Calendar.current
        return calendar.date(from: dateComponents)!
    }
    /// Indicates if self is a date from the past
    func isPast() -> Bool {
        self < Date.now
    }
    /// Indicates if self is a date of the future
    func isFuture() -> Bool {
        self > Date.now
    }
}

extension BinaryFloatingPoint {
    /// Formats a `BinaryFloatingPoint` to a format suitable for time indications on scrub bars
    /// - Returns: Returns a formatted string like 12:34 or 1:23:45
    func customFormatted() -> String {
        let absoluteInterval = abs(self)
        
        let hours = Int(absoluteInterval) / 3600
        let minutes = (Int(absoluteInterval) % 3600) / 60
        let seconds = Int(absoluteInterval) % 60
        
        var formattedString: String
        
        if hours > 0 {
            formattedString = String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            formattedString = String(format: "%d:%02d", minutes, seconds)
        }
        
        return formattedString
    }
}

extension Date {
    /// A textual representation of the time passed since self
    /// - Returns: The representation
    func timeAgo() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full // Use "full", "spellOut", or "short" based on preference
        formatter.dateTimeStyle = .numeric
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
