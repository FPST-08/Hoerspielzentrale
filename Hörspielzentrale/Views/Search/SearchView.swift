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
    
    @State private var allArtists = [SendableSeries]()
    
    @Default(.displayedSortArtists) var displayedArtists
    
    @State private var state = ViewState.loaded
    
    @State private var fetchLimit: Int? = 10
    
    @Environment(\.editMode) var editMode
    
    /// The multi selection of items
    @State private var multiSelection: Set<PersistentIdentifier> = []
    
    // MARK: - View
    var body: some View {
        NavigationStack(path: Bindable(navigation).searchPath) {
            Group {
                switch state {
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
                        }, searchText: navigation.searchText,
                        fetchLimit: fetchLimit,
                        multiSelection: $multiSelection
                    )
                    .safeAreaPadding(.bottom, 60)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            if editMode?.wrappedValue.isEditing == true {
                                Menu {
                                    Button("Als gespielt markieren", systemImage: "rectangle.badge.checkmark") {
                                        updateAll(keypath: \.played, to: true)
                                    }
                                    Button("Als ungespielt markieren", systemImage: "rectangle.badge.minus") {
                                        updateAll(keypath: \.played, to: false)
                                    }
                                    Button("Zu als Nächstes hinzufügen", systemImage: "plus.circle") {
                                        updateAll(keypath: \.showInUpNext, to: true)
                                        updateAll(keypath: \.addedToUpNext, to: Date.now)
                                    }
                                    Button("Von als Nächstes entfernen", systemImage: "minus.circle") {
                                        updateAll(keypath: \.showInUpNext, to: false)
                                    }
                                    Button("Bookmark zum Anfang", systemImage: "arrow.uturn.left") {
                                        updateAll(keypath: \.playedUpTo, to: 0)
                                    }
                                } label: {
                                    Label("Menü", systemImage: "ellipsis.circle")
                                }
                                
                            }
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                editMode?.wrappedValue = editMode?.wrappedValue.isEditing == true ? .inactive : .active
                            } label: {
                                Label("Auswählen", systemImage: "checklist")
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
            .task {
                do {
                    allArtists = try await dataManager.manager.fetchAllSeries()
                    if displayedArtists.isEmpty {
                        displayedArtists = allArtists
                    }
                    try? await Task.sleep(for: .seconds(1.5))
                    fetchLimit = nil
                } catch {
                    Logger.data.fullError(error, sendToTelemetryDeck: true)
                    state = .error
                }
            }
            .navigationDestination(for: SendableHoerspiel.self) { hoerspiel in
                HoerspielDetailView(hoerspiel)
            }
            .navigationDestination(for: Hoerspiel.self) { hoerspiel in
                HoerspielDetailView(SendableHoerspiel(hoerspiel: hoerspiel))
            }
            .trackNavigation(path: "HoerspielList")
        }
    }
    
    enum ViewState {
        case loaded, error
    }
    
    func updateAll<T: Hashable>(
        keypath: ReferenceWritableKeyPath<Hoerspiel, T>,
        to value: T
    ) {
        Task {
            for identifier in multiSelection {
                try? await dataManager.manager.update(identifier,
                                                      keypath: keypath,
                                                      to: value)
            }
        }
    }
}
