//
//  OnboardingSeriesSearchView.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 22.11.24.
//

@preconcurrency import MusicKit
import SwiftUI

/// A view to search for series from the apple music catalog
struct SeriesSearchView: View {
    // MARK: - Properties
    
    @Environment(SeriesManager.self) var seriesManager
    
    @Environment(\.dismiss) var dismiss
    
    /// The search string
    @State private var searchString = ""
    
    /// The search suggestions
    @State private var searchSuggestions: [MusicCatalogSearchSuggestionsResponse.Suggestion] = []
    
    /// The search results
    @State private var searchResults = [Artist]()
    
    /// A Boolean to present a visible search
    @State private var searchPresented = true
    
    /// Series that a frequently used
    let popularSeries: [String] = [
        "Die drei ???",
        "TKKG",
        "Die drei ??? Kids",
        "John Sinclair",
        "Sherlock Holmes - Die Originale",
        "Fünf Freunde"
    ]
    // MARK: - View
    var body: some View {
        NavigationStack {
            List {
                if searchString.isEmpty {
                    ForEach(popularSeries, id: \.self) { series in
                        Button {
                            searchString = series
                        } label: {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(Color.primary)
                                Text(series)
                                    .foregroundStyle(Color.secondary)
                            }
                        }
                        
                    }
                } else {
                    ForEach(searchSuggestions) { series in
                        Button {
                            searchString = series.searchTerm
                        } label: {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(Color.primary)
                                Text(series.displayTerm)
                                    .foregroundStyle(Color.secondary)
                            }
                        }
                    }
                    ForEach(searchResults) { result in
                        Button {
                            if !(seriesManager.selectedArtists.contains(result) ||
                                 seriesManager.seriesToDownload.contains(result) ||
                                 seriesManager.selectedArtists.contains(result)) {
                                seriesManager.downloadSeries(result)
                            }
                            dismiss()
                        } label: {
                            SeriesSelectionSearchResultView(series: result)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Suche Serien")
            .searchable(text: $searchString, isPresented: $searchPresented, placement: .navigationBarDrawer)
            .onChange(of: searchString) { _, newValue in
                if newValue.isEmpty {
                    searchSuggestions.removeAll()
                    searchResults.removeAll()
                }
                if newValue != "" {
                    Task {
                        await loadSuggestions(for: newValue)
                        await loadEntries(for: newValue)
                    }
                }
            }
            .onSubmit {
                searchSuggestions.removeAll()
                Task {
                    await loadEntries(for: searchString)
                }
            }
        }
        
    }
    // MARK: - Functions
    
    /// Loads the search suggestions for a term
    /// - Parameter term: The term to load suggestions for
    func loadSuggestions(for term: String) async {
        do {
            var request = MusicCatalogSearchSuggestionsRequest(term: term, includingTopResultsOfTypes: [Artist.self])
            request.limit = nil
            let response = try await request.response()
            searchSuggestions = response.suggestions
        } catch {
            print(error)
        }
    }
    
    /// Loads teh search results for a term
    /// - Parameter term: The term to load the results for
    func loadEntries(for term: String) async {
        do {
            var request = MusicCatalogSearchRequest(term: term, types: [Artist.self])
            request.limit = nil
            let response = try await request.response()
            searchResults = []
            searchResults.append(contentsOf: response.artists)
        } catch {
            print(error)
        }
    }
}
