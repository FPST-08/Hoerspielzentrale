//
//  NotificationSeriesView.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 22.12.24.
//

import Defaults
import SwiftUI

/// A view to modify the notification behaviour of a single Hoerspiel
struct NotificationSeriesView: View {
    // MARK: - Properties
    
    /// The series to present
    let series: SendableSeries
    
    /// The image of the series
    @State private var image: Image?
    
    /// Referencing an `@Observable` class responsible for loading and caching covers
    @Environment(ImageCache.self) var imageCache
    
    /// An array of ``SendableSeries`` that have notifications disabled
    @Default(.seriesWithDiabledNotifications) var seriesWithDisalbedNotifications
    
    // MARK: - View
    var body: some View {
        HStack {
            Group {
                if let image {
                    image
                        .resizable()
                } else {
                    Rectangle()
                        .foregroundStyle(Color.secondary)
                }
            }
            .frame(width: 50, height: 50)
            .cornerRadius(5)
            Text(series.name)
            Spacer()
            Toggle(series.name, isOn: Binding<Bool>(
                get: {
                    !seriesWithDisalbedNotifications.contains(where: { $0.musicItemID == series.musicItemID })
                },
                set: { isSelected in
                    if isSelected {
                        seriesWithDisalbedNotifications.removeAll(where: { $0.musicItemID == series.musicItemID })
                    } else {
                        seriesWithDisalbedNotifications.append(series)
                    }
                }
            ))
                .labelsHidden()
        }
        .task {
            image = await imageCache.image(for: series)
        }
    }
}
