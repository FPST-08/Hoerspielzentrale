//
//  AllHoerspielsQueryView.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 20.01.25.
//

import Defaults
import SwiftData
import SwiftUI

/// A view used to be present all ``Hoerspiel`` by a single ``Series``
struct AllHoerspielsQueryView: View {
    @Query var hoerspiele: [Hoerspiel]
    
    /// A function to increase the fetchlimit
    let loadMore: () -> Void
    
    @Default(.allHoerspielDisplayMode) var displayMode
    
    /// The columns of the grid
    let columns = [
        GridItem(.adaptive(minimum: 120))
    ]
    
    var body: some View {
        switch displayMode {
        case .covers:
            ScrollView {
                LazyVGrid(columns: columns) {
                    ForEach(hoerspiele) { hoerspiel in
                        HoerspielDisplayView(SendableHoerspiel(hoerspiel: hoerspiel), .coverOnly)
                    }
                    Color.clear
                        .onAppear {
                            loadMore()
                        }
                }
            }
        case .listRows:
            List {
                ForEach(hoerspiele) { hoerspiel in
                    HoerspielListView(hoerspiel: SendableHoerspiel(hoerspiel: hoerspiel))
                }
                Color.clear
                    .onAppear {
                        loadMore()
                    }
            }
            .listStyle(PlainListStyle())
        }
    }
    
    init(
        sortBy sortOrder: SortDescriptor<Hoerspiel>,
        loadMore: @escaping @MainActor () -> Void,
        fetchLimit: Int,
        searchText: String,
        onlyUnplayed: Bool,
        series: SendableSeries
    ) {
        var descriptor = FetchDescriptor<Hoerspiel>()
        let musicItemID = series.musicItemID
        descriptor.predicate = #Predicate { hoerspiel in
            if hoerspiel.series?.musicItemID != musicItemID {
                return false
            } else {
                if searchText.isEmpty {
                    if onlyUnplayed {
                        return !hoerspiel.played
                    } else {
                        return true
                    }
                } else {
                    return hoerspiel.title.localizedStandardContains(searchText)
                }
            }
        }
        descriptor.sortBy = [sortOrder]
        descriptor.fetchLimit = fetchLimit
        _hoerspiele = Query(descriptor)
        self.loadMore = loadMore
    }
}
