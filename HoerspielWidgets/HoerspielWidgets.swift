//
//  Ho_rspielzentraleWidgetExtension.swift
//  HörspielzentraleWidgetExtension
//
//  Created by Philipp Steiner on 21.06.24.
//

import WidgetKit
import MusicKit
import SwiftData
import SwiftUI
import OSLog
import AppIntents
import Network
import TelemetryDeck

/// The entry point of the target
@main
struct HoerspielWidgetsBundle: WidgetBundle {
    var body: some Widget {
        HoerspielzentraleWidgetExtension()
    }
}

// swiftlint:disable trailing_whitespace
/// A struct working as the timeline provider
struct Provider: AppIntentTimelineProvider {
    let modelContainer: ModelContainer
    let modelContext: ModelContext
    
    init() {
        do {
            TelemetryDeck.initialize(config: .init(appID: "CF8103B9-95DE-446F-8435-C740A2FAA8BE"))
            modelContainer = try ModelContainer(for: Hoerspiel.self)
            modelContext = ModelContext(modelContainer)
        } catch {
            fatalError("Failed to create the model container: \(error)")
        }
    }
    
    /// The amount of widget entries to render from a single ``timeline(for:in:)``
    static var widgetsInAdvance = 5
    
    /// Creates a placeholder for the widget picker
    /// - Parameter context: The context of the current widget
    /// - Returns: Returns an ``SimpleEntry`` used as the preview
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date.now, configuration: ConfigurationAppIntent(), error: .preview, hoerspiele: [])
    }
    
    /// Creates a single correct entry for the widget picker
    /// - Parameters:
    ///   - configuration: The default config for the widget
    ///   - context: The context of the current widget
    /// - Returns: Returns an ``SimpleEntry`` used as the preview
    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        var displayHoerspiele = [DisplayHoerspiel]()
        guard let hoerspiele = try? modelContext.fetch(FetchDescriptor<Hoerspiel>()) else {
            return SimpleEntry(
                date: Date.now,
                configuration: ConfigurationAppIntent(),
                error: .failedLoadingHoerspiel,
                hoerspiele: [])
        }
        for index in 0..<4 {
            let hoerspiel = hoerspiele[index]
            guard let album = try? await hoerspiel.album() else {
                return SimpleEntry(
                    date: Date.now,
                    configuration: ConfigurationAppIntent(),
                    error: .failedLoadingAlbum,
                    hoerspiele: [])
            }
            
            let image = await loadImage(for: album)
            
            let id = album.id
            guard let url = URL(string: "hoerspielzentrale://open-hoerspiel?id=\(id)") else {
                return SimpleEntry(
                    date: Date.now,
                    configuration: ConfigurationAppIntent(),
                    error: .failedUnwrappingURL,
                    hoerspiele: [])
            }
            
            guard let image = image else {
                
                let monitor = NWPathMonitor()
                if monitor.currentPath.status != .satisfied {
                    return SimpleEntry(
                        date: Date.now,
                        configuration: ConfigurationAppIntent(),
                        error: .noNetworkConnection,
                        hoerspiele: [])
                }
                return SimpleEntry(
                    date: Date.now,
                    configuration: ConfigurationAppIntent(),
                    error: .failedLoadingImage,
                    hoerspiele: [])
            }
            displayHoerspiele.append(DisplayHoerspiel(image: image, url: url))
        }
        return SimpleEntry(date: Date.now, configuration: configuration, error: nil, hoerspiele: displayHoerspiele)
    }
    // swiftlint:disable function_body_length
    // swiftlint:disable cyclomatic_complexity
    /// Creates the entries for all widgets
    /// - Parameters:
    ///   - configuration: The config of the widget
    ///   - context: The context of the current widget
    /// - Returns: Returns a `Timeline` with `Entries`
    func timeline(
        for configuration: ConfigurationAppIntent,
        in context: Context
    ) async -> Timeline<SimpleEntry> {
        TelemetryDeck.signal(
            "Widget.timeline",
            parameters: [
                "family": context.family.description,
                "onlyUnplayed": configuration.onlyUnplayed.description,
                "filter": configuration.seriesfilter.localizedStringResource.key])
        var entries = [SimpleEntry]()
        
        var hoerspiele = [Hoerspiel]()

        let currentDate = Date()
        
        for hourOffset in 0 ..< Provider.widgetsInAdvance {
            do {
                var descriptor = FetchDescriptor<Hoerspiel>()
                
                if configuration.onlyUnplayed {
                    switch configuration.seriesfilter {
                    case .fragezeichen:
                        descriptor = FetchDescriptor<Hoerspiel>(predicate: #Predicate { hoerspiel in
                            hoerspiel.playedUpTo == 0 && hoerspiel.artist == "Die drei ???"
                        })
                    case .kids:
                        descriptor = FetchDescriptor<Hoerspiel>(predicate: #Predicate { hoerspiel in
                            hoerspiel.playedUpTo == 0 && hoerspiel.artist == "Die drei ??? Kids"
                        })
                    case .all:
                        descriptor = FetchDescriptor<Hoerspiel>(predicate: #Predicate { hoerspiel in
                            hoerspiel.playedUpTo == 0
                        })
                    }
                } else {
                    switch configuration.seriesfilter {
                    case .fragezeichen:
                        descriptor = FetchDescriptor<Hoerspiel>(predicate: #Predicate { hoerspiel in
                            hoerspiel.artist == "Die drei ???"
                        })
                    case .kids:
                        descriptor = FetchDescriptor<Hoerspiel>(predicate: #Predicate { hoerspiel in
                            hoerspiel.artist == "Die drei ??? Kids"
                        })
                    case .all:
                        descriptor = FetchDescriptor<Hoerspiel>()
                    }
                }

                let count = try modelContext.fetchCount(descriptor)
                if count <= Provider.widgetsInAdvance {
                    let entry = SimpleEntry(
                        date: Date.now,
                        configuration: ConfigurationAppIntent(),
                        error: .failedLoadingHoerspiel,
                        hoerspiele: [])
                    return Timeline(entries: [entry], policy: .after(Date.now.advanced(by: 3600)))
                }
                
                descriptor.fetchLimit = Provider.widgetsInAdvance
                descriptor.fetchOffset = Int.random(in: 0...count - Provider.widgetsInAdvance)
                hoerspiele = try modelContext.fetch(descriptor)
            } catch {
                Logger.widgets.fullError(error)
            }
            Logger.widgets.debug("\(hoerspiele[0].title)")
            Logger.widgets.debug("\(hoerspiele[1].title)")
            Logger.widgets.debug("\(hoerspiele[2].title)")

            do {
                let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
                
                var displayHoerspiele = [DisplayHoerspiel]()
                
                for index in 0..<4 {
                    let hoerspiel = hoerspiele[index]
                    let album = try await hoerspiel.album()
                    
                    guard let album = album else {
                        let entry = SimpleEntry(
                            date: Date.now,
                            configuration: ConfigurationAppIntent(),
                            error: .failedLoadingAlbum,
                            hoerspiele: [])
                        return Timeline(entries: [entry], policy: .after(Date.now.advanced(by: 3600)))
                    }
                    
                    let image = await loadImage(for: album)
                    
                    let id = album.id
                    guard let url = URL(string: "hoerspielzentrale://open-hoerspiel?id=\(id)") else {
                        let entry = SimpleEntry(
                            date: Date.now,
                            configuration: ConfigurationAppIntent(),
                            error: .failedUnwrappingURL,
                            
                            hoerspiele: [])
                        return Timeline(entries: [entry], policy: .after(Date.now.advanced(by: 3600)))
                    }
                    
                    guard let image = image else {
                        
                        let monitor = NWPathMonitor()
                        if monitor.currentPath.status != .satisfied {
                            let entry = SimpleEntry(
                                date: Date.now,
                                configuration: ConfigurationAppIntent(),
                                error: .noNetworkConnection,
                                hoerspiele: [])
                            return Timeline(entries: [entry], policy: .after(Date.now.advanced(by: 3600)))
                        }
                        let entry = SimpleEntry(
                            date: Date.now,
                            configuration: ConfigurationAppIntent(),
                            error: .failedLoadingImage,
                            hoerspiele: [])
                        return Timeline(entries: [entry], policy: .after(Date.now.advanced(by: 3600)))
                    }
                    displayHoerspiele.append(DisplayHoerspiel(image: image, url: url))
                    
                }
                
                let entry = SimpleEntry(
                    date: entryDate,
                    configuration: configuration,
                    error: nil,
                    hoerspiele: displayHoerspiele)
                entries.append(entry)
            } catch {
                Logger.widgets.fullError(error)
            }
        }
        
        guard !hoerspiele.isEmpty else {
            let entry = SimpleEntry(
                date: Date.now,
                configuration: ConfigurationAppIntent(),
                error: .failedLoadingHoerspiel,
                hoerspiele: [])
            return Timeline(entries: [entry], policy: .after(Date.now.advanced(by: 3600)))
        }
        
        return Timeline(entries: entries, policy: .atEnd)
    }
    // swiftlint:enable function_body_length
    // swiftlint:enable cyclomatic_complexity
    
    /// Loads the cover for an album
    /// - Parameter album: The album to load the cover for
    /// - Returns: The cover with size `400 x 400` if available
    func loadImage(for album: Album) async -> Image? {
        let url = album.artwork!.url(width: 400, height: 400)!
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let uiimage = UIImage(data: data) else {
                return nil
            }
            let image = Image(uiImage: uiimage)
            Logger.widgets.info("Successfully loaded artwork")
            return image
        } catch {
            return nil
        }
    }
}

/// The `Entry`used for Widgets
struct SimpleEntry: TimelineEntry {
    
    /// The time the entry should appear
    var date: Date
    
    /// The app intent to configure the widhet
    let configuration: ConfigurationAppIntent
    
    /// A possible error while creating the timeline
    let error: WidgetError?
    
    /// The hoerpsiele used for this entry
    let hoerspiele: [DisplayHoerspiel]
}

/// The `Hoerspiel` displayed at widgets
struct DisplayHoerspiel {
    /// The cover of the ``DisplayHoerspiel``
    let image: Image
    /// The url the ``DisplayHoerspiel`` will open
    let url: URL
}

/// An error used to communicate timeline creation errors
enum WidgetError: Error, LocalizedError {
    case failedLoadingAlbum
    case failedLoadingHoerspiel
    case failedLoadingCurrentAlbum
    case failedLoadingImage
    case failedUnwrappingURL
    case noNetworkConnection
    case preview
    
    public var errorDescription: String? {
            switch self {
            case .failedLoadingAlbum:
                "Ein Album konnte nicht geladen werden"
            case .failedLoadingHoerspiel:
                "Ein Hörspiel konnte nicht geladen werden"
            case .failedLoadingCurrentAlbum:
                "Das aktuelle Hörspiel konnte nicht geladen werden"
            case .failedLoadingImage:
                "Ein Cover konnte nicht geladen werden"
            case .failedUnwrappingURL:
                "Eine URL ist ungültig"
            case .noNetworkConnection:
                "Keine Internet-Verbindung"
            case .preview:
                "Preview"
            }
        }
}

extension Hoerspiel {
    /// Loads the `album` matching self
    /// - Returns: Returns the matching album 
    func album() async throws -> Album? {
        let itemID = MusicItemID(self.albumID)
        let albumRequest = MusicCatalogResourceRequest<Album>(matching: \.id, memberOf: [itemID])
        
        let albumResponse = try? await albumRequest.response()
        
        if let album = albumResponse?.items.first {
            return album
        } else {
            Logger.widgets.error(
                """
Unable to get response from albumRequest with id \(self.albumID) upc \(self.upc) and title \(self.title)
""")
        }
        let searchRequest = MusicCatalogSearchRequest(term: self.title, types: [Album.self])
        let searchResponse = try? await searchRequest.response()
        if let album = searchResponse?.albums.first(where: { $0.upc == self.upc }) {
            return album
        }
        Logger.widgets.error("Couldn't get album with json id nor get album with custom fetch for title")
        return nil
    }
}
// swiftlint:enable trailing_whitespace
