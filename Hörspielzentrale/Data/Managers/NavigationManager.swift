//
//  NavigationManager.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 30.06.24.
//

import MusicKit
import OSLog
import SwiftData
import SwiftUI

/// A class responsible for handling navigation
@MainActor
@Observable final class NavigationManager {
    
    init(dataManager: DataManager) {
        self.dataManager = dataManager
    }
    
    let dataManager: DataManager
    
    /// Currently selected tab
    var selection = Selection.home
    
    /// The search text of the current search
    var searchText = ""
    
    /// A boolean that indicates if the search is currently presented
    var searchPresented = false
    
    /// A boolean that indicates if the media sheet is shown fullscreen
    var presentMediaSheet = false
    
    /// The primary path of navigation in the search tab
    var searchPath = NavigationPath()
    
    /// The primary path of navigation in the home tab
    var homePath = NavigationPath()
    
    /// The primary path of navigation in the library tab
    var libraryPath = NavigationPath()
    
    /// A bool to toggle the appearance of the ``SeriesSelectionView`` sheet
    var showSeriesAddingSheet = false
    
    /// A boolean that indicates if the alert is shown
    ///
    /// This value can only be set using ``presentAlert(title:description:)``
    var alertPresented = false
    
    /// The title of the alert
    ///
    /// This value can only be set using ``presentAlert(title:description:)``
    private(set) var alertTitle = ""
    
    /// The optional description of the alert
    ///
    /// This value can only be set using ``presentAlert(title:description:)``
    private(set) var alertDescription: String?
    
    /// A boolean that indicates if the `musicSubscriptionSheet` is shown
    ///
    /// This value should only be set using ``presentMusicSubscriptionSheet(itemID:)``
    var musicSubscriptionSheetPresented = false
    
    /// The `MusicItemID` of the item presented in the `MusicSubscriptionSheet`
    ///
    /// This value can only be set using ``presentMusicSubscriptionSheet(itemID:)``
    private(set) var musicItemID = MusicItemID("")
    
    /// A function to navigate to the search with a specified search term
    /// - Parameter input: The term to search for
    func search(for input: String) {
        searchPath = NavigationPath()
        presentMediaSheet = false
        selection = .search
        searchText = input
        
    }
    
    /// Opens a hoerspiel with a specific `albumID`
    /// - Parameter id: the `albumID` of the hoerspiel to open
    func openHoerspiel(albumID id: String) async {
        selection = .library
        presentMediaSheet = false
        let fetchedResults = try? await dataManager.fetchIdentifiers( {
            FetchDescriptor<Hoerspiel>(predicate: #Predicate { hoerspiel in
            hoerspiel.albumID == id
        }) })
        guard let result = fetchedResults?.first else {
            Logger.navigation.error("Unable to get first result with id \(id)")
            return
        }
        guard let sendableHoerspiel = try? await dataManager.batchRead(result) else {
            Logger.navigation.error("Couldn't get sendableHoerspiel")
            return
        }
        Logger.navigation.info(
            "Opening hoerspiel with title \(sendableHoerspiel.title) and upc \(sendableHoerspiel.upc)")
        libraryPath.append(sendableHoerspiel)
    }
    
    /// Opens a hoerspiel with a specific `UPC`
    /// - Parameter upc: the upc of the hoerspiel to open
    func openHoerspiel(upc: String) async {
        selection = .library
        presentMediaSheet = false
        let fetchedResults = try? await dataManager.fetchIdentifiers( {
            var fetchDescriptor = FetchDescriptor<Hoerspiel>(predicate: #Predicate { hoerspiel in
                hoerspiel.upc == upc
            })
            fetchDescriptor.fetchLimit = 1
            return fetchDescriptor
        })
        guard let result = fetchedResults?.first else {
            Logger.navigation.error("Unable to get first result with upc \(upc)")
            return
        }
        guard let sendableHoerspiel = try? await dataManager.batchRead(result) else {
            Logger.navigation.error("Couldn't get sendableHoerspiel")
            return
        }
        Logger.navigation.info(
            "Opening hoerspiel with title \(sendableHoerspiel.title) and upc \(sendableHoerspiel.upc)")
        libraryPath.append(sendableHoerspiel)
    }
    
    func presentAlert(title: String, description: String?) {
        alertTitle = title
        alertDescription = description
        alertPresented = true
    }
    
    func presentMusicSubscriptionSheet(itemID: String) {
        musicItemID = MusicItemID(itemID)
        musicSubscriptionSheetPresented = true
    }
    
}

/// Enum for currently selected tab
enum Selection: Int {
    case library
    case search
    case home
}

extension String {
    /// Retruns the album for the given UPC
    /// - Returns: Album for UPC given
    public func getAlbum() async throws -> Album {
            let resourceRequest = MusicCatalogResourceRequest<Album>(matching: \.upc, equalTo: self)
            let resourceResponse = try await resourceRequest.response()
            if let album = resourceResponse.items.first {
                return album
            }
            throw GettingAlbumError.appleMusicError
        }
}
