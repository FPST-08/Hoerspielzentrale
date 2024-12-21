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
    @State var musicAuthorizationStatus: MusicAuthorization.Status = .notDetermined
    
    /// The appropriate title for the button
    var buttonTitle: String {
        if musicAuthorizationStatus == .denied || musicAuthorizationStatus == .restricted {
            return "Zu den Einstellungen"
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
        
    }
    
    // MARK: - View
    public var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                bgGradient.ignoresSafeArea()
                
                ZStack {
                    UnevenRoundedRectangle(topLeadingRadius: 40, topTrailingRadius: 40)
                        .foregroundStyle(gradient)
                    
                    VStack {
                        Grid(alignment: .center, horizontalSpacing: 20, verticalSpacing: 30) {
                            GridRow {
                                dummyAppIcon
                                dummyAppIcon
                                dummyAppIcon
                                dummyAppIcon
                            }
                            GridRow {
                                Image(.appIconLogo)
                                    .resizable()
                                    .frame(width: 55, height: 55)
                                    .cornerRadius(10)
                                    .colorInvert(colorScheme == .light)
                                Image(systemName: "arrowshape.backward.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundStyle(blankColor)
                                
                                Image(systemName: "arrowshape.forward.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundStyle(blankColor)
                                
                                Image(.appleMusicIcon)
                                    .resizable()
                                    .frame(width: 55, height: 55)
                                    .cornerRadius(10)
                                    .colorInvert(colorScheme == .light)
                            }
                            GridRow {
                                dummyAppIcon
                                dummyAppIcon
                                dummyAppIcon
                                dummyAppIcon
                            }
                            GridRow {
                                dummyAppIcon
                                dummyAppIcon
                                dummyAppIcon
                                dummyAppIcon
                            }
                        }
                        .frame(maxHeight: .infinity)
                        .clipped()
                        .padding(.horizontal, 20)
                        
                    }
                    .padding(.top, 40)
                }
                .padding(.top, 35)
                .padding(.horizontal, 45)
            }
            .frame(maxHeight: .infinity)
            ZStack {
                Color(UIColor(red: 28/256, green: 28/256, blue: 30/256, alpha: 1))
                    .ignoresSafeArea()
                VStack(spacing: 20) {
                    Text(title)
                        .font(.largeTitle.bold())
                        .padding(.top, 30)
                        .multilineTextAlignment(.center)
                    Text("""
                         Um die Hörspiele abspielen zu können und die Cover zu laden, \ 
                         ist Zugriff auf Apple Music erforderlich. \ 
                         Dabei werden keine Daten aus deiner Mediathek abgerufen oder verändert
                         """)
                        .font(.body)
                        .foregroundStyle(Color.secondary)
                        .multilineTextAlignment(.center)
                    
                    Spacer()
                    
                    Button {
                        TelemetryDeck.signal("Onboarding.AuthorizationButtonPressed")
                        Task {
                            if musicAuthorizationStatus == .notDetermined {
                                loading = true
                                musicAuthorizationStatus = await MusicAuthorization.request()
                                TelemetryDeck.signal(
                                    "Onboarding.Authorization",
                                    parameters: ["Auth": musicAuthorizationStatus.description])
                                loading = false
                                if MusicAuthorization.currentStatus == .authorized {
                                    navpath.append(OnboardingNavigation.seriesPicker)
                                }
                            } else if musicAuthorizationStatus == .authorized {
                                navpath.append(OnboardingNavigation.seriesPicker)
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
    }
    // MARK: - Init
    init(
        loading: Bool = false,
        onboarding: Binding<Bool>,
        navpath: Binding<NavigationPath>
    ) {
        self.loading = loading
        self.musicAuthorizationStatus = MusicAuthorization.currentStatus
        _navpath = navpath
    }
}
