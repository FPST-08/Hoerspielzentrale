//
//  diedreifragezeichenplayerApp.swift
//  diedreifragezeichenplayer
//
//  Created by Philipp Steiner on 31.03.24.
//

import AppIntents
import BackgroundTasks
import CloudKitSyncMonitor
import Connectivity
import MediaPlayer
import MusicKit
import OSLog
import Roadmap
import SwiftData
import SwiftUI
import TelemetryDeck
import WhatsNewKit

/// Start point of app
@main
struct Hörspielzentrale: App {
    // MARK: - Properties
    /// Creation of MusicManager
    @State var musicmanager: MusicManager

    /// Creation of NavigationManager
    @State var navigationManager: NavigationManager

    /// Creation of imageCache
    @State var imageCache: ImageCache

    /// Creating of dataHandlerClass
    @State var dataManagerClass: DataManagerClass

    /// Creation of ``maintenanceManager``
    @State var maintenanceManager: Maintenance
    
    /// Creation of ``seriesManager``
    @State  var seriesManager: SeriesManager

    /// The current playback state
    @ObservedObject var state = ApplicationMusicPlayer.shared.state

    /// The modelContainer
    let modelContainer: ModelContainer

    @AppStorage("onboarding") var onboarding = true
    
    /// The current scenephase of the app
    @Environment(\.scenePhase) private var phase

    // MARK: - View
    var body: some Scene {
        WindowGroup {
            ContentView()
                .tint(.accent)
                .welcomeSheet()
                .onboarding()
                .whatsNewSheet()
                .maintenance()
                .networkUnavailable()
                .modelContainer(modelContainer)
                .environment(musicmanager)
                .environment(navigationManager)
                .environment(dataManagerClass)
                .environment(imageCache)
                .environment(maintenanceManager)
                .environment(seriesManager)
                .environment(
                    \.whatsNew,
                     WhatsNewEnvironment(
                        versionStore: UserDefaultsWhatsNewVersionStore(),
                        whatsNewCollection: whatsNewCollection,
                        initialBehaviour: .hidden
                     )
                )
                .onChange(of: state.playbackStatus) { oldValue, newValue in
                    Logger.playback.info("Playback status changed")
                    if oldValue == .playing {
                        Task {
                            await musicmanager.saveListeningProgressAsync()
                        }
                    } else if newValue == .playing {
                        Task {
                            await musicmanager.calculateDatesWhilePlaying()
                        }
                    }
                }
                .onOpenURL { incomingURL in
                    TelemetryDeck.signal("App.deeplink", parameters: ["URL": incomingURL.absoluteString])
                    Logger.url.info("App was opened via URL: \(incomingURL)")
                    handleIncomingURL(incomingURL)
                }
                
        }
        .onChange(of: phase) { _, newPhase in
            switch newPhase {
            case .background: scheduleAppRefresh()
            default: break
            }
        }
        .backgroundTask(.appRefresh("newReleasesBackgroundTask")) { _ in
            #if DEBUG
            do {
                do {
                    let content = UNMutableNotificationContent()
                    content.title = "Background-Check started"
                    content.subtitle = "Let's see how it goes"
                    content.sound = UNNotificationSound.default
                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                    let request = UNNotificationRequest(identifier: UUID().uuidString,
                                                        content: content,
                                                        trigger: trigger)
                    try await UNUserNotificationCenter.current().add(request)
                }
                
                let added = try await seriesManager.checkForNewReleases()
                
                do {
                    let content = UNMutableNotificationContent()
                    content.title = "Background-Check finished"
                    content.subtitle = "\(added.count) new hoerspiels were found"
                    content.sound = UNNotificationSound.default
                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                    let request = UNNotificationRequest(identifier: UUID().uuidString,
                                                        content: content,
                                                        trigger: trigger)
                    try await UNUserNotificationCenter.current().add(request)
                }
            } catch {
                Logger.data.fullError(error, sendToTelemetryDeck: true)
            }
            #endif
        }
    }
    
    // MARK: - Functions
    
    /// Schedules and submits all app refreshes
    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "newReleasesBackgroundTask")
        do {
            try BGTaskScheduler.shared.submit(request)
            Logger.data.info("Requested app refresh")
        } catch {
            Logger.data.fullError(error, sendToTelemetryDeck: true)
        }
    }
    
    /// A function called to handle incoming urls
    /// - Parameter url: The url to handle
    private func handleIncomingURL(_ url: URL) {
        guard url.scheme == "hoerspielzentrale" else {
            return
        }
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            Logger.url.error("Invalid URL")
            return
        }
        guard let action = components.host, action == "search" || action == "open-hoerspiel" else {
            Logger.url.error("Unknown URL")
            return
        }
        if action == "search" {
            guard let searchTerm = components.queryItems?.first(where: { $0.name == "term" })?.value else {
                Logger.url.error("Term for search not found")
                Logger.url.debug("\(url)")
                return
            }
            navigationManager.search(for: searchTerm)
        } else if action == "open-hoerspiel" {
            guard let id = components.queryItems?.first(where: { $0.name == "id" })?.value else {
                Logger.url.error("Hoerspiel id not found")
                return
            }
            Task {
                await navigationManager.openHoerspiel(albumID: id)
            }
        }
    }
    // swiftlint:disable function_body_length
    init() {
        if let appID = Bundle.main.infoDictionary?["TELEMETRYDECKAPPID"] as? String, appID != "" {
            let config = TelemetryDeck.Config(appID: appID)
            TelemetryDeck.initialize(config: config)
            Logger.data.info("Initialized TelemetryDeck with \(appID)")
        } else {
            Logger.data.warning("Unable to initialize TelemetryDeck")
            assertionFailure()
        }
        do {
            modelContainer = try ModelContainer(for: Series.self,
                                                configurations: ModelConfiguration(cloudKitDatabase: .automatic)
            )
        } catch {
            Logger.data.fullError(error,
                                  additionalParameters: ["cloudKitDatabase": "automatic"],
                                  sendToTelemetryDeck: true)
            do {
                let localModelContainer = try ModelContainer(for: Hoerspiel.self,
                                                             configurations:
                                                                ModelConfiguration(cloudKitDatabase: .none))
                let fetchedLocals = try localModelContainer.mainContext.fetch(FetchDescriptor<Hoerspiel>())
                var jsonLocal = [SendableHoerspiel]()
                for fetchedLocal in fetchedLocals {
                    jsonLocal.append(SendableHoerspiel(hoerspiel: fetchedLocal))
                }
                let cloudModelContainer = try ModelContainer(for: Hoerspiel.self,
                                                             configurations: ModelConfiguration(
                                                                cloudKitDatabase: .automatic))
                do {
                    let fetchCount = try cloudModelContainer.mainContext.fetchCount(FetchDescriptor<Hoerspiel>())
                    Logger.data.debug("\(fetchCount)")
                }
                try cloudModelContainer.mainContext.delete(model: Hoerspiel.self)
                do {
                    let fetchCount = try cloudModelContainer.mainContext.fetchCount(FetchDescriptor<Hoerspiel>())
                    Logger.data.debug("\(fetchCount)")
                }
                for index in jsonLocal {
                    cloudModelContainer.mainContext.insert(Hoerspiel(from: index))
                }
                do {
                    let fetchCount = try cloudModelContainer.mainContext.fetchCount(FetchDescriptor<Hoerspiel>())
                    Logger.data.debug("\(fetchCount)")
                }
                self.modelContainer = cloudModelContainer
            } catch {
                Logger.data.fullError(error,
                                      additionalParameters: ["cloudKitDatabase": "none"],
                                      sendToTelemetryDeck: true)
                fatalError()
            }
        }
        let dataManager = DataManager(modelContainer: modelContainer)
        self.dataManagerClass = DataManagerClass(manager: dataManager)
        let navigationManager = NavigationManager(dataManager: dataManager)
        self.navigationManager = navigationManager
        
        let imageCache = ImageCache(dataManager: dataManager)
        self.imageCache = imageCache
        
        let musicplayer = MusicManager(dataManager: dataManager, navigation: navigationManager, imageCache: imageCache)
        self.musicmanager = musicplayer
        
        self.seriesManager = SeriesManager(dataManager: dataManager)
        
        self.maintenanceManager = Maintenance(manager: dataManager)
        
        AppDependencyManager.shared.add(dependency: dataManager)
        AppDependencyManager.shared.add(dependency: navigationManager)
        AppDependencyManager.shared.add(dependency: musicplayer)
        AppDependencyManager.shared.add(dependency: imageCache)
        
        HoerspielShortCuts.updateAppShortcutParameters()
        
        Task {
            let status = try? await MusicSubscription.current.description
            TelemetryDeck.signal("App.launched", parameters: ["MusicSubscriptionStatus": status ?? "N/A"])
        }
    }
    // swiftlint:enable function_body_length
}
