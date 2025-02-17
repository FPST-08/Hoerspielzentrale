//
//  NewContentView.swift
//  diedreifragezeichenplayer
//
//  Created by Philipp Steiner on 10.04.24.
//
//

import Defaults
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
    
    /// The order of sections in the home view
    @Default(.homeOrder) var homeOrder
    
    /// A boolean to show the reordering sheet
    @State private var showReorderSheet = false
    
    // MARK: - View
    var body: some View {
        NavigationStack(path: Bindable(navigation).homePath) {
            VStack {
                ScrollView {
                    UpNextView()
                    
                    HomeSections()
                    
                    Button {
                        showReorderSheet = true
                    } label: {
                        Label("Anordnen", systemImage: "checklist")
                    }
                    .padding()
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
            .sheet(isPresented: $showReorderSheet) {
                List {
                    Section {
                        ForEach(homeOrder) { item in
                            HStack {
                                Text(item.description)
                                Spacer()
                                Image(systemName: "line.3.horizontal")
                                    .foregroundStyle(Color.secondary)
                            }
                        }
                        .onMove { origin, destination in
                            homeOrder.move(fromOffsets: origin, toOffset: destination)
                        }
                    } footer: {
                        Text("Bewege die Abschnitte um diese neu anzuordnen")
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .trackNavigation(path: "Home")
    }
}
