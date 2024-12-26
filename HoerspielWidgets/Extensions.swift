//
//  Extensions.swift
//  HoerspielWidgetsExtension
//
//  Created by Philipp Steiner on 26.12.24.
//

import OSLog
import SwiftUI

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

extension Array where Element == HoerspielData {
    /// Sorts an Array of ``HoerspielData`` to start with the one mostrecently added to up next
    /// - Returns: Returns the sorted array
    func sortByAddedToUpNext() -> [HoerspielData] {
        return self.sorted(by: { $0.hoerspiel.addedToUpNext > $1.hoerspiel.addedToUpNext})
    }
}

extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension View {
    /// Sets the URL to open in the containing app when the user clicks the widget.
    func widgetURL(for hoerspiel: SendableHoerspiel) -> some View {
        modifier(WidgetURLViewModifier(hoerspiel: hoerspiel))
    }
}

/// A modifier to apply the widgetURL to link to the detail view
struct WidgetURLViewModifier: ViewModifier {
    /// The hoerspiel to link to
    let hoerspiel: SendableHoerspiel
    func body(content: Content) -> some View {
        content
            .widgetURL(URL(string: "hoerspielzentrale://open-hoerspiel?upc=\(hoerspiel.upc)")!)
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
            components.append("\(hours) h")
        }
        if minutes > 0 {
            components.append("\(minutes) m")
        }
        
        return components.joined(separator: " ")
    }
}

public extension UIImage {
    /// Creates a `UIImage` from a colo
    /// - Parameters:
    ///   - color: The desired color
    ///   - size: The size of the image
    convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
}
