//
//  CacheManager.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 07.09.24.
//

import Defaults
import Foundation
@preconcurrency import MusicKit
import OSLog
import SwiftUI

/// A class responsible for caching cover images of a ``Hoerspiel``
@MainActor
@Observable class ImageCache {
    let datamanager: DataManager
    
    /// The cache used to store the covers
    private let smallImageCache: NSCache<NSString, UIImage> = NSCache()
    
    private let regularImageCache: NSCache<NSString, UIImage> = NSCache()
    
    private let seriesImageCache: NSCache<NSString, UIImage> = NSCache()
    
    init(dataManager: DataManager) {
        self.datamanager = dataManager
    }
    /// Provides the cover for a specified ``SendableHoerspiel``
    ///  - Parameter hoerspiel: The ``SendableHoerspiel`` used to find the corresponding Cover
    ///  - Parameter size: The size option of the image
    ///  - Returns: Returns an `Image`if the cover was successfully retrieved
    /// 
    ///  This function is building on top of ``uiimage(for:)``and converts its result to an `Image`
    /// 
    ///  - Note: If the cover is needed as an UIImage, call ``uiimage(for:)`` directly
    func image(for hoerspiel: SendableHoerspiel, size: SizeOptions = .small) async -> Image? {
        if let uiimage = await uiimage(for: hoerspiel, size: size) {
            return Image(uiImage: uiimage)
        } else {
            return nil
        }
    }
    
    /// Provides the cover for a specified ``SendableHoerspiel``
    /// - Parameter hoerspiel: The ``SendableHoerspiel`` used to find the corresponding Cover
    /// - Parameter size: The size option of the image
    /// - Returns: Returns an `UIImage` if the cover was successfully retrieved
    /// 
    /// First it will be tried to load the image from the cache.
    /// If it is not to be found there, it will be tried to load the image from disk.
    /// If that also fails, the image will be loaded from the Apple Music API.
    /// If all of these attempts where not successfull, nil will be returned
    func uiimage( // swiftlint:disable:this cyclomatic_complexity
        for hoerspiel: SendableHoerspiel,
        size: SizeOptions = .small
    ) async -> UIImage? {
        let task = Task {
            if hoerspiel.upc == "" {
                assertionFailure()
            }
    #if DEBUG
            if hoerspiel.upc == "DEBUG" {
                return UIImage(color: UIColor.random)
            }
    #endif
            let upc = hoerspiel.upc
            switch size {
            case .fullResolution:
                let fileURL = documentsDirectoryPath.appendingPathComponent("\(upc).jpg")
                if let image = UIImage(contentsOfFile: fileURL.path()) {
                    let coverSize = Defaults[.coversize].width
                    deleteImageWithWrongSize(upc: upc, size: coverSize)
                    return image
                }
            case .small, .regular:
                let cache = size == .small ? smallImageCache : regularImageCache
                let size = size == .small ? 80 : 192
                if let uiimage = cache.object(forKey: upc as NSString) {
                    Logger.data.info("Image for \(upc) was read from Cache  with size \(uiimage.size.width)")
                    return uiimage
                } else {
                    let fileURL = documentsDirectoryPath.appendingPathComponent("\(upc).jpg")
                    let image = resizedImage(at: fileURL, for: CGSize(width: size, height: size))
                    if let image {
                        cache.setObject(image, forKey: "\(upc)" as NSString)
                        return image
                    }
                }
            }
            
            guard let image = await loadImageFromRemote(for: hoerspiel) else {
                return nil
            }
            switch size {
            case .fullResolution:
                let coverSize = Defaults[.coversize].width
                return resizedImage(image, for: CGSize(width: coverSize, height: coverSize))
            case .small:
                return resizedImage(image, for: CGSize(width: 80, height: 80))
            case .regular:
                return resizedImage(image, for: CGSize(width: 192, height: 192))
            }
        }
        let result = await task.value
        return result

    }
    
    func loadImageFromRemote(for hoerspiel: SendableHoerspiel) async -> UIImage? {
        guard let album = try? await hoerspiel.album(datamanager) else {
            Logger.data.error("Couldn't get album")
            return nil
        }
        
        let coversizeString = UserDefaults.standard.string(forKey: "coversize") ?? "Klein"
        let width = CoverSize(coversizeString).width
        
        guard let url = album.artwork?.url(width: Int(width), height: Int(width)) else {
            Logger.data.error("Couldn't get url for artwork \(hoerspiel.upc)")
            return nil
        }
        guard let (data, _) = try? await URLSession.shared.data(from: url) else {
            Logger.data.error("URLSession failed")
            return nil
        }
        guard let uiimage = UIImage(data: data) else {
            Logger.data.error("Cannot convert data to uiimage")
            return nil
        }
        if let data = uiimage.jpegData(compressionQuality: 0.8) {
            let filename = documentsDirectoryPath
                .appendingPathComponent("\(hoerspiel.upc).jpg")
            try? data.write(to: filename, options: .atomic)
            Logger.data.info("Image for \(hoerspiel.upc) was fetched from Apple Music with size \(uiimage.size.width)")
            deleteImageWithWrongSize(upc: hoerspiel.upc, size: uiimage.size.width)
            return uiimage
        }
        return nil
    }
    
    func deleteImageWithWrongSize(upc: String, size: Double) {
        guard let coversizeString = UserDefaults.standard.string(forKey: "coversize") else {
            return
        }
        let coverSize = CoverSize(coversizeString)
        if coverSize.width != size {
            let filename = documentsDirectoryPath.appendingPathComponent("\(upc).jpg")
            do {
                try FileManager.default.removeItem(atPath: filename.path)
                Logger.data.info("""
Deleting image with upc \(upc) since its size of \(size) is not equal to the stored size of \(coverSize.width)
""")
            } catch {
                Logger.data.fullError(error,
                                      additionalParameters: [
                                        "coversize": size.formatted(),
                                        "coversizedstring": coversizeString],
                                      sendToTelemetryDeck: false)
            }
        }
    }
    
    ///  Provides the cover for a specified ``SendableSeries``
    /// - Parameter hoerspiel: The ``SendableSeries`` used to find the corresponding Cover
    /// - Returns: Returns an `Image`if the cover was successfully retrieved
    ///
    /// This function is building on top of ``uiimage(for:)``and converts its result to an `Image`
    ///
    /// - Note: If the cover is needed as an UIImage, call ``uiimage(for:)`` directly
    func image(for sendableSeries: SendableSeries) async -> Image? {
        if let uiimage = await uiimage(for: sendableSeries) {
            return Image(uiImage: uiimage)
        } else {
            return nil
        }
    }
    
    /// Loades the UIImage for a ``SendableSeries``
    /// - Parameter sendableSeries: The sendableseries
    /// - Returns: Returns the `UIImage` if possible, otherwise nil
    func uiimage(for sendableSeries: SendableSeries) async -> UIImage? {
        let task = Task {
            do {
                if sendableSeries.musicItemID == "" {
                    assertionFailure()
                    throw LoadingCoverError.identifierNotAvailable
                }
#if DEBUG
                if sendableSeries.musicItemID == "DEBUG" {
                    return UIImage(color: UIColor.random)
                }
#endif
                let musicItemID = sendableSeries.musicItemID
                if let uiimage = seriesImageCache.object(forKey: musicItemID as NSString) {
                    Logger.data.info("Image for \(musicItemID) was read from Cache")
                    return uiimage
                } else {
                    let fileURL = documentsDirectoryPath.appendingPathComponent("\(musicItemID).jpg")
                    
                    if let imageData = try? Data(contentsOf: fileURL) {
                        guard let uiimage = UIImage(data: imageData) else {
                            throw LoadingCoverError.unableToCreateImage
                        }
                        seriesImageCache.setObject(uiimage, forKey: musicItemID as NSString)
                        Logger.data.info("Image for \(musicItemID) was read from disk")
                        return uiimage
                    } else {
                        Logger.data.info("Image for \(musicItemID) is not locally available")
                        return await loadImageFromRemote(for: sendableSeries)
                    }
                }
            }
        }
        let value = try? await task.value
        return value
    }
    
    /// Loads the artist image from Apple Music
    /// - Parameter series: The corresponding series
    /// - Returns: Returns the `UIImage`if possible, otherwise nil
    func loadImageFromRemote(for series: SendableSeries) async -> UIImage? {
        do {
            var request = MusicCatalogResourceRequest<Artist>(matching: \.id, equalTo: MusicItemID(series.musicItemID))
            request.limit = 1
            
            guard let artist = try await request.response().items.first else {
                Logger.imageCache.error("Unable to get first item of ressource request response")
                return nil
            }
            
            let coversizeString = UserDefaults.standard.string(forKey: "coversize")
            let coversize = Int(CoverSize(coversizeString ?? "Groß").width)
            
            guard let url = artist.artwork?.url(width: coversize, height: coversize) else {
                Logger.imageCache.error("Unable to get artwork url")
                return nil
            }
            let (data, _) = try await URLSession.shared.data(from: url)
            
            guard let uiimage = UIImage(data: data) else {
                Logger.imageCache.error("Cannot convert data to uiimage")
                return nil
            }
            if let data = uiimage.jpegData(compressionQuality: 0.8) {
                let filename = documentsDirectoryPath
                    .appendingPathComponent("\(series.musicItemID).jpg")
                try? data.write(to: filename, options: .atomic)
                Logger.imageCache.info("Image for \(series.musicItemID) was fetched from Apple Music")
                return uiimage
            }
        } catch {
            Logger.imageCache.fullError(error, sendToTelemetryDeck: true)
        }
        return nil
    }
    /// Fetches an `UIImage`from the url and resized that
    /// - Parameters:
    ///   - url: The file url of the image
    ///   - size: The desired size
    /// - Returns: Returns the resized image
    func resizedImage(at url: URL, for size: CGSize) -> UIImage? {
        guard let image = UIImage(contentsOfFile: url.path) else {
            return nil
        }

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    /// Resizes an `UIImage` to the specified size
    /// - Parameters:
    ///   - uiimage: The uiimage to resize
    ///   - size: The desired size
    /// - Returns: Returns the resized image
    func resizedImage(_ uiimage: UIImage, for size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            uiimage.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    /// The size options of an `UIImage`
    enum SizeOptions {
        case fullResolution
        case small
        case regular
    }
    
    enum LoadingCoverError: Error {
        case identifierNotAvailable
        case unableToCreateImage
    }
}

/// The Size of all Covers saved locally
enum CoverSize: Hashable, Codable, Defaults.Serializable {
    
    case small, normal, big
    
    /// The textual description of the cover size
    var description: String {
        switch self {
        case .small:
            return "Klein"
        case .normal:
            return "Mittel"
        case .big:
            return "Groß"
        }
    }
    
    /// The pixel width of the cover with this option
    var width: Double {
        switch self {
        case .small:
            512
        case .normal:
            768
        case .big:
            1024
        }
    }
    
    init(_ string: String) {
        switch string {
        case "Klein":
            self = .small
        case "Mittel":
            self = .normal
        case "Groß":
            self = .big
        default:
            self = .small
        }
    }
    
    /// An array of ``CoverSize`` containing all posible elements
    static let allSizes: [CoverSize] = [.small, .normal, .big]
}
