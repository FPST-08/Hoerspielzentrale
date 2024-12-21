//
//  Color.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 04.07.24.
//

import Foundation
import SwiftUI
import UIKit

extension UIColor {
    static var random: UIColor {
        return UIColor(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1),
            alpha: 1.0
        )
    }
}

extension Color {
    /// A Color with random RGB values
    static var random: Color {
        return Color(uiColor: UIColor.random)
    }
}

public extension Color {
    /// The nonadaptable system color for text on a dark background.
    static let lightText = Color(UIColor.lightText)
    
    /// The nonadaptable system color for text on a light background.
    static let darkText = Color(UIColor.darkText)
    
    /// The color for text labels that contain primary content.
    static let label = Color(UIColor.label)
    
    /// The color for text labels that contain secondary content.
    static let secondaryLabel = Color(UIColor.secondaryLabel)
    
    /// The color for text labels that contain tertiary content.
    static let tertiaryLabel = Color(UIColor.tertiaryLabel)
    
    /// The color for text labels that contain quaternary content.
    static let quaternaryLabel = Color(UIColor.quaternaryLabel)
    
    /// The color for the main background of your interface.
    static let systemBackground = Color(UIColor.systemBackground)
    
    /// The standard base gray color that adapts to the environment.
    static let systemGray = Color(UIColor.systemGray)
    
    /// A color object with a grayscale value of 1/3 and an alpha value of 1.0.
    static let darkGray = Color(UIColor.darkGray)
    
    /// A color object with a grayscale value of 2/3 and an alpha value of 1.0.
    static let lightGray = Color(UIColor.lightGray)
    
    /// A second-level shade of gray that adapts to the environment.
    static let systemGray2 = Color(UIColor.systemGray2)
    
    /// A third-level shade of gray that adapts to the environment.
    static let systemGray3 = Color(UIColor.systemGray3)
    
    /// A fourth-level shade of gray that adapts to the environment.
    static let systemGray4 = Color(UIColor.systemGray4)
    
    /// A fifth-level shade of gray that adapts to the environment.
    static let systemGray5 = Color(UIColor.systemGray5)
    
    /// A sixth-level shade of gray that adapts to the environment.
    static let systemGray6 = Color(UIColor.systemGray6)
    
    /// The color for the main background of your grouped interface.
    static let systemGroupedBackground = Color(UIColor.systemGroupedBackground)
    
    /// The color for content layered on top of the main background.
    static let secondarySystemBackground = Color(UIColor.secondarySystemBackground)
    
    /// An overlay fill color for medium-size shapes.
    static let secondarySystemFill = Color(UIColor.secondarySystemFill)
    
    /// The color for content layered on top of the main background of your grouped interface.
    static let secondarySystemGroupedBackground = Color(UIColor.secondarySystemGroupedBackground)
    
    /// The color for content layered on top of secondary backgrounds.
    static let tertiarySystemBackground = Color(UIColor.tertiarySystemBackground)
    
    /// An overlay fill color for large shapes.
    static let tertiarySystemFill = Color(UIColor.tertiarySystemFill)
    
    /// The color for content layered on top of secondary backgrounds of your grouped interface.
    static let tertiarySystemGroupedBackground = Color(UIColor.tertiarySystemGroupedBackground)
    
    /// An overlay fill color for large areas that contain complex content.
    static let quaternarySystemFill = Color(UIColor.quaternarySystemFill)
}

extension UIImage {
    // swiftlint:disable line_length
    /// Returns the average color of an `UIImage
    var averageColor: UIColor? {
        guard let inputImage = CIImage(image: self) else { return nil }
        let extentVector = CIVector(x: inputImage.extent.origin.x, y: inputImage.extent.origin.y, z: inputImage.extent.size.width, w: inputImage.extent.size.height)

        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: extentVector]) else { return nil }
        guard let outputImage = filter.outputImage else { return nil }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull as Any])
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)

        return UIColor(red: CGFloat(bitmap[0]) / 255, green: CGFloat(bitmap[1]) / 255, blue: CGFloat(bitmap[2]) / 255, alpha: CGFloat(bitmap[3]) / 255)
    }
    // swiftlint:enable line_length
}
