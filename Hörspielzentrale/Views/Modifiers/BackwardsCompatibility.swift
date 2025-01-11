//
//  BackwardsCompatibility.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 02.11.24.
//

import SwiftUI

extension View {
    /// Sets the navigation transition style for this view if available.
    ///
    /// Add this modifier to a view that appears within a
    /// `NavigationStack` or a sheet, outside of any containers such as
    /// `VStack`.
    ///
    ///     struct ContentView: View {
    ///         @Namespace private var namespace
    ///         var body: some View {
    ///             NavigationStack {
    ///                 NavigationLink {
    ///                     DetailView()
    ///                         .navigationTransition(.zoom(sourceID: "world", in: namespace))
    ///                 } label: {
    ///                     Image(systemName: "globe")
    ///                         .matchedTransitionSource(id: "world", in: namespace)
    ///                 }
    ///             }
    ///         }
    ///     }
    ///
    func backwardsNavigationTransition(_ sourceID: String, in namespace: Namespace.ID) -> some View {
        if #available(iOS 18, *) {
            return self
                .navigationTransition(.zoom(sourceID: sourceID, in: namespace))
        } else {
            return self
        }
    }
    /// Identifies this view as the source of a navigation transition, such
    /// as a zoom transition if available.
    ///
    /// - Parameters:
    ///   - id: The identifier, often derived from the identifier of
    ///     the data being displayed by the view.
    ///   - namespace: The namespace in which defines the `id`. New
    ///     namespaces are created by adding an `Namespace` variable
    ///     to a ``View`` type and reading its value in the view's body
    ///     method.
    func backwardsMatchedTransitionSource(id: String, in namespace: Namespace.ID) -> some View {
        if #available(iOS 18, *) {
            return self
                .matchedTransitionSource(id: id, in: namespace)
        } else {
            return self
        }
    }
}
