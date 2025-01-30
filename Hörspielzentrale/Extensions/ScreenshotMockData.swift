//
//  ScreenshotMockData.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 29.01.25.
//

import Foundation

#if DEBUG
struct ScreenShotSeries {
    var name: String
    var hoerspiele: [ScreenShotHoerspiel]
}

struct ScreenShotHoerspiel {
    var title: String
    var duration: TimeInterval
    var releaseDate: Date
    var lastPlayed: Date
    
    init(title: String) {
        self.title = title
        self.duration = TimeInterval(Int.random(in: 1200...4800))
        self.releaseDate = Date.from(day: Int.random(in: 0..<30),
                                     month: Int.random(in: 1..<13),
                                     year: Int.random(in: 0..<3) + 2022)
        self.lastPlayed = self.releaseDate.advanced(by: Double(Int.random(in: 0..<10) * 86400))
    }
}

let screenshotSeries = [
    ScreenShotSeries(name: "Echo der Schatten", hoerspiele: [
        ScreenShotHoerspiel(title: "Flüstern im Nebel"),
        ScreenShotHoerspiel(title: "Das verborgene Zimmer"),
        ScreenShotHoerspiel(title: "Der verschwundene Schlüssel"),
        ScreenShotHoerspiel(title: "Stimmen aus der Vergangenheit"),
        ScreenShotHoerspiel(title: "Der Mann ohne Gesicht"),
        ScreenShotHoerspiel(title: "Die letzte Nachricht"),
        ScreenShotHoerspiel(title: "Schatten im Spiegel"),
        ScreenShotHoerspiel(title: "Der Kreis der Echos"),
        ScreenShotHoerspiel(title: "Das vergessene Versteck"),
        ScreenShotHoerspiel(title: "Der dunkle Anruf")
    ]),
    ScreenShotSeries(name: "Nebelpfad", hoerspiele: [
        ScreenShotHoerspiel(title: "Der Ruf des Nebels"),
        ScreenShotHoerspiel(title: "Die Stadt hinter dem Schleier"),
        ScreenShotHoerspiel(title: "Das Tor der verlorenen Seelen"),
        ScreenShotHoerspiel(title: "Fluch des Ewigen Königs"),
        ScreenShotHoerspiel(title: "Die silberne Klinge"),
        ScreenShotHoerspiel(title: "Der geheime Pakt"),
        ScreenShotHoerspiel(title: "Schattenwesen"),
        ScreenShotHoerspiel(title: "Der zerbrochene Zauber"),
        ScreenShotHoerspiel(title: "Das letzte Licht"),
        ScreenShotHoerspiel(title: "Der Pfad des Vergessens")
    ]),
    ScreenShotSeries(name: "Codename: Aurora", hoerspiele: [
        ScreenShotHoerspiel(title: "Operation Mitternacht"),
        ScreenShotHoerspiel(title: "Die Doppelgängerin"),
        ScreenShotHoerspiel(title: "Codex Omega"),
        ScreenShotHoerspiel(title: "Jäger und Gejagte"),
        ScreenShotHoerspiel(title: "Verrat in Prag"),
        ScreenShotHoerspiel(title: "Schatten über Genf"),
        ScreenShotHoerspiel(title: "Der rote Bote"),
        ScreenShotHoerspiel(title: "Tödliches Signal"),
        ScreenShotHoerspiel(title: "Countdown zum Chaos"),
        ScreenShotHoerspiel(title: "Der letzte Auftrag")
    ]),
    ScreenShotSeries(name: "Die Stimmenjäger", hoerspiele: [
        ScreenShotHoerspiel(title: "Das Flüstern in der Wand"),
        ScreenShotHoerspiel(title: "Der Sender aus dem Jenseits"),
        ScreenShotHoerspiel(title: "Nacht der verlorenen Stimmen"),
        ScreenShotHoerspiel(title: "Das geheime Tonband"),
        ScreenShotHoerspiel(title: "Frequenz 666"),
        ScreenShotHoerspiel(title: "Der Gesang der Toten"),
        ScreenShotHoerspiel(title: "Stille im Äther"),
        ScreenShotHoerspiel(title: "Die verbotene Melodie"),
        ScreenShotHoerspiel(title: "Schreie aus der Tiefe"),
        ScreenShotHoerspiel(title: "Das Echo des Grauens")
    ]),
    ScreenShotSeries(name: "Zeitsturm", hoerspiele: [
        ScreenShotHoerspiel(title: "Der Riss im Raum-Zeit-Gefüge"),
        ScreenShotHoerspiel(title: "Chronojäger"),
        ScreenShotHoerspiel(title: "Der Tag, der nicht geschah"),
        ScreenShotHoerspiel(title: "Flucht aus dem Jahr 3021"),
        ScreenShotHoerspiel(title: "Die gestohlene Zukunft"),
        ScreenShotHoerspiel(title: "Paradoxon"),
        ScreenShotHoerspiel(title: "Der Mann, der sich selbst begegnete"),
        ScreenShotHoerspiel(title: "Schatten der Vergangenheit"),
        ScreenShotHoerspiel(title: "Mission: Zeitbruch"),
        ScreenShotHoerspiel(title: "Der letzte Sprung")
    ])
]

extension DataManager {
    /// Populates the database with entries for the screenshots
    func populateForScreenshots() {
        try? modelContext.transaction {
            for series in screenshotSeries {
                let modelSeries = Series(name: series.name, musicItemID: "DEBUG")
                modelContext.insert(modelSeries)
                for hoerspiel in series.hoerspiele {
                    let modelHoerspiel = Hoerspiel(
                        title: hoerspiel.title,
                        albumID: "DEBUG",
                        played: Bool.random(),
                        lastPlayed: hoerspiel.lastPlayed,
                        duration: hoerspiel.duration,
                        releaseDate: hoerspiel.releaseDate,
                        upc: "DEBUG",
                        series: modelSeries
                    )
                    modelContext.insert(modelHoerspiel)
                }
            }
            try modelContext.save()
        }
    }
}
#endif
