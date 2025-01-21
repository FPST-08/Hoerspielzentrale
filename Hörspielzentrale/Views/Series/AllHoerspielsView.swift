//
//  AllHoerspielsView.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 20.01.25.
//

import Defaults
import SwiftData
import SwiftUI

/// A parent view used to display all ``Hoerspiel`` by a single series
struct AllHoerspielsView: View {
    /// The series to present
    let series: SendableSeries
    
    @Default(.sortFilter) var sortType
    @Default(.sortAscending) var sortAscending
    @Default(.onlyUnplayed) var onlyUnplayed
    @Default(.allHoerspielDisplayMode) var displayMode
    
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
    
    /// The fetchlimit
    @State private var fetchLimit = 30
    
    /// The searchtext
    @State private var searchText = ""

    var body: some View {
        AllHoerspielsQueryView(sortBy: sortDescriptor,
                               loadMore: { fetchLimit += 30 },
                               fetchLimit: fetchLimit,
                               searchText: searchText,
                               onlyUnplayed: onlyUnplayed,
                               series: series)
        .navigationTitle("Hörspiele von \(series.name)")
        .navigationBarTitleDisplayMode(.inline)
        .padding(.horizontal, 2)
        .safeAreaPadding(.bottom, 60)
        .searchable(text: $searchText, prompt: Text("Suche nach Hörspielen von \(series.name)"))
        .toolbar {
            ToolbarItem {
                Button {
                    displayMode.toggle()
                } label: {
                    Image(systemName: displayMode.currentSystemName)
                }
                
            }
            ToolbarItem {
                Menu("Filter", systemImage: "arrow.up.arrow.down") {
                    Picker(selection: $sortAscending) {
                        Text("Aufsteigend")
                            .tag(true)
                        Text("Absteigend")
                            .tag(false)
                    } label: {
                        Text("Reihenfolge")
                    }
                    Toggle(isOn: $onlyUnplayed) {
                        Text("Nur ungespielt")
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
                        Text("Sortier-Kriterium")
                    }
                }
            }
        }
    }
    
    enum AllHoerspielDisplayMode: Codable, Defaults.Serializable {
        case covers
        case listRows
        
        mutating func toggle() {
            self = self == .covers ? .listRows : .covers
        }
        
        var currentSystemName: String {
            switch self {
            case .covers:
                return "square.grid.3x3"
            case .listRows:
                return "list.bullet"
            }
        }
    }
}
