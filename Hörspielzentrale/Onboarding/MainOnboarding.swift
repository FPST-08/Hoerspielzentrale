//
//  MainOnboarding.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 14.10.24.
//

import SwiftUI
import TelemetryDeck
import WhatsNewKit

/// A view modifier used to present the onboarding
struct OnboardingModifier: ViewModifier {
    // MARK: - Properties
    
    /// A boolean used to indicate if onboarding is completed
    @AppStorage("onboarding") var onboarding = true
    
    /// The navpath to append further views to
    @State private var navPath = NavigationPath()
    
    /// An Observable Class responsible for data
    @Environment(DataManagerClass.self) var dataManager
    
    // MARK: - View
    func body(content: Content) -> some View {
        ZStack {
            
            if !onboarding {
                content
                    .transition(.scale)
            }
            
            if onboarding {
                NavigationStack(path: $navPath) {
                    OnboardingFeature(navPath: $navPath)
                    .navigationDestination(for: OnboardingNavigation.self) { value in
                        switch value {
                        case .musicPermission:
                            MusicPermissionView(onboarding: $onboarding, navpath: $navPath)
                        case .seriesPicker:
                            SeriesSelectionView {
                                onboarding = false
                            }
                        default: ContentUnavailableView(
                            "Ein Fehler ist aufgetreten",
                            systemImage: "exclamationmark.triangle",
                            description: Text("""
                                            Hier hättest du nie hinkommen sollen. \ 
                                            Starte die App neu und versuche es erneut
                                            """))
                        }
                    }
                }
                .transition(.move(edge: .bottom))
                .zIndex(1)
                .tint(.accent)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: onboarding)
    }
}
