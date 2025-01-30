//
//  NotificationExtensions.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 11.01.25.
//

import OSLog
import UIKit
import UserNotifications

extension UNNotificationAttachment {
    /// Save the image to disk
    ///
    /// Source: https://stackoverflow.com/questions/45226847/unnotificationattachment-failing-to-attach-image
    static func create(imageFileIdentifier: String, data: NSData) -> UNNotificationAttachment? {
        let fileManager = FileManager.default
        let tmpSubFolderName = ProcessInfo.processInfo.globallyUniqueString
        let tmpSubFolderURL = NSURL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(tmpSubFolderName, isDirectory: true)

        do {
            try fileManager.createDirectory(at: tmpSubFolderURL!, withIntermediateDirectories: true, attributes: nil)
            let fileURL = tmpSubFolderURL?.appendingPathComponent(imageFileIdentifier)
            try data.write(to: fileURL!, options: [])
            let imageAttachment = try UNNotificationAttachment.init(identifier: imageFileIdentifier, url: fileURL!)
            return imageAttachment
        } catch {
            Logger.backgroundRefresh.fullError(error,
                                               additionalParameters: ["imageFileIdentifier": imageFileIdentifier],
                                               sendToTelemetryDeck: true)
        }
        return nil
    }
    
    /// Creates an `UNNotificationAttachment` from an `UIImage` and a UPC
    /// - Parameters:
    ///   - uiimage: The uiimage used as attachment
    ///   - upc: The upc of the corresponsing hoerspiel
    /// - Returns: The correct attachment
    static func create(uiimage: UIImage,
                       upc: String) -> UNNotificationAttachment? {
        guard let data = uiimage.pngData() else {
            return nil
        }
        return UNNotificationAttachment.create(imageFileIdentifier: "\(upc).jpg", data: NSData(data: data))
    }
}
