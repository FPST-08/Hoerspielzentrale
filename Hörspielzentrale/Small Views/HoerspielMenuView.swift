//
//  HoerspielMenuView.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 01.06.24.
//

import OSLog
import SwiftData
import SwiftUI

/// A menu that offers quick actions for a ``Hoerspiel`` across the app
struct HoerspielMenuView<Content: View>: View {
    // MARK: - Properties
    /// The persistentIdentifer of the hoerspiel that is represented in this menu
    let persistentIdentifier: PersistentIdentifier
    
    /// A view that will be used as the label of the menu
    @ViewBuilder let content: Content
    
    /// Referencing an `Observable` class responsible for playback
    @Environment(MusicManager.self) var musicplayer
    @Environment(DataManagerClass.self) var dataManager
    
    /// A Query used to update the menu
    @Query private var hoerspiele: [Hoerspiel]
    
    // MARK: - View
    var body: some View {
        if let hoerspiel = hoerspiele.first {
            Menu {
                Button {
                    Task(priority: .high) {
                        do {
                            if hoerspiel.played {
                                try await dataManager.manager.update(
                                    persistentIdentifier,
                                    keypath: \.played,
                                    to: false)
                                try await dataManager.manager.update(
                                    persistentIdentifier,
                                    keypath: \.playedUpTo,
                                    to: 0)
                            } else {
                                try await dataManager.manager.update(
                                    persistentIdentifier,
                                    keypath: \.played,
                                    to: true)
                                try await dataManager.manager.update(
                                    persistentIdentifier,
                                    keypath: \.showInUpNext,
                                    to: false)
                                try await dataManager.manager.update(
                                    persistentIdentifier,
                                    keypath: \.playedUpTo,
                                    to: 0)
                            }
                        } catch {
                            Logger.data.fullError(error, sendToTelemetryDeck: true)
                        }
                    }
                } label: {
                    if hoerspiel.played {
                        Label("Als ungespielt markieren", systemImage: "rectangle.badge.minus")
                            .font(.body)
                    } else {
                        Label("Als gespielt markieren", systemImage: "rectangle.badge.checkmark")
                            .font(.body)
                    }
                }
                Button {
                    Task {
                        try? await dataManager.manager.update(persistentIdentifier, keypath: \.playedUpTo, to: 0)
                        await musicplayer.startPlayback(for: persistentIdentifier)
                    }
                } label: {
                    Label("Von Anfang an", systemImage: "arrow.uturn.left")
                        .font(.body)
                }
                
                ShareLink(item: URL(string: "hoerspielzentrale://open-hoerspiel?upc=\(hoerspiel.upc)")!) {
                    Label("Teilen", systemImage: "square.and.arrow.up")
                        .font(.body)
                }
                
                Button(role: hoerspiel.showInUpNext ? .destructive : .none) {
                    Task {
                        do {
                            try await dataManager.manager.update(
                                persistentIdentifier,
                                keypath: \.showInUpNext,
                                to: !hoerspiel.showInUpNext)
                            try await dataManager.manager.update(
                                persistentIdentifier,
                                keypath: \.addedToUpNext,
                                to: Date.now)
                        } catch {
                            Logger.data.fullError(error, sendToTelemetryDeck: true)
                        }
                    }
                } label: {
                    if hoerspiel.showInUpNext {
                        Label("Von als Nächstes entfernen", systemImage: "minus.circle")
                            .font(.body)
                    } else {
                        Label("Zu als Nächstes hinzufügen", systemImage: "plus.circle")
                            .font(.body)
                    }
                }
                
#if DEBUG
                Button("Löschen", role: .destructive) {
                    Task {
                        do {
                            try await dataManager.manager.delete(persistentIdentifier)
                        } catch {
                            Logger.data.fullError(error, sendToTelemetryDeck: false)
                        }
                    }
                }
                .font(.body)
#endif
            } label: {
                content
            }
        } else {
            content
        }
    }
    
    init(persistentIdentifier: PersistentIdentifier, @ViewBuilder content: () -> Content) {
        self.persistentIdentifier = persistentIdentifier
        self.content = content()
        _hoerspiele = Query(filter: #Predicate<Hoerspiel> { hoerspiel in
            hoerspiel.persistentModelID == persistentIdentifier
        })
    }
}
