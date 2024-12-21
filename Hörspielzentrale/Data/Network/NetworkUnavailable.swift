//
//  NetworkUnavailable.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 22.10.24.
//

import SwiftUI

struct NetworkUnavailableViewModifier: ViewModifier {
    @State private var networkhelper = NetworkHelper()
    
    @Environment(MusicManager.self) var musicmanager
    
    func body(content: Content) -> some View {
        switch networkhelper.connectionStatus {
        case .working:
            content
        case .notWorking(let description, let systemName):
            ContentUnavailableView {
                Label("Keine Verbindung", systemImage: systemName)
            } description: {
                Text(description)
            } actions: {
                Button("Erneut versuchen") {
                    networkhelper.check()
                }
                .buttonStyle(BorderedProminentButtonStyle())
            }
            .onAppear {
                musicmanager.musicplayer.stop()
            }
            .task {
                await musicmanager.saveListeningProgressAsync()
            }
            .tint(.accent)
        }
    }
}
extension View {
    func networkUnavailable() -> some View {
        modifier(NetworkUnavailableViewModifier())
    }
}
