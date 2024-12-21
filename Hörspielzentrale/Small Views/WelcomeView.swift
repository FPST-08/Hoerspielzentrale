//
//  WelcomeView.swift
//  diedreifragezeichenplayer
//
//  Created by Philipp Steiner on 01.04.24.
//

import MusicKit
import SwiftData
import SwiftUI

// MARK: - Welcome view

/// `WelcomeView` is a view that introduces to users the purpose of the MusicAlbums app,
/// and demonstrates best practices for requesting user consent for an app to get access to
/// Apple Music data.
///
/// Present this view as a sheet using the convenience `.welcomeSheet()` modifier

@MainActor
struct WelcomeView: View {
    
    // MARK: - Properties
    
    /// The current authorization status of MusicKit.
    @Binding var musicAuthorizationStatus: MusicAuthorization.Status
    
    /// Opens a URL using the appropriate system service.
    @Environment(\.openURL) private var openURL
    
    // MARK: - View
    
    /// A declaration of the UI that this view presents.
    var body: some View {
        ZStack {
            gradient
            VStack {
                Image(.appIconLogo)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .shadow(radius: 10)
                
                Text("Hörspielzentrale")
                    .foregroundColor(.primary)
                    .font(.largeTitle.weight(.semibold))
                    .shadow(radius: 2)
                    .padding(.bottom, 1)
                Text("Stell den Verstärker an!")
                    .foregroundColor(.primary)
                    .font(.title2.weight(.medium))
                    .multilineTextAlignment(.center)
                    .shadow(radius: 1)
                    .padding(.bottom, 16)
                explanatoryText
                    .foregroundColor(.primary)
                    .font(.title3.weight(.medium))
                    .multilineTextAlignment(.center)
                    .shadow(radius: 1)
                    .padding([.leading, .trailing], 32)
                    .padding(.bottom, 16)
                if let secondaryExplanatoryText = self.secondaryExplanatoryText {
                    secondaryExplanatoryText
                        .foregroundColor(.primary)
                        .font(.title3.weight(.medium))
                        .multilineTextAlignment(.center)
                        .shadow(radius: 1)
                        .padding([.leading, .trailing], 32)
                        .padding(.bottom, 16)
                }
                if musicAuthorizationStatus == .notDetermined || musicAuthorizationStatus == .denied {
                    Button(action: handleButtonPressed) {
                        buttonText
                            .foregroundStyle(Color.accentColor)
                            .padding([.leading, .trailing], 10)
                    }
                    .buttonStyle(.prominent)
                    .colorScheme(.light)
                }
            }
            .colorScheme(.dark)
        }
    }
    
    /// Constructs a gradient to use as the view background.
    private var gradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 251/255, green: 90/255, blue: 114/255),
                Color(red: 250/255, green: 39/255, blue: 63/255)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .flipsForRightToLeftLayoutDirection(false)
        .ignoresSafeArea()
    }
    
    /// Provides text that explains how to use the app according to the authorization status.
    private var explanatoryText: Text {
        let explanatoryText: Text
        switch musicAuthorizationStatus {
        case .restricted:
            explanatoryText = Text("Die Hörspielzentrale kann nicht verwendet werden, da der Zugriff auf ")
            + Text(Image(systemName: "applelogo")) + Text(" Music gesperrt ist.")
        default:
            explanatoryText = Text("Die Hörspielzentrale benutzt ")
            + Text(Image(systemName: "applelogo")) + Text(" Music\num Hörspiele abspielen zu können.")
        }
        return explanatoryText
    }
    
    /// Provides additional text that explains how to get access to Apple Music
    /// after previously denying authorization.
    private var secondaryExplanatoryText: Text? {
        var secondaryExplanatoryText: Text?
        switch musicAuthorizationStatus {
        case .denied:
            secondaryExplanatoryText = Text("Bitte erlaube der Hörspielzentrale Zugriff auf ")
            + Text(Image(systemName: "applelogo")) + Text(" Music in den Einstellungen.")
        default:
            break
        }
        return secondaryExplanatoryText
    }
    
    /// A button that the user taps to continue using the app according to the current
    /// authorization status.
    private var buttonText: Text {
        let buttonText: Text
        switch musicAuthorizationStatus {
        case .notDetermined:
            buttonText = Text("Weiter")
        case .denied:
            buttonText = Text("Öffne Einstellungen")
        default:
            buttonText = Text("Es ist ein Fehler aufgetreten")
            
        }
        return buttonText
    }
    
    // MARK: - Methods
    
    /// Allows the user to authorize Apple Music usage when tapping the Continue/Open Setting button.
    private func handleButtonPressed() {
        switch musicAuthorizationStatus {
        case .notDetermined:
            Task {
                let musicAuthorizationStatus = await MusicAuthorization.request()
                
                //                    let musicAuthorizationStatus = MusicAuthorization.currentStatus
                withAnimation {
                    self.musicAuthorizationStatus = musicAuthorizationStatus
                }
                
            }
        case .denied:
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                openURL(settingsURL)
            }
        default:
            
            do { }
        }
    }
    
    // MARK: - Presentation coordinator
    
    /// A presentation coordinator to use in conjuction with `SheetPresentationModifier`.
    class PresentationCoordinator: ObservableObject {
        static let shared = PresentationCoordinator()
        
        private init() {
            let authorizationStatus = MusicAuthorization.currentStatus
            musicAuthorizationStatus = authorizationStatus
            isWelcomeViewPresented = (authorizationStatus != .authorized)
        }
        
        @Published var musicAuthorizationStatus: MusicAuthorization.Status {
            didSet {
                isWelcomeViewPresented = (musicAuthorizationStatus != .authorized)
                //                Task {
                //                    subscription = try? await MusicSubscription.current
                //                }
                
            }
        }
        
        @Published var subscription: MusicSubscription?
        
        @Published var isWelcomeViewPresented: Bool
    }
    
    // MARK: - Sheet presentation modifier
    
    /// A view modifier that changes the presentation and dismissal behavior of the welcome view.
    fileprivate struct SheetPresentationModifier: ViewModifier {
        @Environment(\.modelContext) var modelContext
        @StateObject private var presentationCoordinator = PresentationCoordinator.shared
        var onDismiss: (() -> Void)?
        func body(content: Content) -> some View {
            content
                .sheet(isPresented: $presentationCoordinator.isWelcomeViewPresented, onDismiss: onDismiss) {
                    WelcomeView(musicAuthorizationStatus: $presentationCoordinator.musicAuthorizationStatus)
                        .interactiveDismissDisabled()
                }
        }
    }
    
    fileprivate struct ScreenPresentationModifier: ViewModifier {
        @StateObject private var presentationCoordinator = PresentationCoordinator.shared
        func body(content: Content) -> some View {
            if presentationCoordinator.isWelcomeViewPresented {
                WelcomeView(musicAuthorizationStatus: $presentationCoordinator.musicAuthorizationStatus)
            } else if presentationCoordinator.subscription?.canPlayCatalogContent ?? false {
                content
            } else {
                content
                    .musicSubscriptionOffer(isPresented: .constant(true))
            }
        }
    }
}

// MARK: - View extension

/// Allows the addition of the`welcomeSheet` view modifier to the top-level view.
extension View {
    @MainActor func welcomeSheet() -> some View {
        modifier(WelcomeView.SheetPresentationModifier())
    }
}

// MARK: - Previews

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView(musicAuthorizationStatus: .constant(.notDetermined))
    }
}

/// A prominent button style suitable for primary buttons
struct ProminentButtonStyle: ButtonStyle {
    
    /// The color scheme of the environment.
    @Environment(\.colorScheme) private var colorScheme: ColorScheme
    
    /// Applies relevant modifiers for this button style.
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .font(.title3.bold())
            .foregroundColor(.accentColor)
            .padding()
            .background(backgroundColor.cornerRadius(8))
    }
    
    /// The background color appropriate for the current color scheme.
    private var backgroundColor: Color {
        return Color(uiColor: (colorScheme == .dark) ? .secondarySystemBackground : .secondarySystemBackground)
    }
}

// MARK: - Button style extension

/// An extension that offers more convenient and idiomatic syntax to apply
/// the prominent button style to a button.
extension ButtonStyle where Self == ProminentButtonStyle {
    
    /// A button style that encapsulates all the common modifiers
    /// for prominent buttons shown in the UI.
    static var prominent: ProminentButtonStyle {
        ProminentButtonStyle()
    }
}

extension View {
    func welcomeView() -> some View {
        modifier(WelcomeView.ScreenPresentationModifier())
    }
}
