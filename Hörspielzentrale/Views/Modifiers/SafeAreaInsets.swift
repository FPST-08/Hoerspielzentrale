//
//  SafeAreaInsets.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 16.11.24.
//

import SwiftUI

private struct SafeAreaInsetsKey: EnvironmentKey {
    /// The default safe area insets
    static var defaultValue: EdgeInsets {
        UIApplication.shared
                   .connectedScenes.lazy
                   .compactMap { $0.activationState == .foregroundActive ? ($0 as? UIWindowScene) : nil }
                   .first(where: { $0.keyWindow != nil })?
                   .keyWindow?
                   .safeAreaInsets.swiftUiInsets ?? EdgeInsets()
    }
}

extension EnvironmentValues {
    /// The safeAreaInsets
    var safeAreaInsets: EdgeInsets {
        self[SafeAreaInsetsKey.self]
    }
}

private extension UIEdgeInsets {
    /// The swiftUI safe area insets
    var swiftUiInsets: EdgeInsets {
        EdgeInsets(top: top, leading: left, bottom: bottom, trailing: right)
    }
}
