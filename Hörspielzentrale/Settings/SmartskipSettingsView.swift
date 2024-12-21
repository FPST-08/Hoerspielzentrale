//
//  SmartskipSettingsView.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 21.08.24.
//

import SwiftUI
import TelemetryDeck

/// A view that represents the Settings for SmartSkip
struct SmartskipSettingsView: View {
    // MARK: - Properties
    /// A booleanthat enables or disables smart skip entirely
    @State private var smartskipenabled = false
    /// A boolean that enables or disables skipping the disclaimer
    @State private var disclaimerSkip = true
    /// A boolean that enables or disables skipping the intro
    @State private var introSkip = true

    /// A boolean that enables or disables skipping the music
    @State private var musicSkip = false
    
    // MARK: - View
    var body: some View {
        List {
            Section {
                VStack(alignment: .center) {
                    ZStack {
                        ContainerRelativeShape()
                            .foregroundStyle(.purple)
                        Image(systemName: "forward.frame.fill")
                            .padding(10)
                            .font(.title.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                        .frame(width: 60, height: 60)
                        .cornerRadius(10)
                    Text("Smart Skip")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("Überspringe automatisch ungewünschte Teile des Hörspiels")
                        .multilineTextAlignment(.center)
                    Divider()
                    Toggle("Smart Skip aktivieren", isOn: $smartskipenabled)
                        .onChange(of: smartskipenabled) { _, newValue in
                            UserDefaults.standard.setValue(newValue, forKey: "smartskipenabled")
                            if newValue == true {
                                disclaimerSkip = true
                                introSkip = true
                            }
                        }
                }
                .frame(maxWidth: .infinity)
            }
            
            if smartskipenabled {
                Section {
                    Toggle("Disclaimer überspringen", isOn: $disclaimerSkip)
                        .onChange(of: disclaimerSkip) { _, newValue in
                            UserDefaults.standard.setValue(newValue, forKey: "smartskipdisclaimer")
                        }
                    Toggle("Inhaltsangabe überspringen", isOn: $introSkip)
                        .onChange(of: introSkip) { _, newValue in
                            UserDefaults.standard.setValue(newValue, forKey: "smartskipintro")
                        }
                    Toggle("Titelmusik überspringen", isOn: $musicSkip)
                        .onChange(of: musicSkip) { _, newValue in
                            UserDefaults.standard.setValue(newValue, forKey: "smartskipmusic")
                        }
                        .disabled(true)
                } footer: {
                    Text("Titelmusik überspringen wird aktuell noch nicht unterstützt.")
                }
            }
            
        }
        .onAppear {
            smartskipenabled = UserDefaults.standard.bool(forKey: "smartskipenabled")
            disclaimerSkip = UserDefaults.standard.bool(forKey: "smartskipdisclaimer")
            introSkip = UserDefaults.standard.bool(forKey: "smartskipintro")
            musicSkip = UserDefaults.standard.bool(forKey: "smartskipmusic")
        }
        .onDisappear {
            TelemetryDeck.signal(
                "Smartskip.Changed",
                parameters: [
                    "disclaimer": disclaimerSkip.description,
                    "intro": introSkip.description])
        }
        .trackNavigation(path: "Smartskip")
    }
}
