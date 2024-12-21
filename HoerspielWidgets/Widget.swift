//
//  Widget.swift
//  HoerspielWidgetsExtension
//
//  Created by Philipp Steiner on 02.07.24.
//

import WidgetKit
import SwiftUI

// swiftlint:disable trailing_whitespace
/// The widget specifying all its information
struct HoerspielzentraleWidgetExtension: Widget {
    let kind: String = "HoerspielzentraleWidgetExtension"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            WidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Vorschläge")
        .description("Entdecke neue Hörspielfolgen aus der Hörspielzentrale")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

/// The view used by all widgets
struct WidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var widgetFamily: WidgetFamily
    
    var body: some View {
        
        ZStack {
            ContainerRelativeShape()
                .foregroundStyle(.black)
            
                if let error = entry.error {
                    if error == .preview {
                        ZStack {
                            switch widgetFamily {
                            case .systemSmall:
                                Rectangle()
                                    .foregroundStyle(Color.random)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            case .systemMedium:
                                HStack(spacing: 0) {
                                    Rectangle()
                                        .foregroundStyle(Color.random)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    Rectangle()
                                        .foregroundStyle(Color.random)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                }
                            case .systemLarge:
                                VStack(spacing: 0) {
                                    HStack(spacing: 0) {
                                        Rectangle()
                                            .foregroundStyle(Color.random)
                                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        Rectangle()
                                            .foregroundStyle(Color.random)
                                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    }
                                    HStack(spacing: 0) {
                                        Rectangle()
                                            .foregroundStyle(Color.random)
                                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        Rectangle()
                                            .foregroundStyle(Color.random)
                                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    }
                                }
                            default:
                                Text("Das Widget sollte nicht verfügbar sein")
                            }
                            
                            Text("""
\(widgetFamily == .systemSmall ? 
                                 "Hier ist ein zufälliges Cover von einem Hörspiel" :
                                 "Hier stehen zufällige Cover von Hörspielen")
""")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .multilineTextAlignment(.center)
                            
                        }
                    } else {
                        ZStack {
                            ContainerRelativeShape()
                                .foregroundStyle(Color.orange.gradient)
                            VStack {
                                Text("Ein Fehler ist aufgetreten")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                Text(error.localizedDescription)
                                
                            }
                        }
                    }
                } else if entry.hoerspiele.count == 4 {
                    switch widgetFamily {
                    case .systemSmall:
                        AlbumCoverView(displayHoerspiel: entry.hoerspiele[0])
                    case .systemMedium:
                        HStack(spacing: 0) {
                            AlbumCoverView(displayHoerspiel: entry.hoerspiele[0])
                            AlbumCoverView(displayHoerspiel: entry.hoerspiele[1])
                        }
                    case .systemLarge:
                        VStack(spacing: 0) {
                            HStack(spacing: 0) {
                                AlbumCoverView(displayHoerspiel: entry.hoerspiele[0])
                                AlbumCoverView(displayHoerspiel: entry.hoerspiele[1])
                            }
                            HStack(spacing: 0) {
                                AlbumCoverView(displayHoerspiel: entry.hoerspiele[2])
                                AlbumCoverView(displayHoerspiel: entry.hoerspiele[3])
                            }
                        }
                    default:
                        Text("Das Widget sollte nicht verfügbar sein")
                    }
                } else {
                    Text("Ein interner Fehler ist aufgetreten")
                }
        }
    }
}
// swiftlint:enable trailing_whitespace
