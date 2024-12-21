//
//  OnboardingFeature.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 14.10.24.
//

import SwiftUI
import TelemetryDeck
import WhatsNewKit

/// A view used to present the most important features in the onboarding
struct OnboardingFeature: View {
    // MARK: - Properties
    
    /// The features that will be presented in the onboarding
    let features = [
        WhatsNew.Feature(
            image: .init(systemName: "bookmark",
                         foregroundColor: Color.green),
            title: "Bookmark-Funktion",
            subtitle: "Einfach da weiterhören, wo du aufgehört hast. Die Hörspielzentrale merkt sich, wo du warst"),
        WhatsNew.Feature(image: .init(systemName: "play.square.stack",
                                      foregroundColor: Color.red),
                         title: "Mediathek",
                         subtitle: """
Behalte einen Überblick über Hörspiele, die du schon gehört hast oder bald hören möchtest
"""),
        WhatsNew.Feature(image: .init(systemName: "magnifyingglass",
                                      foregroundColor: Color.blue),
                         title: "Stöbern",
                         subtitle: """
Stöbere und durchsuche ganz einfach alle Hörspiele um genau das Richtige zu finden
"""),
        WhatsNew.Feature(image: .init(systemName: "sparkles",
                                      foregroundColor: Color.yellow),
                         title: "Zusatzinformationen",
                         subtitle: """
                         Welche Beschreibung hat das Hörspiel? Wer waren die Sprecher? \ 
                         Wie heißt das aktuelle Kapitel? \ 
                         All das erfärhst du ganz einfach in der Hörspielzentrale
                         """)
    ]
    
    /// The navpath to push the next view to
    @Binding var navPath: NavigationPath
    
    // MARK: - View
    var body: some View {
        WhatsNewView(whatsNew: WhatsNew(
            title: .init(
                text: .init(
                    "Willkommen zur "
                    + AttributedString(
                        "Hörspielzentrale",
                        attributes: .foregroundColor(.accentColor)
                    )
                )
            ),
            features: features,
            primaryAction: WhatsNew.PrimaryAction(title: "Weiter")
        ), action: {
            TelemetryDeck.signal("Onboarding.finishedFeatures")
            navPath.append(OnboardingNavigation.musicPermission)
        })
    }
}
