//
//  SettingsView.swift
//  diedreifragezeichenplayer
//
//  Created by Philipp Steiner on 18.04.24.
//

import AcknowList
import MediaPlayer
import MusicKit
import OSLog
import Roadmap
import SwiftUI
import TelemetryDeck

/// A view providing Settings
struct SettingsView: View {
    // MARK: - Properties
    /// The config required for a `RoadMapView`
    let configuration = RoadmapConfiguration(
        roadmapJSONURL: URL(string: "https://raw.githubusercontent.com/FPST-08/H-rspielzentraleJSON/refs/heads/main/SmallUtilities/FeatureVoter")!, // swiftlint:disable:this line_length
        voter: CustomFeatureVoter(),
        style: RoadmapTemplate.standard.style,
        shuffledOrder: true,
        allowVotes: true, // Present the roadmap in read-only mode by setting this to false
        allowSearching: false
    )
    
    @Environment(\.dismiss) var dismiss
    
    // MARK: - View
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .center) {
                        Image(.appIconLogo)
                            .resizable()
                            .frame(width: 60, height: 60)
                            .cornerRadius(10)
                        Text("Einstellungen")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text("Das ist wirklich eine spezialgelagerte Sondereinstellung.")
                            .multilineTextAlignment(.center)
                            .font(.body)
                        
                    }
                    .frame(maxWidth: .infinity)
                }
                
                Section {
                    NavigationLink {
                        NotificationView()
                    } label: {
                        CuteLabel(title: "Benachrichtigungen", systemName: "bell.badge", backgroundColor: .red)
                    }
                }
                
                Section {
                    NavigationLink {
                        SmartskipSettingsView()
                    } label: {
                        CuteLabel(
                            title: "Smart-Skip",
                            systemName: "forward.frame.fill",
                            backgroundColor: .purple)
                    }

                }
                
                Section {
                    NavigationLink {
                        RoadmapView(configuration: configuration)
                            .trackNavigation(path: "Roadmap")
                    } label: {
                        CuteLabel(
                            title: "Wähle für neue Funktionen",
                            systemName: "arrowtriangle.up",
                            backgroundColor: Color.red)
                    }
                    
                    Button {
                        let mailtoString = """
mailto:hoerspielzentrale@icloud.com?subject=Idee für eine neue Funktion in der Hörspielzentrale
""".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
                        let mailtoUrl = URL(string: mailtoString!)!
                        if UIApplication.shared.canOpenURL(mailtoUrl) {
                                UIApplication.shared.open(mailtoUrl, options: [:])
                        }

                    } label: {
                        CuteLabel(
                            title: "Vorschlag für Funktion senden",
                            systemName: "envelope",
                            backgroundColor: .blue)
                            .foregroundStyle(Color.blue)
                    }
                    
                }
                Section {
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        CuteLabel(
                            title: "Systemberechtigungen öffnen",
                            systemName: "gear",
                            backgroundColor: Color.gray)
                    }
                    if Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt" {
                        Button {
                            // Special scheme specific to TestFlight
                            let presenceCheck = URL(string: "itms-beta://")!
                            // Special link that includes the app's ID
                            let deepLink = URL(string: "https://beta.itunes.apple.com/v1/app/6503214441")!
                            let app = UIApplication.shared
                            if app.canOpenURL(presenceCheck) {
                                app.open(deepLink)
                            }
                        } label: {
                            CuteLabel(
                                title: "In TestFlight öffnen",
                                systemName: "airplane",
                                backgroundColor: Color.blue)
                        }
                    }
                }
                .foregroundStyle(Color.blue)
                Section {
                    NavigationLink {
                        SpeicherView()
                    } label: {
                        CuteLabel(title: "Speicher", systemName: "internaldrive", backgroundColor: .gray)
                    }
                }
#if DEBUG
                Section {
                    NavigationLink {
                        DebugView()
                    } label: {
                        CuteLabel(
                            title: "Dangerous Debug",
                            systemName: "exclamationmark.triangle",
                            backgroundColor: Color.orange)
                    }
                }
#endif
                NavigationLink {
                    AcknowListSwiftUIView(acknowledgements: acknowledgements)
                        .trackNavigation(path: "AcknowList")
                } label: {
                    CuteLabel(
                        title: "Acknowledgements",
                        systemName: "heart")
                    
                }
                
                Section {
                    VStack {
                        Image(.profilbild)
                            .resizable()
                            .frame(width: 50, height: 50)
                            .padding(.bottom)
                        Text("Made with ❤️ by Philipp")
                            .font(.body)
                            .foregroundStyle(Color.secondary)
                        
                        Text("Version \(Bundle.main.releaseVersionNumber!) (\(Bundle.main.buildVersionNumber!))")
                            .font(.caption)
                            .foregroundStyle(Color.tertiaryLabel)
                        Button("Kontakt") {
                            let mailtoString = """
                            mailto:hoerspielzentrale@icloud.com?subject=Kontakt zur Hörspielzentrale
                            """.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
                            let mailtoUrl = URL(string: mailtoString!)!
                            if UIApplication.shared.canOpenURL(mailtoUrl) {
                                UIApplication.shared.open(mailtoUrl, options: [:])
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets())
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .background(Color(UIColor.systemGroupedBackground))
                }
            }
            .navigationTitle("Einstellungen")
        }
        .trackNavigation(path: "Settings")
    }
}
