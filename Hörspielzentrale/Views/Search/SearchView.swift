//
//  SplitSearchView.swift
//  diedreifragezeichenplayer
//
//  Created by Philipp Steiner on 20.05.24.
//

import Defaults
import MusicKit
import OSLog
import SwiftData
import SwiftUI
import TelemetryDeck

/// A view used to set the sorting behaviour of ``SearchQueryView``
struct SearchView: View {
    // MARK: - Properties
    /// Referencing an `Observable` class responsible for playback
    @Environment(MusicManager.self) var musicplayer
    /// An Observable Class responsible for navigation
    @Environment(NavigationManager.self) var navigation
    @Environment(DataManagerClass.self) var dataManager
    @Environment(SeriesManager.self) var seriesManager
    
    /// An Observable Class handling Maintenance
    @Environment(Maintenance.self) var maintenanceManager
    
    @Default(.sortFilter) var sortType
    
    @AppStorage("sortAscending") private var sortAscending = false
    @AppStorage("onlyUnplayed") private var onlyUnplayed = false
    
    /// A computed property combining the `sortType` and the `Order` into a `SortDescriptor`
    var sortDescriptor: SortDescriptor<Hoerspiel> {
        switch sortType {
        case .duration:
            return SortDescriptor(\Hoerspiel.duration, order: sortAscending ? .forward : .reverse)
        case .releaseDate:
            return SortDescriptor(\Hoerspiel.releaseDate, order: sortAscending ? .forward : .reverse)
        case .title:
            return SortDescriptor(\Hoerspiel.title, order: sortAscending ? .forward : .reverse)
        case .lastPlayed:
            return SortDescriptor(\Hoerspiel.lastPlayed, order: sortAscending ? .forward : .reverse)
        }
    }
    
    @Environment(\.dismiss) var dismiss
    
    @State private var disableDice = true
    
    @State private var allArtists = [SendableSeries]()
    
    @Default(.displayedSortArtists) var displayedArtists
    
    @State private var fetchLimit = 10
    
    @State private var state = ViewState.loading
    
    @Environment(\.editMode) var editMode
    
    // MARK: - View
    var body: some View {
        NavigationStack(path: Bindable(navigation).searchPath) {
            Group {
                switch state {
                case .loading:
                    ProgressView()
                case .error:
                    ContentUnavailableView("Es ist ein Fehler aufgetreten", systemImage: "exclamationmark.triangle")
                case .loaded:
                    SearchQueryView(
                        displayedSeries: displayedArtists,
                        onlyUnplayed: onlyUnplayed,
                        sortBy: sortDescriptor,
                        removeFilters: {
                            onlyUnplayed = false
                            displayedArtists = allArtists
                            navigation.searchText = ""
                        }, loadMore: {
                            fetchLimit += 10
                        }, searchText: navigation.searchText,
                        fetchLimit: fetchLimit
                        
                    )
                    .safeAreaPadding(.bottom, 60)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                TelemetryDeck.signal("Playback.dice",
                                                     parameters: [
                                                        "onlyUnplayed": onlyUnplayed.description,
                                                        "sortingAscending": sortAscending.description
                                                     ])
                                Task {
                                    disableDice = true
                                    let displayedArtists = UserDefaults.standard[.displayedSortArtists]
                                    let seriesNames = displayedArtists.map { $0.name }
                                    await musicplayer.playRandom(seriesNames: seriesNames)
                                    disableDice = false
                                }
                            } label: {
                                Label("Zufällig", systemImage: "dice")
                            }
                            .disabled(disableDice)
                            .task {
                                do {
                                    disableDice = try await !MusicSubscription.current.canPlayCatalogContent
                                } catch {
                                    Logger.authorization.fullError(error, sendToTelemetryDeck: true)
                                }
                            }
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            Menu {
                                Picker(selection: $sortAscending) {
                                    Text("Aufsteigend")
                                        .tag(true)
                                    Text("Absteigend")
                                        .tag(false)
                                } label: {
                                    Text("Order of sorting")
                                }
                                Picker(selection: $sortType) {
                                    Text("Titel")
                                        .tag(SortingType.title)
                                    Text("Dauer")
                                        .tag(SortingType.duration)
                                    Text("Erscheinungsdatum")
                                        .tag(SortingType.releaseDate)
                                    Text("Zuletzt gespielt")
                                        .tag(SortingType.lastPlayed)
                                } label: {
                                    Text("Sorting by")
                                }
                                Toggle("Nur ungespielt", isOn: $onlyUnplayed)
                                Divider()
                                ForEach(allArtists) { artist in
                                    Toggle(artist.name, isOn: Binding<Bool>(
                                        get: {
                                            return displayedArtists.contains(where: { $0.id == artist.id }) == true
                                        },
                                        set: { isSelected in
                                            if isSelected {
                                                displayedArtists.append(artist)
                                            } else {
                                                displayedArtists.removeAll(where: { $0.id == artist.id })
                                            }
                                        }
                                    ))
                                }
                            } label: {
                                Image(systemName: "arrow.up.arrow.down")
                            }
                            .menuActionDismissBehavior(.disabled)
                        }
                    }
                }
            }
            .refreshable {
                do {
                    try await seriesManager.checkForNewReleases()
                    TelemetryDeck.signal("Data.refreshed")
                } catch {
                    let hapticGen = UINotificationFeedbackGenerator()
                    hapticGen.notificationOccurred(.error)
                    Logger.data.fullError(error, sendToTelemetryDeck: true)
                }
                Task {
                    await seriesManager.fetchUpdatesFromMusicLibrary()
                }
            }
            .task {
                do {
                    allArtists = try await dataManager.manager.fetchAllSeries()
                    if displayedArtists.isEmpty {
                        displayedArtists = allArtists
                    }
                    state = .loaded
                } catch {
                    Logger.data.fullError(error, sendToTelemetryDeck: true)
                    state = .error
                }
            }
            .navigationDestination(for: SendableHoerspiel.self) { hoerspiel in
                HoerspielDetailView(hoerspiel: hoerspiel)
            }
            .navigationDestination(for: Hoerspiel.self) { hoerspiel in
                HoerspielDetailView(hoerspiel: SendableHoerspiel(hoerspiel: hoerspiel))
            }
            .trackNavigation(path: "Search")
        }
    }
    
    enum ViewState {
        case loading, loaded, error
    }
}
