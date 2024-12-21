//
//  AppIntent.swift
//  HoerspielWidgets
//
//  Created by Philipp Steiner on 01.07.24.
//

import WidgetKit
import AppIntents
// swiftlint:disable trailing_whitespace
/// The app intent used to configure widgets
struct ConfigurationAppIntent: WidgetConfigurationIntent {
    /// The title of the app intent
    static var title: LocalizedStringResource = "Konfiguration"
    
    /// The description of the app intent
    static var description = IntentDescription("Entdecke neue Hörspielfolgen aus der Hörspielzentrale")
    
    /// The series that should be displayed
    @Parameter(title: "Serien", default: .all)
    var seriesfilter: SeriesFilter
    /// Indicating if only a ``Hoerspiel`` marked as `unplayed` should be displayed
    @Parameter(title: "Nur ungespielt", default: true)
    var onlyUnplayed: Bool
}

enum SeriesFilter: String, AppEnum {
    case fragezeichen, kids, all
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "SeriesFilter"
    static var caseDisplayRepresentations: [SeriesFilter: DisplayRepresentation] = [
        .fragezeichen: "Fragezeichen",
        .kids: "Kids",
        .all: "Beide"
    ]
}
// swiftlint:enable trailing_whitespace
