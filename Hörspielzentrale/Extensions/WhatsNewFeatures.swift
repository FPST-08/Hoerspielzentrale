//
//  WhatsNewFeatures.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 01.06.24.
//

@preconcurrency import MusicKit
import OSLog
import SwiftData
import SwiftUI
import WhatsNewKit
// swiftlint:disable file_length
extension Hörspielzentrale {
    
    /// A WhatsNewCollection
    var whatsNewCollection: WhatsNewCollection {
        [
            WhatsNew(
                version: "0.1.0",
                title: .init(
                    text: .init(
                        "Was ist neu in der "
                        + AttributedString(
                            "Hörspielzentrale",
                            attributes: .foregroundColor(.accentColor)
                        )
                    )
                ),
                features: [
                    .init(
                        image: .init(
                            systemName: "star.fill",
                            foregroundColor: .orange
                        ),
                        title: "Erster Beta-Release",
                        subtitle: "Dies ist die erste Version der Hörspielzentrale."
                    ),
                    .init(
                        image: .init(
                            systemName: "square.and.arrow.down",
                            foregroundColor: .blue
                        ),
                        title: "Speicherung",
                        subtitle: """
Die Hörspielzentrale merkt sich bis wohin das Hörspiel schon gehört wurde, sodass du dort direkt weiterhören kannst
"""
                    ),
                    .init(
                        image: .init(
                            systemName: "play.square.stack",
                            foregroundColor: .red
                        ),
                        title: "Mediathek",
                        subtitle: "Behalte einen Überblick über deine aktuellen und bereits gehörten Hörspiele"
                    ),
                    .init(
                        image: .init(
                            systemName: "arrow.up.arrow.down",
                            foregroundColor: .mint
                        ),
                        title: "Ordnung",
                        subtitle: "Ordne alle Hörspiele nach Erscheinungsdauer, Titel und Dauer und suche nach Titeln"
                    )
                    
                ],
                primaryAction: .init(
                    hapticFeedback: {
#if os(iOS)
                        .notification(.success)
#else
                        nil
#endif
                    }()
                )
                //                ,
                //                secondaryAction: .init(
                //                    title: "Learn more",
                //                    action: .openURL(.init(string: "https://github.com/SvenTiigi/WhatsNewKit"))
                //                )
            ),
            WhatsNew(version: "0.1.1",
                     title: .init(
                        text: .init(
                            "Was ist neu in der "
                            + AttributedString(
                                "Hörspielzentrale",
                                attributes: .foregroundColor(.accentColor)
                            )
                        )
                     ), features: [
                        WhatsNew.Feature(image: .init(systemName: "moon.zzz",
                                                      foregroundColor: Color.cyan),
                                         title: "Einschlaftimer",
                                         subtitle: """
Pausiere dein Hörspiel automatisch nach einer bestimmten Zeit. Auch genannt Ruhezustandstimer
"""),
                        WhatsNew.Feature(image: .init(systemName: "play.fill",
                                                      foregroundColor: Color.red),
                                         title: "Neues Design",
                                         subtitle: """
Der Button zum Abspielen eines neuen Hörspiels wurde überarbeitet. Sowohl auf der Startseite als auch in der Suche
"""),
                        WhatsNew.Feature(image: .init(systemName: "dice",
                                                      foregroundColor: Color.green),
                                         title: "Zufälliges Hörspiel",
                                         subtitle: """
\"Ich glaube nicht an Zufälle\" Ein zufälliges Hörspiel kann für dich ausgesucht werden. 
""")
                     ],
                     primaryAction: .init(
                        title: .init("Weiter"),
                        hapticFeedback: .notification(.success)
                     )
                    ),
            WhatsNew(version: "0.1.2",
                     title: .init(
                        text: .init(
                            "Was ist neu in der "
                            + AttributedString(
                                "Hörspielzentrale",
                                attributes: .foregroundColor(.accentColor)
                            )
                        )
                     ), features: [
                        WhatsNew.Feature(image: .init(systemName: "arrowtriangle.up.fill",
                                                      foregroundColor: Color.green),
                                         title: "Voting-System",
                                         subtitle: """
Du kannst nun für neue Funktionen stimmen, die als nächstes implementiert werden sollen.
"""),
                        WhatsNew.Feature(image: .init(systemName: "play.fill",
                                                      foregroundColor: Color.red),
                                         title: "Neues Design",
                                         subtitle: "Der Button zum Abspielen eines neuen Hörspiels wurde überarbeitet.")
                     ],
                     primaryAction: .init(
                        title: .init("Weiter"),
                        hapticFeedback: .notification(.success)
                     )
                    ),
            WhatsNew(version: "0.1.3",
                     title: .init(
                        text: .init(
                            "Was ist neu in der "
                            + AttributedString(
                                "Hörspielzentrale",
                                attributes: .foregroundColor(.accentColor)
                            )
                        )
                     ), features: [
                        WhatsNew.Feature(image: .init(systemName: "cloud.fill",
                                                      foregroundColor: Color.cyan),
                                         title: "iCloud-Sync",
                                         subtitle: "Deine Hörspiele werden nun automatisch mit iCloud synchronisiert"),
                        WhatsNew.Feature(image: .init(systemName: "ladybug",
                                                      foregroundColor: Color.red),
                                         title: "Wichtige Verbesserungen",
                                         subtitle: """
Neu veröffentlichte Hörspiele werden nun auch angezeigt und weitere Verbesserungen.
""")
                        
                     ],
                     primaryAction: .init(
                        title: .init("Weiter"),
                        hapticFeedback: .notification(.success)
                     )
                    ),
            WhatsNew(version: "0.1.4",
                     title: .init(
                        text: .init(
                            "Was ist neu in der "
                            + AttributedString(
                                "Hörspielzentrale",
                                attributes: .foregroundColor(.accentColor)
                            )
                        )
                     ), features: [
                        WhatsNew.Feature(image: .init(systemName: "apps.iphone",
                                                      foregroundColor: Color.green),
                                         title: "Widgets",
                                         subtitle: """
Auf dem Home-Bildschirm können nun stündlich neue Hörspiele vorgeschlagen werden
"""),
                        WhatsNew.Feature(image: .init(systemName: "text.justify.leading",
                                                      foregroundColor: Color.red),
                                         title: "Beschreibungen",
                                         subtitle: """
Sehe die Beschreibungen von Hörspielen der drei ???. Weitere Beschreibungen werden folgen
"""),
                        WhatsNew.Feature(image: .init(systemName: "film.stack",
                                                      foregroundColor: Color.orange),
                                         title: "Kapitel",
                                         subtitle: """
Sehe nun die Kapitel von Hörspielen. Weitere Hörspiele werden folgen
"""),
                        WhatsNew.Feature(image: .init(systemName: "globe",
                                                      foregroundColor: Color.blue),
                                         title: "Links",
                                         subtitle: """
Teile ein Hörspiel mithilfe eines Links mit anderen Nutzern der Hörspielzentrale
""")
                     ],
                     primaryAction: .init(
                        title: .init("Weiter"),
                        hapticFeedback: .notification(.success)
                     )
                    ),
            WhatsNew(version: "1.0.0",
                     title: .init(
                        text: .init(
                            "Was ist neu in der "
                            + AttributedString(
                                "Hörspielzentrale",
                                attributes: .foregroundColor(.accentColor)
                            )
                        )
                     ), features: [
                        WhatsNew.Feature(image: .init(systemName: "gauge.with.dots.needle.100percent",
                                                      foregroundColor: Color.green),
                                         title: "Verbesserte Performance",
                                         subtitle: """
Die Hörspielzentrale läuft nun viel stabiler und schneller als zuvor
"""),
                        WhatsNew.Feature(image: .init(systemName: "rectangle.portrait.on.rectangle.portrait.slash"),
                                         title: "Metadaten für weitere Hörspiele",
                                         subtitle: "Fast alle Hörspiele der drei ??? zeigen nun Metadaten an"),
                        WhatsNew.Feature(image: .init(systemName: "ladybug",
                                                      foregroundColor: Color.blue),
                                         title: "Kleine Fehlerbehebungen",
                                         subtitle: "Hier und da ein kleiner Fehler, der nun nicht mehr auftritt")
                     ],
                     primaryAction: .init(
                        title: .init("Weiter"),
                        hapticFeedback: .notification(.success)
                     )
                    ),
            WhatsNew(
                version: "1.1.0",
                title: .init(
                    text: .init(
                        "Was ist neu in der "
                        + AttributedString(
                            "Hörspielzentrale",
                            attributes: .foregroundColor(.accentColor)
                        )
                    )
                ),
                features: [
                    WhatsNew.Feature(image: .init(systemName: "forward.frame.fill",
                                                  foregroundColor: Color.purple),
                                     title: "Smart-Skip",
                                     subtitle: """
Disclaimer und Inhaltsangabe können automatisch übersprungen werden. Dies kann in den Einstellungen eingestellt werden
"""),
                    WhatsNew.Feature(image: .init(systemName: "arrowtriangle.up.fill",
                                                  foregroundColor: Color.green),
                                     title: "Voting System",
                                     subtitle: """
Das System funktioniert wieder. Der bisherige Anbieter hat überraschenderweise den Dienst eingestellt.
"""),
                    WhatsNew.Feature(image: .init(systemName: "square.2.layers.3d",
                                                  foregroundColor: Color.blue),
                                     title: "ShortCuts",
                                     subtitle: """
Hörspiele können nun über Kurzbefehle abgespielt und Informationen abgefragt werden. Weitere Kurzbefehle werden folgen
"""),
                    WhatsNew.Feature(image: .init(systemName: "externaldrive",
                                                  foregroundColor: Color.yellow),
                                     title: "Lokale Cover",
                                     subtitle: """
Die Album-Cover werden nun lokal gespeichert. Dadurch läuft die App flüssiger \
und die Cover sind beim Scrollen sofort sichtbar
""")
                ], primaryAction: .init(
                    title: .init("Weiter"),
                    hapticFeedback: .notification(.success)
                ), migration: {
                    do {
                        guard let url = URL(string: "https://api.npoint.io/3df42554b18fe664663c") else {
                            assertionFailure("Invalid URL")
                            return
                        }
                        let (data, _) = try await URLSession.shared.data(from: url)
                        
                        let decoded = try JSONDecoder().decode([UPCJSON].self, from: data)
                        let hoerspiele = try await dataManagerClass.manager.fetchIdentifiers( {
                            FetchDescriptor<Hoerspiel>()
                        })
                        for hoerspiel in hoerspiele {
                            let title = try await dataManagerClass.manager.read(hoerspiel, keypath: \.title)
                            Logger.data.info("Add upc for \(title)")
                            var upc = String()
                            
                            if let fetchedUPC = decoded.first(where: { $0.title == title })?.upc {
                                upc = fetchedUPC
                            } else {
                                let title = try await dataManagerClass.manager.read(hoerspiel, keypath: \.title)
                                let request = MusicCatalogSearchRequest(term: title, types: [Album.self])
                                guard let fetchedUPC = try await request.response().albums.first?.upc else {
                                    Logger.data.error("No UPC from SearchRequest")
                                    return
                                }
                                upc = fetchedUPC
                            }
                            
                            guard !upc.isEmpty else {
                                Logger.data.error("UPC still nil")
                                return
                            }
                            try await dataManagerClass.manager.update(hoerspiel, keypath: \.upc, to: upc)
                            
                            let dhupc = try await dataManagerClass.manager.read(hoerspiel, keypath: \.upc)
                            Logger.data.info("Added \(dhupc) to \(title)")
                        }
                        
                        try await dataManagerClass.manager.save()
                        Logger.data.info("Finished adding UPCs")
                        
                    } catch {
                        Logger.data.fullError(error, sendToTelemetryDeck: false)
                    }
                    Logger.data.info("Migration seemingly finished")
                }
            ),
            WhatsNew(
                version: "1.1.1",
                title: .init(
                    text: .init(
                        "Was ist neu in der "
                        + AttributedString(
                            "Hörspielzentrale",
                            attributes: .foregroundColor(.accentColor)
                        )
                    )
                ),
                features: [
                    WhatsNew.Feature(image: .init(systemName: "plus.square.fill.on.square.fill",
                                                  foregroundColor: Color.indigo),
                                     title: "Alle Serien",
                                     subtitle: """
            Du kannst nun direkt den Apple Music Katalog durchsuchen und jede Serie anhören
            """),
                    WhatsNew.Feature(image: .init(systemName: "externaldrive.badge.plus",
                                                  foregroundColor: Color.green),
                                     title: "Verbesserung der Datenstruktur",
                                     subtitle: """
                                Dadurch können neue Funktionen einfacher entwickelt werden
                                """),
                    WhatsNew.Feature(image: .init(systemName: "ladybug",
                                                  foregroundColor: Color.blue),
                                     title: "Kleine Fehlerbehebungen",
                                     subtitle: "Hier und da ein kleiner Fehler, der nun nicht mehr auftritt")
                ], primaryAction: .init(
                    title: .init("Weiter"),
                    hapticFeedback: .notification(.success)
                )
            )
            
        ]
    }
}

extension AttributeContainer {
    
    /// A AttributeContainer with a given foreground color
    /// - Parameter color: The foreground color
    static func foregroundColor(
        _ color: Color
    ) -> Self {
        var container = Self()
        container.foregroundColor = color
        return container
    }
    
}
