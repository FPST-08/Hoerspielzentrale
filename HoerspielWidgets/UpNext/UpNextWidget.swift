//
//  UpNextWidget.swift
//  HoerspielWidgetsExtension
//
//  Created by Philipp Steiner on 23.12.24.
//

import SwiftUI
import WidgetKit

/// A widget that displays hoerspiele added to up next
struct UpNextWidget: Widget {
    let kind: String = "UpNextWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: UpNextProvider()) { entry in
            UpNextWidgetEntry(entry: entry)
        }
        .configurationDisplayName("Als Nächstes")
        .description("Höre da weiter, wo du aufgehört hast")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

/// A view that displays hoerspiels added to up next
struct UpNextWidgetEntry: View {
    
    /// The entry of the widget
    var entry: UpNextEntry
    
    /// The size of the widget
    @Environment(\.widgetFamily) var family
    
    /// The color scheme
    @Environment(\.colorScheme) var colorScheme
    
    /// The rendering mode of the widget
    @Environment(\.widgetRenderingMode) var renderingMode
    
    // MARK: - View
    var body: some View {
        Group {
            if entry.data.count >= 1 {
                switch family {
                case .systemSmall:
                    if let data = entry.data.sortByAddedToUpNext()[safe: 0] {
                        DeepLink(hoerspiel: data.hoerspiel) {
                            VStack(alignment: .leading) {
                                if #available(iOSApplicationExtension 18.0, *) {
                                    data.image
                                        .resizable()
                                        .widgetAccentedRenderingMode(.fullColor)
                                        .scaledToFit()
                                        .cornerRadius(7)
                                        .frame(width: 50, height: 50)
                                } else {
                                    data.image
                                        .resizable()
                                        .scaledToFit()
                                        .cornerRadius(7)
                                        .frame(width: 50, height: 50)
                                }
                                Text("\(data.hoerspiel.playedUpTo == 0 ? "Beginnen" : "Fortsetzen")".uppercased())
                                    .fontDesign(.rounded)
                                    .fontWeight(.semibold)
                                    .font(.caption2)
                                    .foregroundStyle(Color.white)
                                    .widgetAccentable()
                                
                                Text(data.hoerspiel.title)
                                    .font(.footnote)
                                    .fontWeight(.medium)
                                    .foregroundStyle(Color.white)
                                
                                Text("""
                                \(data.hoerspiel.artist) · \
                                \(data.hoerspiel.playedUpTo == 0
                                ? "\(data.hoerspiel.duration.formattedDuration())"
                                : "Noch \((data.hoerspiel.duration - TimeInterval(data.hoerspiel.playedUpTo)).formattedDuration())")
                                """)
                                .font(.caption2)
                                .foregroundStyle(Color.secondary)
                                Spacer()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                case .systemMedium:
                    VStack(alignment: .leading) {
                        Text("Als Nächstes")
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.white)
                            .widgetAccentable()
                        if let data = entry.data.sortByAddedToUpNext()[safe: 0] {
                            listRow(hoerspiel: data.hoerspiel, image: data.image)
                        }
                        
                        if let data = entry.data.sortByAddedToUpNext()[safe: 1] {
                            listRow(hoerspiel: data.hoerspiel, image: data.image)
                        }
                        
                    }
                case .systemLarge:
                    VStack(alignment: .leading) {
                        if let data = entry.data.sortByAddedToUpNext()[safe: 0] {
                            DeepLink(hoerspiel: data.hoerspiel) {
                                HStack {
                                    if #available(iOSApplicationExtension 18.0, *) {
                                        entry.data.sortByAddedToUpNext().first!.image
                                            .resizable()
                                            .widgetAccentedRenderingMode(.fullColor)
                                            .scaledToFit()
                                            .cornerRadius(10)
                                            .frame(width: 130, height: 130)
                                    } else {
                                        entry.data.sortByAddedToUpNext().first!.image
                                            .resizable()
                                            .scaledToFit()
                                            .cornerRadius(10)
                                            .frame(width: 130, height: 130)
                                    }
                                    VStack(alignment: .leading) {
                                        Spacer()
                                        Text(data.hoerspiel.title)
                                            .fontWeight(.medium)
                                            .lineLimit(3)
                                            .frame(height: 50, alignment: .bottom)
                                        Text("""
    \(data.hoerspiel.artist) · \
    \(data.hoerspiel.releaseDate.formatted(date: .numeric, time: .omitted)) · \
    \((data.hoerspiel.duration - Double(data.hoerspiel.playedUpTo)).formattedDuration())
    """)
                                        .foregroundStyle(Color.secondary)
                                        .frame(maxHeight: .infinity, alignment: .top)
                                        .font(.caption)
                                    }
                                    .foregroundStyle(Color.white)
                                }
                            }
                        }
                        Spacer()
                        Text("Als Nächstes")
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.white)
                            .widgetAccentable()
                        
                        if let data = entry.data.sortByAddedToUpNext()[safe: 1] {
                            listRow(hoerspiel: data.hoerspiel, image: data.image)
                        }
                        
                        if let data = entry.data.sortByAddedToUpNext()[safe: 2] {
                            listRow(hoerspiel: data.hoerspiel, image: data.image)
                        }
                        
                        if let data = entry.data.sortByAddedToUpNext()[safe: 3] {
                            listRow(hoerspiel: data.hoerspiel, image: data.image)
                        }
                        Spacer()
                    }
                    .padding(.vertical)
                default: Text("Größe nicht untersstützt \(family.description)")
                }
            } else {
                Text("Keine Hörspiele in Als Nächstes vorhanden")
                    .foregroundStyle(Color.white)
                    .bold()
            }
        }
        .containerBackground(for: .widget) {
            if renderingMode == .fullColor && colorScheme == .light {
                ContainerRelativeShape()
                    .fill(Color.pink.gradient)
                
            } else {
                ContainerRelativeShape()
                    .fill(Color.black.gradient)
            }
            
        }
    }
    
    /// The list representation of a Hoerspiel in a widget
    /// - Parameters:
    ///   - hoerspiel: The hoerspiel
    ///   - image: The image
    /// - Returns: Returns a view of a Hoerspiel list representation
    @ViewBuilder
    func listRow(hoerspiel: SendableHoerspiel, image: Image) -> some View {
        DeepLink(hoerspiel: hoerspiel) {
            HStack {
                if #available(iOSApplicationExtension 18.0, *) {
                    image
                        .resizable()
                        .widgetAccentedRenderingMode(.fullColor)
                        .scaledToFit()
                        .cornerRadius(8)
                        .frame(width: 50, height: 50)
                } else {
                    image
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(8)
                        .frame(width: 50, height: 50)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(hoerspiel.title)
                        .font(.footnote)
                        .fontWeight(.medium)
                    Text("""
            \(hoerspiel.artist) · \
            \(hoerspiel.releaseDate.formatted(date: .numeric, time: .omitted)) · \ 
            \(hoerspiel.playedUpTo == 0
            ? "\(hoerspiel.duration.formattedDuration())"
            : "Noch \((hoerspiel.duration - TimeInterval(hoerspiel.playedUpTo)).formattedDuration())")
            """)
                    .font(.caption2)
                    .foregroundStyle(Color.secondary)
                }
                .foregroundStyle(Color.white)
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
    }
}
