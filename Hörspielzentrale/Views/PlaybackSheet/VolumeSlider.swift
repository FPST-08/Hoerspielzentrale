//
//  VolumeSlider.swift
//  diedreifragezeichenplayer
//
//  Created by Philipp Steiner on 22.04.24.
//

import AVKit
import OSLog
import SwiftUI

/// A slider to modify the volume
///
///  Due to API limitations the VolumeSlider can not adapt to volume button presses.
///  Using MPVolumeView is an alternative that provides the functionality but
///  its design cannot be properly modified.
struct VolumeSlider<T: BinaryFloatingPoint>: View {
    // MARK: - Properties
    /// The current value
    @State private var value: T = 0
    /// The range the `value` can move in
    let inRange: ClosedRange<T>
    
    /// The color of the filled area while changing
    let activeFillColor: Color
    
    /// The color of the filled area
    let fillColor: Color
    
    /// The color of the unfilled area
    let emptyColor: Color
    
    /// The height of the slider
    ///
    /// The default value is 8
    let height: CGFloat
    
    /// A copy of ``value`` used to persistent the value while editing
    @State private var localRealProgress: T = 0
    
    /// The amount of moved area relative to ``localRealProgress``
    @State private var localTempProgress: T = 0
    
    /// Indicates currently active editing
    @GestureState private var isActive: Bool = false
    
    /// Referencing an `Observable` class responsible for playback
    @Environment(MusicManager.self) var musicplayer
    
    // MARK: - View
    var body: some View {
        GeometryReader { bounds in
            ZStack {
                
                HStack {
                    Image(systemName: "speaker.fill")
                        .font(.system(.title2))
                        .foregroundColor(isActive ? activeFillColor : fillColor)
                    
                    GeometryReader { geo in
                        ZStack(alignment: .center) {
                            Capsule()
                                .fill(emptyColor)
                            Capsule()
                                .fill(isActive ? activeFillColor : fillColor)
                                .mask({
                                    HStack {
                                        Rectangle()
                                            .frame(
                                                width:
                                                    max(geo.size.width * CGFloat(
                                                        localRealProgress + localTempProgress),
                                                        0),
                                                alignment: .leading)
                                        Spacer(minLength: 0)
                                    }
                                })
                        }
                    }
                    
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(isActive ? activeFillColor : fillColor)
                }
                .frame(width: isActive ? bounds.size.width * 1.04 : bounds.size.width, alignment: .center)
//                .shadow(color: .black.opacity(0.1), radius: isActive ? 20 : 0, x: 0, y: 0)
                .animation(animation, value: isActive)
            }
            .frame(width: bounds.size.width, height: bounds.size.height, alignment: .center)
            .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .updating($isActive) { _, state, _ in
                    state = true
                    
                    setVolume(to: Double(localRealProgress + localTempProgress))
                }
                .onChanged { gesture in
                    localTempProgress = T(gesture.translation.width / bounds.size.width)
                    value = max(min(getPrgValue(), inRange.upperBound), inRange.lowerBound)
                }.onEnded { _ in
                    localRealProgress = max(min(localRealProgress + localTempProgress, 1), 0)
                    localTempProgress = 0
                    musicplayer.volume = Double(max(min(getPrgValue(), inRange.upperBound), inRange.lowerBound))
                })
            .onAppear {
                localRealProgress = getPrgPercentage(T(musicplayer.volume))
//
            }
            .onChange(of: musicplayer.volume) { _, newValue in
                
                if !isActive {
                    localRealProgress = getPrgPercentage(T(newValue))
                }
            }

        }
        .frame(height: isActive ? height * 2 : height, alignment: .center)
    }
    
    // MARK: - Functions
    
    private var animation: Animation {
        if isActive {
            return .spring()
        } else {
            return .spring(response: 0.5, dampingFraction: 0.5, blendDuration: 0.6)
        }
    }
    
    private func getPrgPercentage(_ value: T) -> T {
        let range = inRange.upperBound - inRange.lowerBound
        let correctedStartValue = value - inRange.lowerBound
        let percentage = correctedStartValue / range
        return percentage
    }
    
    private func getPrgValue() -> T {
        return (
            (localRealProgress + localTempProgress) * (inRange.upperBound - inRange.lowerBound)
        ) + inRange.lowerBound
    }
}
