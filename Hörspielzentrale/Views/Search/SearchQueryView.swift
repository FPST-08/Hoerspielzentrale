//
//  NewSearchListView.swift
//  diedreifragezeichenplayer
//
//  Created by Philipp Steiner on 20.05.24.
//

import MusicKit
import OSLog
import SwiftData
import SwiftUI

/// A view used to present all `Hoerspiele`
///
/// - Note: This view is only intended to be used by ``SearchView``
@MainActor
struct SearchQueryView: View {
    // MARK: - Properties
    /// The `Query` used to load the `Hoerspiel`e
    @Query private var hoerspiele: [Hoerspiel]
    
    /// A closure to remove all filters passed from ``SearchView``
    let removeFilters: () -> Void
    
    /// A function to increase the fetchlimit
    let loadMore: @MainActor () -> Void
    
    /// An Observable Class responsible for navigation
    @Environment(NavigationManager.self) var navigation
    
    /// An Observable Class responsible for data
    @Environment(DataManagerClass.self) var dataManager
    
    /// The string of the text at the end of the list
    var textString: String {
        if hoerspiele.count == 1 {
            return "Gefällt dir dieses Hörspiel nicht?"
        } else {
            return """
\(hoerspiele.count) tolle Hörspiele und du hast keines gefunden?
"""
        }
    }
    
    @State private var multiSelection: Set<PersistentIdentifier> = []
    
    @Environment(\.editMode) var editMode
    
    // MARK: - View
    var body: some View {
        if hoerspiele.isEmpty && navigation.searchText == "" {
            ContentUnavailableView {
                Label("Keine Ergebnisse mit diesen Filtern", systemImage: "arrow.up.arrow.down")
            } description: {
                Text("Suche mit weniger Filtern um Hörspiele angezeigt zu bekommen.")
            } actions: {
                Button("Filter löschen") {
                    removeFilters()
                }
                .buttonStyle(BorderedProminentButtonStyle())
            }
        } else {
            Group {
                if !hoerspiele.isEmpty {
                    List(selection: $multiSelection) {
                        ForEach(hoerspiele) { hoerspiel in
                            HoerspielListView(hoerspiel: SendableHoerspiel(hoerspiel: hoerspiel))
                                .id(hoerspiel.persistentModelID)
                        }
                        Text(textString)
                            .onAppear {
                                loadMore()
                            }
                    }
                    .animation(nil, value: editMode?.wrappedValue)
                    .toolbar {
                        
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                editMode?.wrappedValue = editMode?.wrappedValue.isEditing == true ? .inactive : .active
                            } label: {
                                Label("Auswählen", systemImage: "checklist")
                            }
                        }
                        
                        ToolbarItem(placement: .topBarLeading) {
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
                    }
                    .listStyle(.plain)
                } else {
                    ContentUnavailableView.search(text: navigation.searchText)
                }
            }
            .searchable(text: Bindable(navigation).searchText, isPresented: Bindable(navigation).searchPresented)
            .navigationTitle("Suche")
            .onDisappear {
                editMode?.wrappedValue = .inactive
                navigation.searchPresented = false
            }
        }
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
    
    /// Initializer for ``SearchQueryView``
    /// - Parameters:
    ///   - displayedArtists: The artists marked by the user as shown
    ///   - onlyUnplayed: Indicates if only unplayed `Hoerspiele` should be returned
    ///   - sortBy: A sortDescriptor to sort all visible `Hoerspiele`
    ///   - removeFilters: A closure to remove all filters if applicable
    ///   - fetchLimit: The amount of items loaded for the list
    ///   - loadMore: A closure that increases the fetchlimit
    ///   - searchText: The search text
    init(
        displayedSeries: [SendableSeries],
        onlyUnplayed: Bool,
        sortBy: SortDescriptor<Hoerspiel>,
        removeFilters: @escaping @MainActor () -> Void,
        loadMore: @escaping @MainActor () -> Void,
        searchText: String,
        fetchLimit: Int
    ) {
        let displayedSeriesIDs = displayedSeries.map { $0.musicItemID }
        var descriptor = FetchDescriptor<Hoerspiel>(predicate: #Predicate<Hoerspiel> { hoerspiel in
            if searchText == "" {
                if onlyUnplayed && hoerspiel.played {
                    return false
                } else {
                    if hoerspiel.series == nil {
                        return false
                    } else {
                        return hoerspiel.series.flatMap { series in
                            displayedSeriesIDs.contains(series.musicItemID)
                        } ?? false
                    }
                }
            } else {
                return hoerspiel.title.localizedStandardContains(searchText)
            }
        })
        
        descriptor.fetchLimit = fetchLimit
        descriptor.sortBy = [sortBy]
        
        _hoerspiele = Query(descriptor)
        self.removeFilters = removeFilters
        self.loadMore = loadMore
    }
}
