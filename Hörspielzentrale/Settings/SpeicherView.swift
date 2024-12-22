//
//  CacheView.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 01.11.24.
//

import CloudKitSyncMonitor
import SwiftUI
import TelemetryDeck

/// A view to modify the overall storage behaviour
struct SpeicherView: View {
    
    /// The current size of the cover as textual representation
    @State private var coversize = CoverSize.small
    
    @ObservedObject var syncMonitor = SyncMonitor.default
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .center) {
                    ZStack {
                        ContainerRelativeShape()
                            .foregroundStyle(.gray)
                        Image(systemName: "internaldrive")
                            .padding(10)
                            .font(.title.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 60, height: 60)
                    .cornerRadius(10)
                    Text("Speicher")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("Passe das Speicher-Verhalten der Hörspielzentrale an")
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }
            
            Section {
                HStack {
                    Image(systemName: syncMonitor.syncStateSummary.symbolName)
                                     .foregroundColor(syncMonitor.syncStateSummary.symbolColor)
                    Text(syncMonitor.syncStateSummary.description)
                }
            }
            
            Section {
                Picker("Cover-Größe", selection: $coversize) {
                    ForEach(CoverSize.allSizes, id: \.self) { size in
                        Text("\(size.description) (\(size.width, format: .number.grouping(.never))px)")
                            .tag(size.description)
                    }
                }
                .onAppear {
                    let savedString = UserDefaults.standard.string(forKey: "coversize")
                    if let savedString {
                        coversize = CoverSize(savedString)
                    }
                }
                .onDisappear {
                    UserDefaults.standard.set(coversize.description, forKey: "coversize")
                }
            }
        }
        .trackNavigation(path: "Storage")
    }
}
