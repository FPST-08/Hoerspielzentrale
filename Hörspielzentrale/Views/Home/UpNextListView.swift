//
//  UpNextView.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 20.06.24.
//

import SwiftUI
/// `UpNextListView` is a view that displays the Hoerspiele from UpNext in a List
struct UpNextListView: View {
    
    // MARK: - Properties
    let hoerspiele: [SendableHoerspiel]
    
    @Environment(DataManagerClass.self) var dataManager
    
    // MARK: - View
    var body: some View {
        List {
            ForEach(hoerspiele, id: \.self) { hoerspiel in
                HoerspielListView(hoerspiel: hoerspiel)
                    .swipeActions(allowsFullSwipe: false) {
                        Button {
                            Task {
                                try? await dataManager.manager.update(
                                    hoerspiel.persistentModelID,
                                    keypath: \.showInUpNext,
                                    to: false)
                            }
                        } label: {
                            Label("Von als Nächstes entfernen", systemImage: "minus.circle")
                        }
                        
                        .tint(.red)
                        
                    }
            }
            
        }
        .navigationTitle("Als Nächstes")
        .listStyle(.plain)
        .safeAreaPadding(.bottom, 60)
    }
}
