//
//  NotificationView.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 22.12.24.
//

import Defaults
import OSLog
@preconcurrency import SwiftUI
import TelemetryDeck

/// A view to change the notification behaviour
struct NotificationView: View {
    // MARK: Properties
    /// All series
    @State private var series = [SendableSeries]()
    
    /// An Observable Class responsible for data
    @Environment(DataManagerClass.self) var dataManager
    
    /// The current view state
    @State private var viewState: ViewState = .loading
    
    /// All series that have notifications disabled
    @Default(.seriesWithDiabledNotifications) var seriesWithDisalbedNotifications
    
    /// A general boolean to toggle all notifications on or off
    @Default(.notificationsEnabled) var notificationsEnabled
    
    /// The NotificationCenter
    let center = UNUserNotificationCenter.current()
    
    /// The current authorization status
    @State private var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    /// The current scene phase of the app
    ///
    /// This is used to refresh the authorization status if the user comes back from settings
    @Environment(\.scenePhase) var scenePhase
    
    // MARK: View
    var body: some View {
        Group {
            switch viewState {
            case .loading:
                ProgressView("Serien werden geladen")
            case .loaded:
                List {
                    Section {
                        VStack(alignment: .center) {
                            ZStack {
                                ContainerRelativeShape()
                                    .foregroundStyle(.red)
                                Image(systemName: "bell.badge")
                                    .padding(10)
                                    .font(.title.weight(.semibold))
                                    .foregroundStyle(.white)
                            }
                            .frame(width: 60, height: 60)
                            .cornerRadius(10)
                            Text("Benachrichtigungen")
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text("Erhalte eine Mitteilung, wenn neue Hörspiele verfügbar sind")
                                .multilineTextAlignment(.center)
                            Divider()
                            Defaults.Toggle("Benachrichtigungen aktiviert", key: .notificationsEnabled)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    if authorizationStatus == .denied && notificationsEnabled {
                        Section {
                            Text("Mitteilungen sind nicht erlaubt")
                            Button("Mitteilungen in Einstellungen erlauben") {
                                if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            }
                        }
                    }
                    
                    Section {
                        ForEach(series) { series in
                                                NotificationSeriesView(series: series)
                                            }
                    }
                    
                    Section {
                        Defaults.Toggle("Vorveröffentlichungen", key: .sendNotificationsForPreRelease)
                    } footer: {
                        Text("Erhalte Benachrichtigungen, wenn eine Vorveröffentlichung eines Hörspiels erscheint")
                    }
                }
            case .failed(let error):
                ContentUnavailableView("Es ist ein Fehler aufgetreten",
                                       systemImage: "exclamationmark.triangle",
                                       description: Text(error.localizedDescription))
            }
        }
        .trackNavigation(path: "Notifications")
        .task {
            do {
                if series.isEmpty {
                    viewState = .loading
                    series = try await dataManager.manager.fetchAllSeries().sorted { $0.name < $1.name }
                    viewState = .loaded
                }
            } catch {
                viewState = .failed(error: error)
                Logger.data.fullError(error, sendToTelemetryDeck: true)
            }
            let settings = await center.notificationSettings()
            _ = try? await center.requestAuthorization(options: [.alert, .badge, .sound, .provisional])
            authorizationStatus = settings.authorizationStatus
        }
        .onChange(of: scenePhase) { _, _ in
            Task {
                let settings = await center.notificationSettings()
                authorizationStatus = settings.authorizationStatus
            }
        }
    }
    
    /// An enum to represent the current view state
    enum ViewState {
        case loading, loaded, failed(error: Error)
    }
}
