//
//  NewContentView.swift
//  diedreifragezeichenplayer
//
//  Created by Philipp Steiner on 10.04.24.
//
//

import OSLog
import SwiftData
import SwiftUI
import TelemetryDeck

/// `LibraryView`is a view that offers the user the most prominent actions
struct LibraryView: View {
    // MARK: - Properties
    
    /// A Boolean that represents the presense of the Settings Sheet
    @State private var showSettings = false
    
    /// The `NavigationPath` of the tab
    @State private var navPath = NavigationPath()
    
    /// An Observable Class responsible for navigation
    @Environment(NavigationManager.self) var navigation
    
    /// An Observable Class responsible for data
    @Environment(DataManagerClass.self) var dataManager
    
    // MARK: - View
    var body: some View {
        NavigationStack(path: Bindable(navigation).libraryPath) {
            VStack {
                ScrollView {
                    UpNextView()
                    
                    LibrarySectionView(title: "Neu erschienen", fetchDescriptor: {
                        let now = Date.now
                        let cutOffDate = Date.now.advanced(by: -86400 * 3)
                        
                        var fetchDescriptor = FetchDescriptor<Hoerspiel>(predicate: #Predicate { hoerspiel in
                            hoerspiel.releaseDate < now && hoerspiel.releaseDate > cutOffDate
                        })
                        
                        fetchDescriptor.fetchLimit = 10
                        return fetchDescriptor
                    }, displaymode: .big)
                    
                    LibrarySectionView(title: "Bald verfügbar", fetchDescriptor: {
                        let now = Date.now
                        var fetchDescriptor = FetchDescriptor<Hoerspiel>(predicate: #Predicate { hoerspiel in
                            hoerspiel.releaseDate > now
                        })
                        fetchDescriptor.sortBy = [SortDescriptor(\.releaseDate, order: .forward),
                                                  SortDescriptor(\.title)]
                        fetchDescriptor.fetchLimit = 10
                        return fetchDescriptor
                    }, displaymode: .rectangular)
                    
                    LibrarySectionView(title: "Neuheiten", fetchDescriptor: {
                        let now = Date.now
                        
                        var fetchDescriptor = FetchDescriptor<Hoerspiel>(predicate: #Predicate { hoerspiel in
                            hoerspiel.releaseDate < now
                        })
                        fetchDescriptor.sortBy = [SortDescriptor(\.releaseDate, order: .reverse)]
                        fetchDescriptor.fetchLimit = 10
                        return fetchDescriptor
                    }, displaymode: .rectangular)
                    
                    LibrarySectionView(title: "Zuletzt gespielt", fetchDescriptor: {
                        var fetchDescriptor = FetchDescriptor<Hoerspiel>(predicate: #Predicate { hoerspiel in
                            if hoerspiel.playedUpTo != 0 {
                                return true
                            } else if hoerspiel.played {
                                return true
                            } else {
                                return false
                            }
                        })
                        fetchDescriptor.fetchLimit = 10
                        fetchDescriptor.sortBy = [SortDescriptor(\Hoerspiel.lastPlayed, order: .reverse)]
                        return fetchDescriptor
                    }, displaymode: .rectangular)
                }
            }
            .navigationTitle("Hörspiele")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }

                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .navigationDestination(for: SendableHoerspiel.self) {
                HoerspielDetailView(hoerspiel: $0)
            }
            .safeAreaPadding(.bottom, 60)
        }
        .trackNavigation(path: "Library")
    }
}
