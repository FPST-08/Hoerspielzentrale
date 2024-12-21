//
//  MusicProgressSlider.swift
//  Custom Seekbar
//
//  Created by Pratik on 08/01/23.
//

import MediaPlayer
import MusicKit
import OSLog
import SwiftData
import SwiftUI

/// A scrubbing bar for a currently playing ``Hoerspiel``
struct MusicProgressSlider: View {
    // MARK: - Properties
    /// The current playback state
    @ObservedObject var state = ApplicationMusicPlayer.shared.state
    
    /// Referencing an `Observable` class responsible for playback
    @Environment(MusicManager.self) var musicplayer
    
    /// The range of the slider
    let inRange: ClosedRange<Double>
    
    /// The color used for past space when scrubbing
    var activeFillColor: Color = .white
    
    /// The color used for past space
    var fillColor: Color = Color.white.opacity(0.5)
    /// The color used for remaining space
    var emptyColor: Color = Color.white.opacity(0.3)
    
    /// The height of the slider
    let height: CGFloat
    
    // A closure used for calling when scrubbing ended
    let onEditingChanged: (_ point: Double) -> Void
    
    /// The current value of the playhead
    @Binding var value: Double
    
    /// The local equivalent to ``value``
    @State private var localRealProgress: Double = 0
    
    /// The local progress when scrubbing
    @State private var localTempProgress: Double = 0
    
    /// A bool indicating active scrubbing
    @GestureState private var isActive: Bool = false
    
    /// Used to display remaining time when scrubbing
    @State private var progressDuration: Double = 0
    
    /// The `persistentIdentifier` for the currently playing ``Hoerspiel``
    let persistentIdentifier: PersistentIdentifier?
    
    // MARK: - View
    var body: some View {
        GeometryReader { bounds in
            ZStack {
                VStack {
                    
                    ZStack(alignment: .center) {
                        Capsule()
                            .fill(emptyColor)
                        
                        Capsule()
                        
                            .fill(isActive ? activeFillColor : fillColor)
                            .mask({
                                HStack {
                                    Rectangle()
                                    
                                        .frame(
                                            width: max(
                                                bounds.size.width * CGFloat(
                                                    (localRealProgress + localTempProgress)),
                                                0),
                                            alignment: .leading)
                                    
                                    Spacer(minLength: 0)
                                }
                            })
                    }
                    
                    HStack {
                        if musicplayer.currentlyPlayingHoerspiel != nil {
                            Text(progressDuration.customFormatted())
                            
                            if let sleeptimerDate = musicplayer.sleeptimerDate {
                                Spacer(minLength: 0)
                                Text(sleeptimerDate, style: .timer)
                            }

                            Spacer(minLength: 0)

                            Text("- " + (inRange.upperBound - progressDuration).customFormatted())
                        } else {
                            Text("0:00")
                            Spacer()
                            Text("0:00")
                        }
                    }
                    .font(.system(.headline, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(isActive ? fillColor : emptyColor)
                    
                }
                .frame(width: isActive ? bounds.size.width * 1.04 : bounds.size.width, alignment: .center)
                .animation(animation, value: isActive)
            }
            .frame(width: bounds.size.width, height: bounds.size.height, alignment: .center)
            .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .updating($isActive) { _, state, _ in
                    state = true
                }
                .onChanged { gesture in
                    localTempProgress = Double(gesture.translation.width / bounds.size.width)
                    let prg = max(min((localRealProgress + localTempProgress), 1), 0)
                    progressDuration = inRange.upperBound * prg
                    value = max(min(getPrgValue(), inRange.upperBound), inRange.lowerBound)
                }.onEnded { _ in
                    localRealProgress = max(min(localRealProgress + localTempProgress, 1), 0)
                    localTempProgress = 0
                    progressDuration = inRange.upperBound * localRealProgress
                }
            )
            .onChange(of: isActive) { _, newValue in
                
                Task(priority: .high) {
                    if state.playbackStatus == .playing {
                        musicplayer.musicplayer.pause()
                    }
                    await MainActor.run { // Update UI on main thread after pausing
                        value = max(min(getPrgValue(), inRange.upperBound), inRange.lowerBound)
                        if !newValue {
                            onEditingChanged(progressDuration)
                        }
                    }
                }
            }
            .onAppear {
                localRealProgress = getPrgPercentage(value)
                progressDuration = inRange.upperBound * localRealProgress
            }
            .onChange(of: value) { _, newValue in
                if !isActive {
                    progressDuration = newValue
                    localRealProgress = newValue / inRange.upperBound
                }
            }
        }
        .allowsHitTesting(state.playbackStatus == .playing || state.playbackStatus == .paused)
        .frame(height: isActive ? height * 1.25 : height, alignment: .center)
    }
    
    // MARK: - Functions
    
    /// The currently needed animation
    private var animation: Animation {
        if isActive {
            return .spring()
        } else {
            return .spring(response: 0.5, dampingFraction: 0.5, blendDuration: 0.6)
        }
    }
    
    /// Returns the percentage of the progress
    private func getPrgPercentage(_ value: Double) -> Double {
        let range = inRange.upperBound - inRange.lowerBound
        let correctedStartValue = value - inRange.lowerBound
        let percentage = correctedStartValue / range
        return percentage
    }
    
    /// Returns the current progress
    private func getPrgValue() -> Double {
        return (
            (localRealProgress + localTempProgress) * (inRange.upperBound - inRange.lowerBound)
        ) + inRange.lowerBound
    }
}
