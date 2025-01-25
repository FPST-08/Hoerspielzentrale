//
//  AlbumListView.swift
//  diedreifragezeichenplayer
//
//  Created by Philipp Steiner on 22.04.24.
//

import OSLog
import SwiftUI

/// `HoerspielListView` is a view that presents an Album within a List
@MainActor
struct HoerspielListView: View {
    // MARK: - Properties
    /// The Hoerspiel that is presented in this view
    let hoerspiel: SendableHoerspiel
    
    /// The image that is displayed as the cover
    @State private var image: Image?
    
    /// An Observable Class responsible for cover caching
    @Environment(ImageCache.self) var imagecache
    
    // MARK: - View
    var body: some View {
        NavigationLink {
            HoerspielDetailView(hoerspiel: hoerspiel)
        } label: {
            HStack {
                if let image {
                    image
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(15)
                        .frame(width: 100, height: 100)
                } else {
                    RoundedRectangle(cornerRadius: 15)
                        .foregroundStyle(Color.clear)
                        .frame(width: 100, height: 100)
                }
                VStack(alignment: .leading, spacing: 0) {
                    Text(hoerspiel.releaseDate != Date.distantPast ?
                         hoerspiel.releaseDate.formatted(date: .numeric, time: .omitted) :
                            "Datum unbekannt")
                        .foregroundStyle(Color.secondary)
                        .font(.subheadline)
                    Text(hoerspiel.title)
                        .foregroundStyle(Color.primary)
                        .font(.body)
                    HStack {
                        PlayPreView(
                            backgroundColor: .playButtonDefaultBackground,
                            textColor: .accentColor,
                            persistentIdentifier: hoerspiel.persistentModelID)
                        Spacer()
                        HoerspielMenuView(persistentIdentifier: hoerspiel.persistentModelID) {
                            Image(systemName: "ellipsis")
                                .foregroundStyle(Color.gray)
                                .font(.title3)
                                .frame(width: 30, height: 30)
                        }
                    }
                }
                .frame(minHeight: 100, maxHeight: 200)
                .dynamicTypeSize(DynamicTypeSize.xSmall...DynamicTypeSize.accessibility5)
            }
        }
        .task {
            if image == nil {
                image = await imagecache.image(for: hoerspiel)
            }
        }
    }
}
