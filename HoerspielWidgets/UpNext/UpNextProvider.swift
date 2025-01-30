//
//  UpNextProvider.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 23.12.24.
//

import MusicKit
import OSLog
import SwiftData
import SwiftUI
import TelemetryDeck
import WidgetKit

struct UpNextProvider: TimelineProvider {
    typealias Entry = UpNextEntry
    
    let modelContainer: ModelContainer
    let modelContext: ModelContext
    
    init() {
        do {
            if let appID = Bundle.main.infoDictionary?["TELEMETRYDECKAPPID"] as? String, appID != "" {
                let config = TelemetryDeck.Config(appID: appID)
                TelemetryDeck.initialize(config: config)
                Logger.widgets.info("Initialized TelemetryDeck with \(appID)")
            } else {
                Logger.widgets.warning("Unable to initialize TelemetryDeck")
            }
            modelContainer = try ModelContainer(for: Hoerspiel.self)
            modelContext = ModelContext(modelContainer)
        } catch {
            Logger.widgets.fullError(error, sendToTelemetryDeck: true)
            fatalError("Failed to create the model container: \(error)")
        }
    }
    
    func placeholder(in context: Context) -> UpNextEntry {
        return UpNextEntry(date: Date.now, data: [])
    }
    
    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        Task {
            let data = await getHoerspiele()
            completion(UpNextEntry(date: Date.now, data: data))
        }
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        Task {
            let data = await getHoerspiele()
            let timeline = Timeline(entries: [UpNextEntry(date: Date.now, data: data)], policy: .never)
            completion(timeline)
        }
    }
    
    func getHoerspiele() async -> [HoerspielData] {
        do {
            var fetchDescriptor = FetchDescriptor<Hoerspiel>()
            fetchDescriptor.predicate = #Predicate { hoerspiel in
                hoerspiel.showInUpNext == true
            }
            fetchDescriptor.sortBy = [SortDescriptor(\Hoerspiel.addedToUpNext, order: .reverse),
                                      SortDescriptor(\Hoerspiel.lastPlayed, order: .reverse)]
            fetchDescriptor.fetchLimit = 4
            let hoerspiele = try modelContext.fetch(fetchDescriptor).map { SendableHoerspiel(hoerspiel: $0) }
            
            var returnArray = [HoerspielData]()
            if hoerspiele.isEmpty {
                Logger.widgets.info("No hoerspiele in up next available")
                return []
            }
            let request = MusicCatalogResourceRequest<Album>(matching: \.upc, memberOf: hoerspiele.map { $0.upc })
            
            let response = try await request.response()
            
            for hoerspiel in hoerspiele {
                if let imageURL = response.items
                    .first(where: { $0.upc == hoerspiel.upc })?
                    .artwork?.url(width: 256, height: 256) {
                    let (data, _) = try await URLSession.shared.data(from: imageURL)
                    if let uiimage = UIImage(data: data) {
                        returnArray.append(HoerspielData(hoerspiel: hoerspiel, image: Image(uiImage: uiimage)))
                    }
                }
            }
            return returnArray.sortByAddedToUpNext()
        } catch {
            Logger.widgets.fullError(error)
            return []
        }
    }
}

/// The entry for the ``UpNextWidget``
struct UpNextEntry: TimelineEntry {
    /// The date this widget should be shown
    var date: Date
    
    /// The data for the widget
    let data: [HoerspielData]
}

/// The data for a ``Hoerspiel``
struct HoerspielData {
    /// The hoerspiel of the data
    let hoerspiel: SendableHoerspiel
    /// The image of the hoerspiel
    let image: Image
}

/// The documents directory used to save files
let documentsDirectoryPath: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

extension Array where Element == SendableHoerspiel {
    func sortByAdded() -> [SendableHoerspiel] {
        return self.sorted(by: { $0.addedToUpNext < $1.addedToUpNext })
    }
}
