//
//  NewContentView.swift
//  diedreifragezeichenplayer
//
//  Created by Philipp Steiner on 10.04.24.
//
//

import MusicKit
import OSLog
import SwiftData
import SwiftUI
import TelemetryDeck

/// `HomeView`is a view that offers the user the most prominent actions
struct HomeView: View {
    // MARK: - Properties
    
    /// A Boolean that represents the presense of the Settings Sheet
    @State private var showSettings = false
    
    /// The `NavigationPath` of the tab
    @State private var navPath = NavigationPath()
    
    /// An Observable Class responsible for navigation
    @Environment(NavigationManager.self) var navigation
    
    /// An Observable Class responsible for data
    @Environment(DataManagerClass.self) var dataManager
    
    /// Referencing an `Observable` class responsible for playback
    @Environment(MusicManager.self) var musicmanager
    
    /// A bool to disable the dice
    @State private var disableDice = true
    
    // MARK: - View
    var body: some View {
        NavigationStack(path: Bindable(navigation).homePath) {
            VStack {
                ScrollView {
                    UpNextView()
                    
                    HomeSection(title: "Neu erschienen", displaymode: .big, fetchDescriptor: {
                        let now = Date.now
                        let cutOffDate = Date.now.advanced(by: -86400 * 3)
                        
                        var fetchDescriptor = FetchDescriptor<Hoerspiel>(predicate: #Predicate { hoerspiel in
                            hoerspiel.releaseDate < now && hoerspiel.releaseDate > cutOffDate
                        })
                        
                        fetchDescriptor.fetchLimit = 10
                        return fetchDescriptor
                    })
                    
                    HomeSection(title: "Bald verfügbar", displaymode: .rectangular, fetchDescriptor: {
                        let now = Date.now
                        var fetchDescriptor = FetchDescriptor<Hoerspiel>(predicate: #Predicate { hoerspiel in
                            hoerspiel.releaseDate > now
                        })
                        fetchDescriptor.sortBy = [SortDescriptor(\.releaseDate, order: .forward),
                                                  SortDescriptor(\.title)]
                        fetchDescriptor.fetchLimit = 10
                        return fetchDescriptor
                    })
                    
                    HomeSection(title: "Neuheiten", displaymode: .rectangular, fetchDescriptor: {
                        let now = Date.now
                        
                        var fetchDescriptor = FetchDescriptor<Hoerspiel>(predicate: #Predicate { hoerspiel in
                            hoerspiel.releaseDate < now
                        })
                        fetchDescriptor.sortBy = [SortDescriptor(\.releaseDate, order: .reverse)]
                        fetchDescriptor.fetchLimit = 10
                        return fetchDescriptor
                    })
                    
                    HomeSection(title: "Zuletzt gespielt", displaymode: .rectangular, fetchDescriptor: {
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
                    })
                }
            }
            .navigationTitle("Hörspiele")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await musicmanager.playRandom(seriesNames: [])
                        }
                    } label: {
                        Image(systemName: "dice")
                    }
                    .disabled(disableDice)
                }
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
                HoerspielDetailView($0)
            }
            .safeAreaPadding(.bottom, 60)
            .task {
                do {
                    disableDice = try await !MusicSubscription.current.canPlayCatalogContent
                } catch {
                    Logger.authorization.fullError(error, sendToTelemetryDeck: true)
                }
            }
        }
        .trackNavigation(path: "Home")
    }
}
