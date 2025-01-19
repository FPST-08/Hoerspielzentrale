//
//  ExpandBottomSheet.swift
//  diedreifragezeichenplayer
//
//  Created by Philipp Steiner on 18.04.24.
//

import MediaPlayer
import MusicKit
import OSLog
import SwiftData
import SwiftUI
import TelemetryDeck

// swiftlint:disable type_body_length
// swiftlint:disable file_length
/// A full screen sheet used to control a running playback
struct PlaybackSheet: View {
    // MARK: - Properties
    /// The animation namespace of the animation
    var animation: Namespace.ID
    /// A bool indicating a running animation
    @Binding var animateContent: Bool
    /// The current offset of the entire sheet caused by pulling
    @State private var offsetY: CGFloat = 0
    /// An Observable Class responsible for data
    @Environment(DataManagerClass.self) var dataManager
    /// Referencing an `Observable` class responsible for playback
    @Environment(MusicManager.self) var musicManager
    /// An Observable Class responsible for navigation
    @Environment(NavigationManager.self) var navigation
    /// Referencing an `@Observable` class responsible for loading and caching covers
    @Environment(ImageCache.self) var imageCache
    /// The current playback state
    @ObservedObject var state = ApplicationMusicPlayer.shared.state
    /// The backgroundColor of the ``Hoerspiel`` Cover used as the overall background
    var backgroundColor: Color {
        if let bgColor = musicManager.currentlyPlayingHoerspielCover?.averageColor {
            return Color(bgColor)
        } else {
            return Color.systemGray4
        }
    }
    /// The `persistentIdentifier` of the currently playing ``Hoerspiel``
    let persistentIdentifier: PersistentIdentifier?
    /// Current playback progress in seconds
    @State private var progressValue = 0.0
    /// The duration of the ``Hoerspiel``
    @State private var durationOfHoerspiel: Double?
    /// Options in minutes to set the sleep timer to
    let sleeptimerDurations = [0, 5, 10, 15, 30, 45, 60]
    
    /// A computet property simplifying an indication to disable the control buttons
    var disableButtons: Bool {
        if musicManager.currentlyPlayingHoerspiel == nil {
            return true
        } else {
            return false
        }
    }
    
    /// A boolean that indicates a currently running playback
    var isPlaying: Bool {
        #if DEBUG
        if musicManager.currentlyPlayingHoerspiel?.upc == "DEBUG" {
            return true
        }
        #endif
        return state.playbackStatus == .playing
    }
    
    @Environment(\.safeAreaInsets) var safeAreaInsets
    
    var cover: Image? {
        Image(musicManager.currentlyPlayingHoerspielCover)
    }
    
    @Environment(\.colorScheme) var colorScheme
    
    // MARK: - View
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: animateContent ? deviceCornerRadius : 0, style: .continuous)
                .foregroundStyle(Color.clear)
            
            Rectangle()
            
                .fill(.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: animateContent ? deviceCornerRadius : 0, style: .continuous)
                        .fill(Color.systemBackground)
                )
                .overlay(
                    ZStack {
                        RoundedRectangle(cornerRadius: animateContent ? deviceCornerRadius : 0, style: .continuous)
                            .fill(backgroundColor)
                            .opacity(animateContent ? 1 : 0)
                        
                        RoundedRectangle(cornerRadius: animateContent ? deviceCornerRadius : 0, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .opacity(animateContent ? 1 : 0)
                    }
                )
                .overlay(alignment: .top) {
                    ZStack {
                        RoundedRectangle(cornerRadius: animateContent ? deviceCornerRadius : 15)
                            .fill(.ultraThickMaterial)
                            .shadow(radius: 3)
                            .padding(.horizontal, 10)
                        //                                .overlay {
                        MusicInfo(
                            animateContent: $animateContent,
                            artwork: cover,
                            animation: animation)
                        //                                }
                    }
                    .frame(height: 60)
                    .allowsTightening(false)
                    .opacity(animateContent ? 0 : 1)
                }
                .matchedGeometryEffect(id: "BGVIEW", in: animation)
            VStack(spacing: 15) {
                Capsule()
                    .fill(.gray)
                    .frame(width: 40, height: 5)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : UIScreen.main.bounds.height)
                
                Group {
                    
                    if let cover {
                        cover
                            .resizable()
                            .cornerRadius(15)
                            .shadow(radius: 10)
                            .scaleEffect(isPlaying ? 1 : 0.7)
                            .animation(.spring(duration: 0.5, bounce: 0.3), value: state.playbackStatus)
                        
                    } else {
                        RoundedRectangle(cornerRadius: animateContent ? 15 : 5, style: .continuous)
                            .foregroundStyle(Color.gray)
                            .cornerRadius(15)
                            .shadow(radius: 10)
                    }
                    
                }
                .matchedGeometryEffect(id: "ARTWORK", in: animation)
                .coverFrame()
                .padding(.vertical, UIScreen.main.bounds.height < 700 ? 10 : 30)
                playerView()
                    .playerViewSize()
                
                    .offset(y: animateContent ? 0 : UIScreen.main.bounds.height)
            }
            
            .padding(.top, safeAreaInsets.top + (safeAreaInsets.bottom == 0 ? 10 : 0))
            .padding(.bottom, safeAreaInsets.bottom == 0 ? 10 : safeAreaInsets.bottom)
            .padding(.horizontal, 25)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .clipped()
            
        }
        .contentShape(Rectangle())
        .offset(y: offsetY)
        .gesture(
            DragGesture(minimumDistance: 20)
                .onChanged( { value in
                    
                    let translationY = value.translation.height
                    offsetY = (translationY > 0 ? translationY : 0)
                }).onEnded( { _ in
                    withAnimation(.easeInOut(duration: 0.30)) {
                        if offsetY > UIScreen.main.bounds.height * 0.2 {
                            navigation.presentMediaSheet = false
                            animateContent = false
                        } else {
                            offsetY = .zero
                        }
                        
                        //
                        
                    }
                })
        )
        .ignoresSafeArea(.container, edges: .all)
        
        .onAppear {
            if let startDate = musicManager.startDate, let endDate = musicManager.endDate {
                
                durationOfHoerspiel = endDate - startDate
                progressValue = Date.now - startDate
            } else if let persistentIdentifier = persistentIdentifier {
                Task {
                    let duration = try? await dataManager.manager.read(persistentIdentifier, keypath: \.duration)
                    await MainActor.run {
                        durationOfHoerspiel = duration
                    }
                    if let value = try? await dataManager.manager.read(persistentIdentifier, keypath: \.playedUpTo) {
                        await MainActor.run {
                            progressValue = Double(value)
                        }
                    }
                    
                }
            }
            withAnimation(.easeInOut(duration: 0.30)) {
                animateContent = true
            }
        }
        .trackNavigation(path: "PlaybackSheet")
    }
    
    // MARK: - Playerview
    
    // swiftlint:disable function_body_length
    @ViewBuilder
    func playerView() -> some View { // All controls
        GeometryReader {
            let size = $0.size
            let spacing = size.height * 0.04
            
            VStack(spacing: spacing) {
                VStack(spacing: spacing) {
                    HStack(alignment: .center, spacing: 15) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(musicManager.currentlyPlayingHoerspiel?.title ?? "Keine Wiedergabe")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(backgroundColor.playbackControlColor(colorScheme: colorScheme))
                            Text(musicManager.currentlyPlayingHoerspiel?.artist ?? "")
                                .foregroundStyle(
                                    backgroundColor
                                        .playbackControlColor(colorScheme: colorScheme)
                                        .secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        if let persistentIdentifier = persistentIdentifier {
                            HoerspielMenuView(persistentIdentifier: persistentIdentifier) {
                                Image(systemName: "ellipsis")
                                    .foregroundStyle(backgroundColor.playbackControlColor(colorScheme: colorScheme))
                                    .padding(12)
                                    .background(.ultraThinMaterial, in: Circle())
                            }
                        }
                    }
                    if let durationOfHoerspiel = durationOfHoerspiel {
                        MusicProgressSlider(
                            inRange: Double.zero...durationOfHoerspiel,
                            height: 32,
                            onEditingChanged: { point in
                                Logger.playback.info("Starting playback after using music progress slider to \(point)")
                                
                                Task {
                                    guard let persistentIdentifier = persistentIdentifier else {
                                        Logger.playback.error("Couldn't get id")
                                        return
                                    }
                                    do {
                                        try await dataManager.manager.update(
                                            persistentIdentifier,
                                            keypath: \.playedUpTo,
                                            to: Int(point))
                                        musicManager.startPlayback(for: persistentIdentifier)
                                    } catch {
                                        Logger.playback.fullError(error, sendToTelemetryDeck: true)
                                    }
                                    
                                }
                            },
                            value: .constant(progressValue),
                            persistentIdentifier: persistentIdentifier)
                        .frame(height: 40)
                        .run(everyTimeInterval: 1) {
                            if let startdate = self.musicManager.startDate {
                                progressValue = Double(Int(Date.now - startdate))
                                Logger.playback.info("Progressvalue was updated to \(progressValue)")
                            }
                        }
                    } else {
                        MusicProgressSlider(
                            inRange: Double.zero...3600,
                            activeFillColor: backgroundColor.playbackControlColor(colorScheme: colorScheme),
                            fillColor: backgroundColor.playbackControlColor(colorScheme: colorScheme).opacity(0.5),
                            emptyColor: backgroundColor.playbackControlColor(colorScheme: colorScheme).opacity(0.3),
                            height: 32,
                            onEditingChanged: { _ in },
                            value: .constant(0),
                            persistentIdentifier: persistentIdentifier
                        )
                        .frame(height: 40)
                    }
                }
                .frame(height: size.height / 2.5, alignment: .top)
                
                ZStack {
                    HStack(spacing: size.width * 0.18) {
                        Spacer()
                        Menu {
                            Picker("Schlaftimer", selection: Binding(
                                get: {
                                    return musicManager.sleepTimerDuration ?? 0
                                },
                                set: { value in
                                    if value != 0 {
                                        musicManager.startSleepTimer(for: value)
                                    } else {
                                        musicManager.stopSleepTimer()
                                    }
                                }
                            )) {
                                ForEach(sleeptimerDurations, id: \.self) { duration in
                                    if duration == 60 {
                                        Text("1 Stunde")
                                            .tag(60)
                                    } else if duration == 0 {
                                        Text("Aus")
                                            .tag(0)
                                    } else {
                                        Text("\(duration) min")
                                            .tag(duration)
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: "moon.zzz\(musicManager.sleepTimerDuration == nil ? "" : ".fill")")
                                .foregroundStyle(backgroundColor.playbackControlColor(colorScheme: colorScheme))
                                .font(.headline)
                        }
                    }
                    
                    HStack(spacing: size.width * 0.18) {
                        Button {
                            Task {
                                await musicManager.saveListeningProgressAsync()
                                guard let persistentIdentifier = persistentIdentifier,
                                      let playedUpTo = try? await dataManager.manager.read(
                                        persistentIdentifier,
                                        keypath: \.playedUpTo
                                      ) else {
                                    return
                                }
                                try? await dataManager.manager.update(
                                    persistentIdentifier,
                                    keypath: \.playedUpTo,
                                    to: playedUpTo - 15)
                                musicManager.startPlayback(for: persistentIdentifier)
                            }
                        } label: {
                            Image(systemName: "gobackward.15")
                                .font(.title)
                            
                        }
                        .disabled(disableButtons)
                        .foregroundStyle(disableButtons ? Color.gray : Color.white)
                        
                        PlayPauseButtonView {
                            if musicManager.currentlyPlayingHoerspiel != nil {
                                musicManager.togglePlayback()
                                if let startDate = musicManager.startDate {
                                    progressValue = Date.now - startDate
                                }
                            } else {
                                Task {
                                    do {
                                        let hoerspiel = try await dataManager.manager.fetchSuggestedHoerspielForPlaybck()
                                        musicManager.startPlayback(for: hoerspiel.persistentModelID)
                                    } catch {
                                        Logger.data.fullError(error, sendToTelemetryDeck: true)
                                    }
                                    if let startDate = musicManager.startDate, let endDate = musicManager.endDate {
                                        
                                        durationOfHoerspiel = endDate - startDate
                                        progressValue = Date.now - startDate
                                    }
                                }
                            }
                        }
                        .foregroundStyle(Color.white)
                        Button {
                            Task {
                                await musicManager.saveListeningProgressAsync()
                                guard let persistentIdentifier = persistentIdentifier,
                                      let playedUpTo = try? await dataManager.manager.read(
                                        persistentIdentifier,
                                        keypath: \.playedUpTo) else {
                                    return
                                }
                                try? await dataManager.manager.update(
                                    persistentIdentifier,
                                    keypath: \.playedUpTo,
                                    to: playedUpTo + 15)
                                musicManager.startPlayback(for: persistentIdentifier)
                            }
                        } label: {
                            Image(systemName: "goforward.15")
                                .font(.title)
                            
                        }
                        .disabled(disableButtons)
                        .foregroundStyle(disableButtons ? Color.gray : Color.white)
                    }
                    .frame(maxHeight: .infinity)
                }
                .frame(alignment: .bottom)
                
                VStack(alignment: .center, spacing: spacing) {
                    VolumeSlider(
                        inRange: 0...1,
                        activeFillColor: backgroundColor.playbackControlColor(colorScheme: colorScheme),
                        fillColor: backgroundColor.playbackControlColor(colorScheme: colorScheme).opacity(0.5),
                        emptyColor: backgroundColor.playbackControlColor(colorScheme: colorScheme).opacity(0.5),
                        height: 8)
                    .onAppear {
                        musicManager.volume = Double(AVAudioSession.sharedInstance().outputVolume)
                    }
                    HStack(alignment: .center) {
                        //                                                Button {
                        //
                        //                                                } label: {
                        //                                                    Image(systemName: "quote.bubble")
                        //                                                        .font(.title2)
                        //                                                }
                        //                        Spacer()
                        ////                        AirPlayView()
                        //
                        //
                        //                        VStack(spacing: 6) {
                        //                            Button {
                        //
                        //                            } label: {
                        //                                Image(systemName: "airpodspro")
                        //                                    .font(.title2)
                        //                            }
                        //                            Text("Philipp's Airpods")
                        //                                .font(.caption)
                        //                        }
                        //                        Spacer()
                        //                                                Button {
                        //
                        //                                                } label: {
                        //                                                    Image(systemName: "list.bullet")
                        //                                                        .font(.title2)
                        //                                                }
                        //                        Spacer()
                        AirPlayView()
                            .frame(width: 50, height: 50)
                    }
                    .padding(.horizontal, 30)
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(Color.white)
                    .blendMode(.overlay)
                    //                    .padding(.top, 10)
                }
                .frame(height: size.height / 2.5, alignment: .bottom)
            }
        }
        .hideVolumeHUD()
    }
    // swiftlint:enable function_body_length
}
// swiftlint:enable type_body_length

fileprivate extension Color {
    /// Returns a color used for the playback controls
    /// - Parameter colorScheme: the current ColorScheme in the view
    /// - Returns: Returns the color for the playback controls
    func playbackControlColor(colorScheme: ColorScheme) -> Color {
        if colorScheme == .dark {
            return .white
        } else {
            return self.adaptedTextColor()
        }
    }
}
