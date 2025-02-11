//
//  HoerspielDetailView.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 01.07.24.
//

import Defaults
import MusicKit
import OSLog
import SwiftData
import SwiftUI
import TelemetryDeck

/// A view used to display information about a ``Hoerspiel``
@MainActor
struct HoerspielDetailView: View {
    // MARK: - Properties
    
    @Environment(\.dismiss) var dismiss
    
    /// The hoerspiel to display
    @State private var hoerspiel: SendableHoerspiel?
    
    @State private var album: Album?
    
    /// The title of the entity
    let title: String
    
    /// The release date of the entity
    var releaseDate: Date? {
        if let albumData = album?.releaseDate {
            return albumData
        } else if let hoerspielDate = hoerspiel?.releaseDate {
            return hoerspielDate
        } else {
            return nil
        }
    }
    
    /// The cover of the ``Hoerspiel``
    @State private var image: Image?
    
    /// Referencing an `Observable` class responsible for playback
    @Environment(MusicManager.self) var musicplayer
    /// An Observable Class responsible for data
    @Environment(DataManagerClass.self) var dataManager
    /// An Observable Class responsible for navigation
    @Environment(NavigationManager.self) var navigation
    /// Referencing an `@Observable` class responsible for loading and caching covers
    @Environment(ImageCache.self) var imagecache
    
    // MARK: - View
    var body: some View {
        ScrollView {
            VStack {
                if let image {
                    image
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(15)
                        .shadow(radius: 10)
                        .coverFrame()
                } else {
                    Rectangle()
                        .foregroundStyle(Color.secondarySystemBackground)
                        .cornerRadius(15)
                        .shadow(radius: 10)
                        .coverFrame()
                }
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(.top, 5)
                Text(releaseDate?.formatted(date: .numeric, time: .omitted) ??
                        "Veröffentlichundsdatum unbekannt")
                .foregroundStyle(Color.secondary)
                .font(.callout)
                .padding(.bottom, -5)
                HStack {
                    Spacer()
                    Button {
                        if let hoerspiel {
                            musicplayer.startPlayback(for: hoerspiel.persistentModelID)
                            requestReviewIfAppropriate()
                        } else {
                            navigation.presentAlert(title: "Hörspiel nicht hinzugefügt",
                                                    description: """
Die Serie des Hörspiels ist nicht zur Mediathek hinzugefügt. \ 
Füge die Serie hinzu, um dieses Hörspiel abspielen zu können
""")
                        }
                    } label: {
                        Label("Wiedergeben", systemImage: "play.fill")
                    }
                    .buttonStyle(DetailPlayButtonStyle())
                    Spacer()
                    Button {
                        if let hoerspiel {
                            Task {
                                try await dataManager.manager.update(
                                    hoerspiel.persistentModelID,
                                    keypath: \.playedUpTo,
                                    to: 0)
                                musicplayer.startPlayback(for: hoerspiel.persistentModelID)
                                requestReviewIfAppropriate()
                            }
                        } else {
                            navigation.presentAlert(title: "Hörspiel nicht hinzugefügt",
                                                    description: """
Die Serie des Hörspiels ist nicht zur Mediathek hinzugefügt. \
Füge die Serie hinzu, um dieses Hörspiel abspielen zu können
""")
                        }
                    } label: {
                        Label("Ab Anfang", systemImage: "arrow.circlepath")
                    }
                    .buttonStyle(DetailPlayButtonStyle())
                    Spacer()
                }
                .buttonStyle(.prominent)
                HoerspielMusicDetailsView(hoerspiel, album)
            }
            .frame(maxWidth: .infinity)
            .toolbar {
                if let persistentModelID = hoerspiel?.persistentModelID {
                    ToolbarItem(placement: .topBarTrailing) {
                        HoerspielMenuView(persistentIdentifier: persistentModelID) {
                            Image(systemName: "ellipsis")
                                .padding(10)
                                .background {
                                    Circle()
                                        .foregroundStyle(Color.secondarySystemBackground)
                                }
                        }
                    }
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if let album, hoerspiel == nil {
                if let upc = album.upc {
                    hoerspiel = try? await dataManager.manager.fetch({
                        var fetchDescriptor = FetchDescriptor<Hoerspiel>(predicate: #Predicate<Hoerspiel> { hoerspiel in
                            hoerspiel.upc == upc
                        })
                        fetchDescriptor.fetchLimit = 1
                        return fetchDescriptor
                    }).first
                }
            }
            if let hoerspiel {
                image = await imagecache.image(for: hoerspiel, size: .fullResolution)
                let center = UNUserNotificationCenter.current()
                center.removeDeliveredNotifications(withIdentifiers: [hoerspiel.upc, "PR\(hoerspiel.upc)"])
            } else {
                guard let artworkURL = album?.artwork?.url(width: 512, height: 512) else {
                    return
                }
                guard let (data, _) = try? await URLSession.shared.data(from: artworkURL) else {
                    return
                }
                guard let uiimage = UIImage(data: data) else {
                    return
                }
                image = Image(uiImage: uiimage)
            }
        }
        .safeAreaPadding(.bottom, 60)
        .trackNavigation(path: "HoerspielDetailView")
    }
    
    /// Creates the view from a hoerspiel
    /// - Parameter hoerspiel: The hoerspiel
    init(_ hoerspiel: SendableHoerspiel) {
        self.hoerspiel = hoerspiel
        self.title = hoerspiel.title
    }
    
    /// Creates the view from an album
    /// - Parameter album: The album
    init(_ album: Album) {
        self.album = album
        self.title = album.title
    }
}
