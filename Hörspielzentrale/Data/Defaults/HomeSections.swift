//
//  HomeSections.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 17.02.25.
//

import Defaults
import SwiftData
import SwiftUI

struct HomeSections: View {
    
    @Default(.homeOrder) var homeOrder
    
    var body: some View {
        ForEach(homeOrder) { entry in
            switch entry {
            case .brandNew:
                HomeSection(title: "Neu erschienen", displaymode: .big, fetchDescriptor: {
                    let now = Date.now
                    let cutOffDate = Date.now.advanced(by: -86400 * 3)
                    
                    var fetchDescriptor = FetchDescriptor<Hoerspiel>(predicate: #Predicate { hoerspiel in
                        hoerspiel.releaseDate < now && hoerspiel.releaseDate > cutOffDate
                    })
                    
                    fetchDescriptor.fetchLimit = 10
                    return fetchDescriptor
                })
            case .soonAvailable:
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
            case .recentlyReleased:
                HomeSection(title: "Neuheiten", displaymode: .rectangular, fetchDescriptor: {
                    let now = Date.now
                    
                    var fetchDescriptor = FetchDescriptor<Hoerspiel>(predicate: #Predicate { hoerspiel in
                        hoerspiel.releaseDate < now
                    })
                    fetchDescriptor.sortBy = [SortDescriptor(\.releaseDate, order: .reverse)]
                    fetchDescriptor.fetchLimit = 10
                    return fetchDescriptor
                })
            case .recentlyPlayed:
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
    }
}
