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
    let hoerspiel: SendableHoerspiel
    
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
        GeometryReader { geo in
            ScrollView {
                VStack {
                    if let image {
                        image
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(15)
                            .shadow(radius: 10)
                            .frame(width: geo.size.width * 0.75, height: geo.size.width * 0.75)
                    } else {
                        Rectangle()
                            .foregroundStyle(Color.secondarySystemBackground)
                            .frame(width: geo.size.width * 0.75, height: geo.size.width * 0.75)
                            .cornerRadius(15)
                            .shadow(radius: 10)
                    }
                    
                    Text(hoerspiel.title)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding(.top, 5)
                    Text(hoerspiel.releaseDate != Date.distantPast ?
                                             hoerspiel.releaseDate.formatted(date: .numeric, time: .omitted) :
                                                "Veröffentlichundsdatum unbekannt")
                        .foregroundStyle(Color.secondary)
                        .font(.callout)
                        .padding(.bottom, -5)
                    HStack {
                        Spacer()
                        Button {
                            musicplayer.startPlayback(for: hoerspiel.persistentModelID)
                            requestReviewIfAppropriate()
                        } label: {
                            Label("Wiedergeben", systemImage: "play.fill")
                        }
                        .buttonStyle(DetailPlayButtonStyle())
                        Spacer()
                        Button {
                            Task {
                                try await dataManager.manager.update(
                                    hoerspiel.persistentModelID,
                                    keypath: \.playedUpTo,
                                    to: 0)
                                musicplayer.startPlayback(for: hoerspiel.persistentModelID)
                                requestReviewIfAppropriate()
                            }
                        } label: {
                            Label("Ab Anfang", systemImage: "arrow.circlepath")
                        }
                        .buttonStyle(DetailPlayButtonStyle())
                        Spacer()
                    }
                    .buttonStyle(.prominent)
                    HoerspielMusicDetailsView(hoerspiel: hoerspiel)
                }
                .frame(maxWidth: .infinity)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        HoerspielMenuView(persistentIdentifier: hoerspiel.persistentModelID) {
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
            .navigationTitle(hoerspiel.title)
            .navigationBarTitleDisplayMode(.inline)
            .task {
                image = await imagecache.image(for: hoerspiel)
                TelemetryDeck.signal("Navigation.Detail", parameters: ["Hoerspiel": hoerspiel.title])
                let center = UNUserNotificationCenter.current()
                center.removeDeliveredNotifications(withIdentifiers: [hoerspiel.upc, "PR\(hoerspiel.upc)"])
            }
            .safeAreaPadding(.bottom, 60)
        }
        .trackNavigation(path: "HoerspielDetailView")
        
    }
}
