//
//  OnboardingAMPermission.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 14.10.24.
//

import MusicKit
import SwiftUI
import TelemetryDeck

/// A view to prompt the user for permission to use Apple Music in the onboarding
struct MusicPermissionView: View {
    // MARK: - Properties
    @Binding var navpath: NavigationPath

    /// Indicates awaiting a result from the permission alert
    @State private var loading = false
    
    /// The gradient of the phone
    let gradient = LinearGradient(colors: [
        Color(UIColor(red: 41/256, green: 41/256, blue: 41/256, alpha: 1)),
        Color(UIColor(red: 55/256, green: 55/256, blue: 55/256, alpha: 1))],
                                  startPoint: .top,
                                  endPoint: .bottom)
    
    /// The background gradient from behind the phone
    let bgGradient = LinearGradient(colors: [
        Color.black,
        Color(UIColor(red: 21/256, green: 21/256, blue: 21/256, alpha: 1))],
                                    startPoint: .top,
                                    endPoint: .bottom)
    
    /// The current musicAuthorization status
    @State var musicAuthorizationStatus: MusicAuthorizationStatus = .notDetermined
    
    /// The appropriate title for the button
    var buttonTitle: String {
        if musicAuthorizationStatus == .denied || musicAuthorizationStatus == .restricted {
            return "Zu den Einstellungen"
        } else if musicAuthorizationStatus == .privacyAcknowRequired {
            return "Zu Apple Music"
        } else {
            return "Weiter"
        }
    }
    
    /// The appropriate title for the current musicAuthorization
    var title: String {
        if musicAuthorizationStatus == .restricted {
            return "Zugriff auf Apple Music eingeschränkt"
        } else if musicAuthorizationStatus == .denied {
            return "Kein Zugriff auf Apple Music möglich"
        } else if musicAuthorizationStatus == .privacyAcknowRequired {
            return "Datenschutzbestätigung erforderlich"
        } else {
            return "Zugriff auf Apple Music benötigt"
        }
    }
    
    @Environment(\.openURL) var openURL
    @Environment(\.colorScheme) var colorScheme
    
    /// The color used as placeholder in the notification
    let blankColor = Color(UIColor(red: 126/256, green: 126/256, blue: 131/256, alpha: 1))
    
    /// A view miming an app icon
    var dummyAppIcon: some View {
        RoundedRectangle(cornerRadius: 10)
            .foregroundStyle(blankColor)
            .frame(width: 55, height: 55)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        
    }
    
    var explanatoryText: String {
        if musicAuthorizationStatus == .privacyAcknowRequired {
            return """
Die Zustimmung der Datenschutzerklärung für Apple Music ist \ 
notwendig um die Hörspielzentrale nutzen zu können
"""
        } else {
            return """
Um die Hörspiele abspielen zu können und die Cover zu laden, \ 
ist Zugriff auf Apple Music. \ 
Dabei werden keine Daten aus deiner Mediathek verändert
"""
        }
    }
    
    /// The current device rotation
    @State private var rotation: UIDeviceOrientation = UIDevice.current.orientation
    
    /// Indicates if additional app icons should be presented
    var showAdditionalAppIcons: Bool {
        if !UIDevice.isIpad {
            return false
        } else if rotation == .landscapeLeft || rotation == .landscapeRight {
            return true
        } else {
            return false
        }
    }
    
    /// A grid row with dummy app icons
    var dummyGridRow: some View {
        GridRow {
            ForEach(showAdditionalAppIcons ? 0..<6 : 0..<4, id: \.self) { _ in
                dummyAppIcon
            }
        }
    }
    
    /// A boolean used to indicate if onboarding is completed
    @AppStorage("onboarding") var onboarding = true
    
    // MARK: - View
    public var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                bgGradient.ignoresSafeArea()
                
                ZStack {
                    UnevenRoundedRectangle(topLeadingRadius: 40, topTrailingRadius: 40)
                        .foregroundStyle(gradient)
                    
                    Grid(alignment: .center) {
                        dummyGridRow
                        GridRow {
                            if showAdditionalAppIcons {
                                dummyAppIcon
                            }
                            
                            Image(.appIconLogo)
                                .resizable()
                                .frame(width: 55, height: 55)
                                .cornerRadius(10)
                                .colorInvert(colorScheme == .light)
                            Image(systemName: "arrowshape.backward.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 55, height: 55)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .foregroundStyle(blankColor)
                            
                            Image(systemName: "arrowshape.forward.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 55, height: 55)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .foregroundStyle(blankColor)
                            
                            Image(.appleMusicIcon)
                                .resizable()
                                .frame(width: 55, height: 55)
                                .cornerRadius(10)
                                .colorInvert(colorScheme == .light)
                            if showAdditionalAppIcons {
                                dummyAppIcon
                            }
                        }
                        dummyGridRow
                        dummyGridRow
                            .padding(.bottom)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .padding(.horizontal, 20)
                }
                .padding(.top, 35)
                .padding(.horizontal, 45)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            ZStack {
                Color(UIColor(red: 28/256, green: 28/256, blue: 30/256, alpha: 1))
                    .ignoresSafeArea()
                VStack(spacing: 20) {
                    Text(title)
                        .font(.largeTitle.bold())
                        .padding(.top, 30)
                        .multilineTextAlignment(.center)
                    Text(explanatoryText)
                        .font(.body)
                        .foregroundStyle(Color.secondary)
                        .multilineTextAlignment(.center)
                    
                    Spacer()
                    
                    Button {
                        TelemetryDeck.signal("Onboarding.AuthorizationButtonPressed")
                        Task {
                            if musicAuthorizationStatus == .notDetermined {
                                loading = true
                                musicAuthorizationStatus = MusicAuthorizationStatus(await MusicAuthorization.request())
                                
                                TelemetryDeck.signal(
                                    "Onboarding.Authorization",
                                    parameters: ["Auth": musicAuthorizationStatus.description])
                                loading = false
                                if MusicAuthorization.currentStatus == .authorized {
                                    do {
                                        _ = try await MusicSubscription.current.canPlayCatalogContent
                                        onboarding = false
                                    } catch {
#if targetEnvironment(simulator)
                                        musicAuthorizationStatus = .authorized
                                        onboarding = false
#else
                                    musicAuthorizationStatus = .privacyAcknowRequired
#endif
                                    }
                                }
                            } else if musicAuthorizationStatus == .authorized {
                                do {
                                    _ = try await MusicSubscription.current.canPlayCatalogContent
                                    onboarding = false
                                } catch {
#if targetEnvironment(simulator)
                                    musicAuthorizationStatus = .authorized
                                    onboarding = false
#else
                                    musicAuthorizationStatus = .privacyAcknowRequired
#endif
                                }
                            } else if musicAuthorizationStatus == .privacyAcknowRequired {
                                if let musicURL = URL(string: "music://music.apple.com/library") {
                                    TelemetryDeck.signal("Onboarding.OpeningMusicForPrivacyAcknow")
                                    openURL(musicURL)
                                }
                            } else {
                                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                                    TelemetryDeck.signal("Onboarding.OpeningSettings")
                                    openURL(settingsURL)
                                }
                            }
                        }
                    } label: {
                        Text(buttonTitle)
                    }
                    .buttonStyle(PrimaryButtonStyle(loading: loading))
                    .padding(.bottom, 56)
                    .disabled(loading)
                }
                .padding(.horizontal, 30)
            }
            .frame(maxHeight: .infinity)
            .padding(.top, -14)
        }
        .navigationBarBackButtonHidden()
        .colorScheme(.dark)
        .colorInvert(colorScheme == .light)
        .onRotate { rotation in
            self.rotation = rotation
        }
    }
    // MARK: - Init
    init(
        loading: Bool = false,
        onboarding: Binding<Bool>,
        navpath: Binding<NavigationPath>
    ) {
        self.loading = loading
        self.musicAuthorizationStatus = MusicAuthorizationStatus(MusicAuthorization.currentStatus)
        _navpath = navpath
    }
}

/// An enum to represent the current Authorization Status
enum MusicAuthorizationStatus {
    case notDetermined, denied, restricted, authorized, privacyAcknowRequired
    
    /// Initialize from `MusicAuthorization.Status`
    /// - Parameter status: The authorization status
    init(_ status: MusicAuthorization.Status) {
        switch status {
        case .notDetermined: self = .notDetermined
        case .denied: self = .denied
        case .restricted: self = .restricted
        case .authorized: self = .authorized
        @unknown default: self = .notDetermined
        }
    }
    
    /// A textual representation of the authorization status
    var description: String {
        switch self {
        case .notDetermined: return "Not Determined"
        case .denied: return "Denied"
        case .restricted: return "Restricted"
        case .authorized: return "Authorized"
        case .privacyAcknowRequired: return "Privacy Acknow Required"
        }
    }
}
