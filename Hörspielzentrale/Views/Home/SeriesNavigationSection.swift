//
//  SeriesNavigationSection.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 21.01.25.
//

import SwiftUI

struct SeriesNavigationSection: View {
    let series: SendableSeries
    
    @State private var image: Image?
    
    @Environment(ImageCache.self) var imageCache
    
    @Environment(MusicManager.self) var musicManager
    
    var body: some View {
        NavigationLink {
            SeriesDetailView(series: series)
        } label: {
            HStack(alignment: .center, spacing: 5) {
                image?
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                Text(series.name)
                    .foregroundStyle(Color.primary)
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundStyle(Color.primary.opacity(0.5))
                Spacer()
                Button {
                    Task {
                        await musicManager.playRandom(seriesNames: [series.name])
                    }
                } label: {
                    Image(systemName: "dice")
                        .padding(10)
                        .background {
                            Circle()
                                .foregroundStyle(Material.regular)
                        }
                        .fontWeight(.regular)
                        .font(.title3)
                        .padding(.horizontal)
                }
            }
            .padding(.leading, 15)
            .fontWeight(.bold)
            .font(.title2)
            .padding(.top, 10)
        }
        .task {
            image = await imageCache.image(for: series)
        }
    }
}
