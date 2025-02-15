//
//  PlaybackPlayerView.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 26.01.25.
//

import AVFAudio
import SwiftData
import SwiftUI

/// A view to display all playback control related views
struct PlaybackPlayerView: View {
    /// The background color
    let backgroundColor: Color
    
    /// Referencing an `Observable` class responsible for playback
    @Environment(MusicManager.self) var musicManager
    
    /// An Observable Class responsible for data
    @Environment(DataManagerClass.self) var dataManager
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        GeometryReader {
            let size = $0.size
            let spacing = size.height * 0.04
            
            VStack(spacing: spacing) {
                VStack(spacing: spacing) {
                    PlaybackInfoView(backgroundColor: backgroundColor)
                    MusicProgressSlider(
                        inRange: Double.zero...(musicManager.currentlyPlayingHoerspiel?.duration ?? 3600))
                    .frame(height: 40)
                }
                .frame(height: size.height / 2.5, alignment: .top)
                
                PlaybackControlsView(size: size,
                                     backgroundColor: backgroundColor)
                
                VStack(alignment: .center, spacing: spacing) {
                    VolumeSlider()
                    .onAppear {
                        musicManager.volume = Double(AVAudioSession.sharedInstance().outputVolume)
                    }
                    HStack(alignment: .center) {
//                        Button {
//
//                        } label: {
//                            Image(systemName: "quote.bubble")
//                                .font(.title2)
//                        }
//                        Spacer()
//                        //                        AirPlayView()
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
//                        Button {
//
//                        } label: {
//                            Image(systemName: "list.bullet")
//                                .font(.title2)
//                        }
//                        Spacer()
                        AirPlayView()
                            .frame(width: 50, height: 50)
                    }
                    .padding(.horizontal, 30)
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(Color.white)
                    .blendMode(.overlay)
                }
                .frame(height: size.height / 2.5, alignment: .bottom)
            }
        }
        .hideVolumeHUD()
        .playerViewSize()
        
    }
}
