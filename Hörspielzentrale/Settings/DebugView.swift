//
//  DebugView.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 13.06.24.
//

import OSLog
import SwiftData
import SwiftUI
import WidgetKit

#if DEBUG
/// A view used to accelerate the debug process by providing common isolated functionality
///
/// - Note: This view should never be visible to users
struct DebugView: View {
    // MARK: - Properties
    @Environment(ImageCache.self) var imagecache
    @Environment(\.modelContext) var modelContext
    @Environment(DataManagerClass.self) var dataManager
    @Environment(Maintenance.self) var maintenanceManager
    @Environment(BackgroundActivities.self) var backgroundActivities
    // MARK: - View
    var body: some View {
        List {
            // MARK: - Data
            Section {
                Button("Check for required maintenance") {
                    maintenanceManager.checkForRequiredMaintenance()
                }
                
                Button("Add random hoerspiel to up next") {
                    Task {
                        
                        let identifiers = try? await dataManager.manager.fetchIdentifiers( {
                            var descriptor = FetchDescriptor<Hoerspiel>()
                            descriptor.fetchLimit = 1
                            descriptor.fetchOffset = Int.random(in: 0..<100)
                            return descriptor
                        })
                        
                        guard let identifier = identifiers?.first else {
                            return
                        }
                        try? await dataManager.manager.update(identifier, keypath: \.showInUpNext, to: true)
                    }
                    
                }
                
                Button("Delete all data") {
                    Task {
                        try? await dataManager.manager.delete(model: Hoerspiel.self)
                        try? await dataManager.manager.delete(model: Series.self)
                    }
                }
                
                Text("""
                     Count of all entities:
                     \(String(describing: try? modelContext.fetchCount(FetchDescriptor<Hoerspiel>())))
""")
                Text("""
Count of all artists: \(String(describing: try? modelContext.fetchCount(FetchDescriptor<Series>())))
""")
                Button("Delete all tracks") {
                    do {
                        let hoerspiele = try modelContext.fetch(FetchDescriptor<Hoerspiel>())
                        for hoerspiel in hoerspiele {
                            hoerspiel.tracks = []
                        }
                        try modelContext.save()
                        Logger.data.info("Removed all tracks")
                    } catch {
                        Logger.data.fullError(error, sendToTelemetryDeck: false)
                    }
                }
                
                Button("Change random release date to near future") {
                    Task {
                        do {
                            let hoerspiel = try await dataManager.manager.fetchRandom({FetchDescriptor<Hoerspiel>()})
                            try await dataManager.manager.update(hoerspiel,
                                                                 keypath: \.releaseDate,
                                                                 to: Date().advanced(by: 86400))
                        } catch { }
                    }
                }
                
                Button("Load all images with correct size and save") {
                    Task {
                        do {
                            let ids = try await dataManager.manager.fetchIdentifiers({ FetchDescriptor<Hoerspiel>() })
                            for id in ids {
                                let hoerspiel = try await dataManager.manager.batchRead(id)
                                _ = await imagecache.uiimage(for: hoerspiel)
                                
                            }
                            Logger.data.debug("Finished loading images")
                        } catch {
                            Logger.data.fullError(error, sendToTelemetryDeck: false)
                        }
                    }
                }
                Button("Request Notification Permission") {
                    Task {
                        do {
                            let center = UNUserNotificationCenter.current()
                            try await center.requestAuthorization(options: [.alert, .badge, .sound])
                        } catch {
                            Logger.data.fullError(error, sendToTelemetryDeck: false)
                        }
                    }
                }
            } header: {
                Text("Data")
            }
            
            Section {
                Button("Delete 5 Hoerspiels and run background activity") {
                    Task {
                        do {
                            UNUserNotificationCenter.current().removeAllDeliveredNotifications()
                            var desc = FetchDescriptor<Hoerspiel>(sortBy: [SortDescriptor(\Hoerspiel.releaseDate, order: .reverse)])
                            desc.fetchLimit = 5
                            let models = try modelContext.fetch(desc)
                            for model in models {
                                modelContext.delete(model)
                            }
                            try await Task.sleep(for: .seconds(5))

                            await backgroundActivities.runBackgroundTask()
                        } catch {
                            Logger.backgroundRefresh.fullError(error, sendToTelemetryDeck: false)
                        }
                        
                    }
                }
            } header: {
                Text("Background-Activities")
            }
            
            // MARK: - Network
            Section {
                Button("Reload Widget Timelines", action: WidgetCenter.shared.reloadAllTimelines)
            } header: {
                Text("Widgetkit")
            }
        }
        .navigationTitle("Debug")
    }
}

#endif
