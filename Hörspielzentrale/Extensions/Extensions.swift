//
//  Extensions.swift
//  diedreifragezeichenplayer
//
//  Created by Philipp Steiner on 22.04.24.
//

import Combine
import Defaults
import MediaPlayer
import MusicKit
import OSLog
import StoreKit
import SwiftData
import SwiftUI
import UIKit

/// The documents directory used to save files
let documentsDirectoryPath: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension Bundle {
    /// The current version number read from the Bundle
    var releaseVersionNumber: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
    /// The current build version number read from the Bundle
    var buildVersionNumber: String? {
        return infoDictionary?["CFBundleVersion"] as? String
    }
}

extension View {
    /// The corner radius of the current device
    @MainActor
    var deviceCornerRadius: CGFloat {
        let key = "_displayCornerRadius"
        if let screen = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.screen {
            if let cornerRadius = screen.value(forKey: key) as? CGFloat {
                return cornerRadius
            }
            
        }
        return 0
    }
}

extension Sequence {
    /// Asynchronously calls body with each element in the path
    func asyncForEach(
        _ operation: (Element) async throws -> Void
    ) async rethrows {
        for element in self {
            try await operation(element)
        }
    }
}

extension Sequence {
    
    /// Returns a LazyMapSequence over this Sequence.
    /// The elements of the result are computed lazily, each time they are read,
    /// by calling transform function on a base element.
    func asyncMap<T>(
        _ transform: @Sendable (Element) async throws -> T
    ) async rethrows -> [T] {
        var values = [T]()

        for element in self {
            try await values.append(transform(element))
        }

        return values
    }
}

/// An array of Integer which represent the numbers of episodes with a disclaimer
///
/// - Important: Only the Hoerspiele from `Die drei ???` have disclaimers
let hoerspielNumbersWithDisclaimer = [1, 3, 4, 6, 19, 35]

extension View {
    /// Inverts the colors of this view if boolean is true
    /// - Parameter bool: The bool to toggle the invert
    /// - Returns: A view that inverts its colors.
    func colorInvert(_ bool: Bool) -> some View {
        modifier(ColorInvertViewModifier(bool: bool))
    }
}
/// A view modifier that inverts the colors of a view
struct ColorInvertViewModifier: ViewModifier {
    let bool: Bool
    func body(content: Content) -> some View {
        if bool {
            content
                .colorInvert()
        } else {
            content
        }
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

extension UIScreen {
    /// The screen width of the device
    static let screenWidth = UIScreen.main.bounds.size.width
    
    /// The screen height of the device
    static let screenHeight = UIScreen.main.bounds.size.height
}

extension Image {
    init?(_ uiImage: UIImage?) {
        if let uiImage {
            let image = Image(uiImage: uiImage)
            self = image
        } else {
            return nil
        }
    }
}

/// An Error used to communicate Album loading errors
enum GettingAlbumError: Error {
    case appleMusicError,
         unableToReadTitle,
         secondOptionFailed,
         unableToLoadTracks
    
    var localizedDescription: String {
        switch self {
        case .appleMusicError:
            "Ein Fehler mit Apple Music trat auf"
        case .unableToReadTitle:
            "Der Titel des Hörspiels konnte nicht gelesen werden"
        case .secondOptionFailed:
            "Das Album konnte zweifach nicht geladen werden"
        case .unableToLoadTracks:
            "Die Tracks des Albums konnten nicht geladen werden"
        }
    }
}

extension Array {
    /// Splits an array into chunks of the specified size
    /// - Parameter size: The size of the chunks
    /// - Returns: Returns an array of arrays with the specified size
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

extension UIDevice {
    /// A boolean that indicates if the current device is an iPad
    static var isIpad: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
}

extension MPMusicPlaybackState {
    /// A textual representation of this instance
    var description: String {
        switch self {
        case .playing:
            return "Playing"
        case .paused:
            return "Paused"
        case .stopped:
            return "Stopped"
        case .interrupted:
            return "Interrupted"
        case .seekingForward:
            return "Seeking Forward"
        case .seekingBackward:
            return "Seeking Backward"
        @unknown default:
            return "Unknown"
        }
    }
}

/// Requests a review if appropriate
func requestReviewIfAppropriate() {
    if Defaults[.timesPlaybackStarted] > 10 {
        if let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
}

extension UIScreen {
    /// The save area of the current Screen
    static var safeArea: UIEdgeInsets? {
        let keyWindow = UIApplication.shared.connectedScenes
            .filter({$0.activationState == .foregroundActive})
            .map({$0 as? UIWindowScene})
            .compactMap({$0})
            .first?.windows
            .filter({$0.isKeyWindow}).first
        
        return keyWindow?.safeAreaInsets
    }
}

extension ReferenceWritableKeyPath: @unchecked @retroactive Sendable { }
