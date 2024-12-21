//
//  AppIntent.swift
//  HörspielzentraleWidgetExtension
//
//  Created by Philipp Steiner on 21.06.24.
//

import AppIntents
import Foundation

/// A class responsible for ShortCuts
class HoerspielShortCuts: AppShortcutsProvider {
    /// The short cut tile color
    static var shortcutTileColor = ShortcutTileColor.red
    
    /// An array of App Short Cuts
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: OpenHoerspiel(),
                    phrases: [
                        "Öffne ein Hörspiel in der \(.applicationName)"
                    ],
                    shortTitle: "Hörspiel öffnen",
                    systemImageName: "arrow.turn.right.up")
        
        AppShortcut(intent: PlayHoerspiel(),
                    phrases: ["Spiele ein Hörspiel in der \(.applicationName)"],
                    shortTitle: "Hörspiel abspielen",
                    systemImageName: "play.fill")
        
        AppShortcut(intent: StopPlayback(),
                    phrases: ["Wiedergabe in der \(.applicationName) pausieren",
                              "Wiedergabe in der \(.applicationName) stoppen"],
                    shortTitle: "Wiedergabe stoppen",
                    systemImageName: "stop.circle")
    }
}
