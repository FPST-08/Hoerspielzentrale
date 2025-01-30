//
//  BackgroundTasks.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 22.12.24.
//

import Foundation
import OSLog
import SwiftData
@preconcurrency import SwiftUI

@MainActor
@Observable
class BackgroundActivities {
    
    let seriesManager: SeriesManager
    
    let manager: DataManager
    
    let imageCache: ImageCache
    
    init(seriesManager: SeriesManager,
         dataManager: DataManager,
         imageCache: ImageCache
    ) {
        self.seriesManager = seriesManager
        self.manager = dataManager
        self.imageCache = imageCache
    }
    
    // swiftlint:disable line_length
    /// Runs the background task and sends notifications accrodingly
    ///
    /// Trigger this task via this command in lldb:
    /// ```lldb
    /// e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"newReleasesBackgroundTask"]
    /// ```
    func runBackgroundTask() async { // swiftlint:disable:this function_body_length
        // swiftlint:disable:previous cyclomatic_complexity
        // swiftlint:enable line_length
        do {
            let added = try await seriesManager.checkForNewReleasesInBackground()
            Logger.backgroundRefresh.info("Added \(added.count) to database")
            
            if !UserDefaults.standard[.notificationsEnabled] {
                Logger.backgroundRefresh.info("Notifications are disabled")
                return
            }
            _ = try? await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound, .provisional])
            let authStatus = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
            
            guard authStatus == .provisional || authStatus == .authorized else {
                Logger.backgroundRefresh.info("Notifications are disabled")
                return
            }
            
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            
            // MARK: - Add new Hoerspiels
            
            Logger.backgroundRefresh.info("Converted to \(added.count) sendables")
            let disabledSeries = UserDefaults.standard[.seriesWithDiabledNotifications]
            Logger.backgroundRefresh.info("Disabled series: \(disabledSeries)")
            let notificationsForPreleases = UserDefaults.standard[.sendNotificationsForPreRelease]
            Logger.backgroundRefresh.info("Notifications for prerelease")
            
            Logger.backgroundRefresh.info("\(added.map { $0.series?.musicItemID ?? "N/A"})")
            
            var requests = [UNNotificationRequest]()
            
            // swiftlint:disable:next line_length
            for add in added where !disabledSeries.contains(where: { $0.musicItemID == add.series?.musicItemID ?? "" }) {
                let isPast = add.releaseDate.isPast()
                let isFuture = add.releaseDate.isFuture()
                if (isFuture && notificationsForPreleases) || isPast {
                    let content = UNMutableNotificationContent()
                    let uiimage = await imageCache.uiimage(for: add)
                    
                    if let uiimage, let attachment = UNNotificationAttachment.create(uiimage: uiimage, upc: add.upc) {
                        content.attachments = [attachment]
                    }
                    content.threadIdentifier = add.artist
                    content.sound = UNNotificationSound.default
                    content.userInfo = ["url": "hoerspielzentrale://open-hoerspiel?upc=\(add.upc)"]
                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                    if add.releaseDate.isPast() {
                        content.title = "\(add.artist): Neues Hörspiel"
                        content.body = "\(add.title) ist jetzt verfügbar"
                    } else {
                        content.title = "\(add.artist): Vorveröffentlichung"
                        content.body = "\(add.title) erscheint am \(add.releaseDate.formatted(date: .abbreviated, time: .omitted))"
                        // swiftlint:disable:previous line_length
                    }
                    let request = UNNotificationRequest(identifier: add.upc, content: content, trigger: trigger)
                    requests.append(request)
                } else {
                    Logger.backgroundRefresh.info("Not adding hoerspiel \(add.title)")
                }
            }
            
            for request in requests {
                do {
                    try await UNUserNotificationCenter.current().add(request)
                    Logger.backgroundRefresh.info("Requested notification: \(request)")
                } catch {
                    Logger.backgroundRefresh.fullError(error, sendToTelemetryDeck: true)
                }
            }
            
            // MARK: - Handle upcoming Hoerspiels
            let upcomingHoerspiels = try await manager.fetch {
                let now = Date.now
                var fetchDescriptor = FetchDescriptor<Hoerspiel>(predicate: #Predicate { hoerspiel in
                    hoerspiel.releaseDate > now
                })
                fetchDescriptor.fetchLimit = 64
                return fetchDescriptor
            }
            Logger.backgroundRefresh.info("Found \(upcomingHoerspiels.count) upcoming Hoerspiels")
            
            for upcoming in upcomingHoerspiels {
                let uiimage = await imageCache.uiimage(for: upcoming)
                Logger.backgroundRefresh.info("Fetched image")
                let content = UNMutableNotificationContent()
                content.title = "\(upcoming.artist): Neues Hörspiel"
                content.body = "\(upcoming.title) ist jetzt verfügbar"
                if let uiimage {
                    if let attachment = UNNotificationAttachment.create(uiimage: uiimage, upc: upcoming.upc) {
                        Logger.backgroundRefresh.info("Attachment found")
                        content.attachments = [attachment]
                    } else {
                        Logger.backgroundRefresh.error("Unable to get attachment")
                    }
                } else {
                    Logger.backgroundRefresh.error("Unable to get image")
                }
                content.threadIdentifier = upcoming.artist
                content.sound = UNNotificationSound.default
                let dateComponents =  Calendar.current.dateComponents([.year, .month, .day, .hour, .minute],
                                                                      from: upcoming.releaseDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                let request = UNNotificationRequest(identifier: "PR\(upcoming.upc)", content: content, trigger: trigger)
                Logger.backgroundRefresh.info("Requesting notification")
                try await UNUserNotificationCenter.current().add(request)
            }
        } catch {
            Logger.backgroundRefresh.fullError(error, sendToTelemetryDeck: true)
        }
    }
}
