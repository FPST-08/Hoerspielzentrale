//
//  CuteLabel.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 18.06.24.
//

import SwiftUI
import UIKit

/// A cute label suitable for lists
struct CuteLabel: View {
    // MARK: - Properties
    
    /// The complementing text associated with this `Label`
    let title: String
    
    /// The `systenName` of the icon that should be displayed
    let systemName: String
    
    /// The color behind the symbol
    let backgroundColor: Color
    
    // MARK: - Views
    var body: some View {
        Label(
            title: {
                Text(title)
                
            },
            icon: {
                ZStack {
                    Image(systemName: systemName)
                        .foregroundStyle(backgroundColor.adaptedTextColor())
                        .font(.body)
                        .background {
                            RoundedRectangle(cornerRadius: 10)
                                .foregroundStyle(backgroundColor)
                                .frame(minWidth: 32, minHeight: 32)
//                                .padding(0)
                        }
                }
                .offset(x: -5)
            }
        )
    }
    
    /// Initialzer for ``CuteLabel``
    /// - Parameters:
    ///   - title: The complementing text associated with this `Label`
    ///   - systemName: The `systenName` of the icon that should be displayed
    ///   - backgroundColor: The color behind the symbol
    init(title: String, systemName: String, backgroundColor: Color = .red) {
        self.title = title
        self.systemName = systemName
        self.backgroundColor = backgroundColor
    }
}

extension Color {
    /// The luminance of self
    /// - Returns: Returns a double representing the luminance of self
    func luminance() -> Double {
        // Convert SwiftUI Color to UIColor
        let uiColor = UIColor(self)
        
        // Extract RGB values
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: nil)
        
        // Compute luminance.
        return 0.2126 * Double(red) + 0.7152 * Double(green) + 0.0722 * Double(blue)
    }
    
    /// A text color adapted to self as the background color
    /// - Returns: Returns either black or white, whatever fits better
    func adaptedTextColor() -> Color {
        return luminance() > 0.5 ? Color.black : Color.white
    }
}
