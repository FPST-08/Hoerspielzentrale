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
    
    /// An Observable Class responsible for navigation
    @Environment(NavigationManager.self) var navigation
    
    /// An Observable Class responsible for data
    @Environment(DataManagerClass.self) var dataManager
    
    /// The multi selection of items
    @Binding private var multiSelection: Set<PersistentIdentifier>
    
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
                    }
                    .animation(nil, value: editMode?.wrappedValue)
                    .listStyle(.plain)
                } else {
                    ContentUnavailableView.search(text: navigation.searchText)
                }
            }
            .searchable(text: Bindable(navigation).searchText, isPresented: Bindable(navigation).searchPresented)
            .navigationTitle("Hörspiele")
            .onDisappear {
                editMode?.wrappedValue = .inactive
                navigation.searchPresented = false
            }
        }
    }
    
    /// Initializer for ``SearchQueryView``
    /// - Parameters:
    ///   - displayedSeries: The series marked by the user as shown
    ///   - onlyUnplayed: Indicates if only unplayed `Hoerspiele` should be returned
    ///   - sortBy: A sortDescriptor to sort all visible `Hoerspiele`
    ///   - removeFilters: A closure to remove all filters if applicable
    ///   - searchText: The search text
    ///   - fetchLimit: The fetch limit
    ///   - multiSelection: The multi selection of items
    init(
        displayedSeries: [SendableSeries],
        onlyUnplayed: Bool,
        sortBy: SortDescriptor<Hoerspiel>,
        removeFilters: @escaping @MainActor () -> Void,
        searchText: String,
        fetchLimit: Int?,
        multiSelection: Binding<Set<PersistentIdentifier>>
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
        descriptor.sortBy = [sortBy]
        descriptor.fetchLimit = fetchLimit
        _hoerspiele = Query(descriptor)
        self.removeFilters = removeFilters
        _multiSelection = multiSelection
    }
}
