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

extension Hörspielzentrale {
    /// Runs the background task and sends notifications accrodingly
    func runBackgroundTask() async {
        do {
            if !UserDefaults.standard[.notificationsEnabled] {
                Logger.backgroundRefresh.info("Notifications are disabled")
                return
            }
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            let upcomingHoerspiels = try await dataManagerClass.manager.fetch {
                let now = Date.now
                var fetchDescriptor = FetchDescriptor<Hoerspiel>(predicate: #Predicate { hoerspiel in
                    hoerspiel.releaseDate > now
                })
                fetchDescriptor.fetchLimit = 64
                return fetchDescriptor
            }
            Logger.backgroundRefresh.info("Found \(upcomingHoerspiels.count) upcoming Hoerspiels")
            for upcoming in upcomingHoerspiels {
                _ = await imageCache.uiimage(for: upcoming)
                Logger.backgroundRefresh.info("Fetched background image")
                let content = UNMutableNotificationContent()
                content.title = "\(upcoming.artist): Neues Hörspiel"
                content.body = "\(upcoming.title) ist jetzt verfügbar"
                
                let url = documentsDirectoryPath.appendingPathComponent("\(upcoming.upc).jpg")
                if let attachment = try? UNNotificationAttachment(identifier: upcoming.upc, url: url) {
                    Logger.backgroundRefresh.info("Attachment found")
                    content.attachments = [attachment]
                } else {
                    Logger.backgroundRefresh.error("Unable to get attachment")
                }
                content.threadIdentifier = upcoming.artist
                content.sound = UNNotificationSound.default
                let dateComponents =  Calendar.current.dateComponents([.year, .month, .day, .hour, .minute],
                                                                      from: upcoming.releaseDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                let request = UNNotificationRequest(identifier: upcoming.upc, content: content, trigger: trigger)
                Logger.backgroundRefresh.info("Requesting notification")
                try await UNUserNotificationCenter.current().add(request)
            }
            
            let addedCodables = try await seriesManager.checkForNewReleases(false)
            Logger.backgroundRefresh.info("Added \(addedCodables.count) to database")
            var added = [SendableHoerspiel]()
            
            for addedCodable in addedCodables {
                if let sendable = try await dataManagerClass.manager.fetch({
                    FetchDescriptor<Hoerspiel>(predicate: #Predicate<Hoerspiel> { hoerspiel in
                        hoerspiel.upc == addedCodable.upc
                    })
                }).first {
                    added.append(sendable)
                }
            }
            Logger.backgroundRefresh.info("Converted to \(added.count) sendables")
            let disabledSeries = UserDefaults.standard[.seriesWithDiabledNotifications]
            Logger.backgroundRefresh.info("Disabled series: \(disabledSeries)")
            let notificationsForPreleases = UserDefaults.standard[.sendNotificationsForPreRelease]
            Logger.backgroundRefresh.info("Notifications for prerelease")
            
            for add in added where !disabledSeries.contains(where: { $0.musicItemID == add.upc }) {
                if (add.releaseDate.isFuture() && notificationsForPreleases) || add.releaseDate.isPast() {
                    let content = UNMutableNotificationContent()
                    _ = await imageCache.uiimage(for: add)
                    
                    let url = documentsDirectoryPath.appendingPathComponent("\(add.upc).jpg")
                    if let attachment = try? UNNotificationAttachment(identifier: add.upc, url: url) {
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
                    }
                    let request = UNNotificationRequest(identifier: add.upc, content: content, trigger: trigger)
                    try await UNUserNotificationCenter.current().add(request)
                } else {
                    Logger.backgroundRefresh.info("Not adding hoerspiel \(add.title)")
                }
            }
        } catch {
            Logger.backgroundRefresh.fullError(error, sendToTelemetryDeck: true)
        }
    }
}
