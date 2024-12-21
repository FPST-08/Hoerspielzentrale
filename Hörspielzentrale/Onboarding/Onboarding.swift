//
//  NewOnboarding.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 04.10.24.
//

import SwiftUI

extension View {
    /// A modifier that attaches the onboarding
    /// - Returns: Returns a view with onboarding if needed
    func onboarding() -> some View {
        modifier(OnboardingModifier())
    }
}

/// An enum to indicate onboarding view states
enum OnboardingNavigation: Hashable {
    case musicPermission
    case features
    case seriesPicker
}
