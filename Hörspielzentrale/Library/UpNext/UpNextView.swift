//
//  UpNextView.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 19.08.24.
//

import MusicKit
import OSLog
import SwiftData
import SwiftUI

/// Presents all Hoerspiele marked with `showInUpNext` in a row of ``HoerspielSquareView`` and
/// with a header that naviagtes to ``UpNextListView``
struct UpNextView: View {
    // MARK: - Properties
    
    /// An Observable Class responsible for navigation
    @Environment(NavigationManager.self) var navigation
    
    /// An Observable Class responsible for data
    @Environment(DataManagerClass.self) var dataManager
    
    /// A Query used  to fetch all Hoerspiele
    ///
    /// The hoerspiele will be sorted using their last played date in reverse order
    @Query(filter: #Predicate<Hoerspiel> { hoerspiel in
        hoerspiel.showInUpNext
    }, sort: [SortDescriptor(\Hoerspiel.lastPlayed, order: .reverse)]) var hoerspiele: [Hoerspiel]
    
    // MARK: - View
    var body: some View {
        Group {
            if hoerspiele.isEmpty {
                ContentUnavailableView {
                    Label("Keine Hörspiele", systemImage: "play.square.stack")
                } description: {
                    Text("Hörspiele, die du angefangen hast, erscheinen hier")
                } actions: {
                    Button {
                        navigation.selection = .search
                    } label: {
                        Label("Gehe zur Suche", systemImage: "arrow.right")
                    }
                    .buttonStyle(BorderedProminentButtonStyle())
                }
            } else {
                NavigationLink {
                    UpNextListView(hoerspiele: hoerspiele.map( { SendableHoerspiel(hoerspiel: $0)}))
                } label: {
                    HStack(spacing: 5) {
                        Text("Als Nächstes")
                            .foregroundStyle(Color.primary)
                        Image(systemName: "chevron.right")
                            .font(.title3)
                            .foregroundStyle(Color.primary.opacity(0.5))
                        Spacer()
                    }
                    .padding(.leading, 15)
                    .fontWeight(.bold)
                    .font(.title2)
                    .padding(.top, 5)
                }
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 10) {
                        ForEach(hoerspiele, id: \.self) { hoerspiel in
                            HoerspielSquareView(hoerspiel: SendableHoerspiel(hoerspiel: hoerspiel))
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollIndicators(.never)
                .contentMargins(.leading, 20, for: .scrollContent)
            }
        }
    }
}

#Preview {
    UpNextView()
}
