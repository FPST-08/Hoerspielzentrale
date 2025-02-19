//
//  NewSearchView.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 05.02.25.
//

import Defaults
@preconcurrency import MusicKit
import SwiftData
import SwiftUI

/// A view searching both local and the Apple Music Catalog
struct NewSearchView: View {
    
    /// An Observable Class responsible for navigation
    @Environment(NavigationManager.self) var navigation
    
    /// An Observable Class responsible for data
    @Environment(DataManagerClass.self) var dataManager

    /// The search results
    @State private var searchResults: [SearchResult] = []
    
    /// The current search results task
    @State private var currentTask: Task<(), any Error>?
    
    /// A class resposible for network checks
    @Environment(NetworkHelper.self) var networkHelper
    
    @Default(.searchMode) var searchMode
    
    @Default(.recentlySearched) var recentlySearched
    
    @Query var series: [Series]
    
    var body: some View {
        NavigationStack {
            List {
                if navigation.searchText.isEmpty {
                    if networkHelper.validConnection {
                        RecentlySearchedView()
                    } else if !navigation.searchPresented {
                        ContentUnavailableView("Keine Internetverbindung",
                                               systemImage: "wifi.slash",
                                               description: Text("""
Dein Gerät ist nicht mit dem Internet verbunden. Um die Internetverbindung herzustellen, \
musst du den Flugmodus auschalten oder es mit einem WLAN verbinden.
"""))
                        
                    }
                } else if searchResults.isEmpty {
                    ContentUnavailableView.search
                } else {
                    ForEach(searchResults, id: \.self) { result in
                        switch result {
                        case .album(let album):
                            RecentlySearchedInlineAlbumView(album: album)
                        case .series(let series):
                            RecentlySearchedInlineSeriesView(series: series)
                        case .hoerspiel(let hoerspiel):
                            RecentlySearchedInlineHoerspielView(hoerspiel: hoerspiel)
                        case .artist(let artist):
                            RecentlySearchedInlineArtistView(artist: artist)
                        }
                    }
                }
            }
            .listStyle(PlainListStyle())
            .searchable(text: Bindable(navigation).searchText, isPresented: Bindable(navigation).searchPresented)
            .searchScopes($searchMode, activation: .onSearchPresentation) {
                if networkHelper.connectionStatus == .working && !series.isEmpty {
                    Text("Apple Music").tag(SearchMode.appleMusic)
                    Text("Hörspielzentrale").tag(SearchMode.local)
                }
            }
            .navigationTitle("Suche")
            .onChange(of: navigation.searchText) { _, newValue in
                updateSearchResults(newValue)
            }
            .onSubmit {
                updateSearchResults(navigation.searchText)
            }
            .onChange(of: searchMode) { _, _ in
                updateSearchResults(navigation.searchText)
            }
            .safeAreaPadding(.bottom, 60)
        }
    }
    
    /// Updates the search results
    /// - Parameter value: The search term
    func updateSearchResults(_ searchTerm: String) {
        currentTask?.cancel()
        currentTask = Task {
            if (searchMode == .local || networkHelper.connectionStatus != .working) && !series.isEmpty {
                let hoerspielResults = try? await dataManager.manager.fetch {
                    var descriptor = FetchDescriptor<Hoerspiel>(predicate: #Predicate { hoerspiel in
                        hoerspiel.title.localizedStandardContains(searchTerm)
                    })
                    descriptor.sortBy = [SortDescriptor(\Hoerspiel.lastPlayed)]
                    return descriptor
                }
                let seriesResults = try? await dataManager.manager.fetch {
                    FetchDescriptor<Series>(predicate: #Predicate { series in
                        series.name.localizedStandardContains(searchTerm)
                    })
                }
                try Task.checkCancellation()
                searchResults = []
                searchResults.append(contentsOf: seriesResults?.compactMap { $0 }.map { SearchResult($0)} ?? [])
                searchResults.append(contentsOf: hoerspielResults?.compactMap { $0 }.map { SearchResult($0) } ?? [])
            } else {
                var request = MusicCatalogSearchRequest(term: searchTerm, types: [Artist.self, Album.self])
                request.limit = 20
                let response = try await request.response()
                try Task.checkCancellation()
                var newSearchResults = [SearchResult]()
                newSearchResults.append(contentsOf: response.artists.map { SearchResult($0) })
                newSearchResults.append(contentsOf: response.albums.map { SearchResult($0) })
                try Task.checkCancellation()
                searchResults = newSearchResults
                
            }
        }
    }
}

#Preview {
    NewSearchView()
}

/// The search mode
enum SearchMode: Codable, Defaults.Serializable, Hashable {
    case local
    case appleMusic
    
    /// All cases of the search mode
    static var allCases: [SearchMode] {
        [.local, .appleMusic]
    }
    
    /// The description of the search mode
    var descroption: String {
        switch self {
        case .local:
            return "Hörspielzentrale"
        case .appleMusic:
            return "Apple Music"
        }
    }
}
