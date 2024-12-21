//
//  AlbumView.swift
//  diedreifragezeichenplayer
//
//  Created by Philipp Steiner on 18.04.24.
//

import MediaPlayer
import MusicKit
import OSLog
import SwiftData
import SwiftUI

/// A view that presents a `SendableHoerspiel` in a square
struct HoerspielSquareView: View {
    // MARK: - Properties
    
    /// Referencing an `@Observable` class responsible for loading and caching covers
    @Environment(ImageCache.self) var imageCache
    
    /// The ``hoerspiel`` displayed in this view
    let hoerspiel: SendableHoerspiel
    
    /// The cover of the `hoerspiel`
    @State private var image: Image?
    
    @Namespace var namespace
    
    // MARK: - View
    var body: some View {
        NavigationLink {
            HoerspielDetailView(hoerspiel: hoerspiel)
                .backwardsNavigationTransition("zoom", in: namespace)
        } label: {
            ZStack(alignment: .center) {
                RoundedRectangle(cornerRadius: 13)
                    .frame(width: 230, height: 230)
                    .foregroundStyle(Color.white.opacity(0.3))
                ZStack(alignment: .bottom) {
                    
                    if let image {
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 228, height: 228)
                        
                            .zIndex(0)
                    } else {
                        RoundedRectangle(cornerRadius: 15)
                            .foregroundStyle(Color.black)
                        
                            .zIndex(0)
                    }
                    Rectangle()
                        .fill(.thinMaterial)
                        .frame(height: 60)
                        .mask {
                            VStack(spacing: 0) {
                                LinearGradient(colors: [Color.black.opacity(0),  // sin(x * pi / 2)
                                                        Color.black.opacity(0.383),
                                                        Color.black.opacity(0.707),
                                                        Color.black.opacity(0.924),
                                                        Color.black],
                                               startPoint: .top,
                                               endPoint: .bottom)
                                .frame(height: 40)
                                
                                Rectangle()
                            }
                        }
                        .zIndex(1)
                        .colorScheme(.dark)
                    HStack {
                        PlayPreView(
                            backgroundColor: .playButtonDefaultBackground,
                            textColor: .accentColor,
                            persistentIdentifier: hoerspiel.persistentModelID)
                        Spacer()
                        HoerspielMenuView(persistentIdentifier: hoerspiel.persistentModelID) {
                            Image(systemName: "ellipsis")
                                .foregroundStyle(Color.gray)
                                .font(.title2)
                                .frame(width: 30, height: 30)
                                .background {
                                    Circle()
                                        .foregroundStyle(Color.playButtonDefaultBackground)
                                }
                        }
                    }
                    .padding(.bottom, 10)
                    .padding(.horizontal)
                    .zIndex(2)
                }
                .clipShape(RoundedRectangle(cornerRadius: 15))
            }
            .backwardsMatchedTransitionSource(id: "zoom", in: namespace)
            .frame(width: 230, height: 230)
        }
        .task {
            if image == nil {
                image = await imageCache.image(for: hoerspiel)
            }
        }
        
    }
}
