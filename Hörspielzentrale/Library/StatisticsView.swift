//
//  TodayView.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 12.07.24.
//

import MusicKit
import SwiftData
import SwiftUI

struct StatisticsView: View {
    @State private var album: Album?
    @State private var playedFragezeichenCount = 0
    @State private var allFragezeichenCount = 0
    @State private var playedKidsCount = 0
    @State private var allKidsCount = 0
    @Environment(\.modelContext) var modelContext
    @Environment(DataManagerClass.self) var dataManager
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15)
                .foregroundStyle(Color.white.opacity(0.3))
            RoundedRectangle(cornerRadius: 15)
                .foregroundStyle(Color.black)
                .padding(1)
            VStack(alignment: .leading) {
                HStack {
                    Text("Statistik und Archiv")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding([.leading, .top])
                    Spacer()
                        
                }
                Gauge(value:
                        Double(playedKidsCount + playedFragezeichenCount),
                      in: 0...Double(allKidsCount + allFragezeichenCount)) {
                    Text("""
Gehörte Folgen (\(playedKidsCount + playedFragezeichenCount)/\(allKidsCount + allFragezeichenCount))
""")
                }
                .tint(.white)
                .padding(.horizontal)
                Gauge(value: Double(playedFragezeichenCount), in: 0...Double(allFragezeichenCount)) {
                    Text("Gehörte ??? Folgen (\(playedFragezeichenCount)/\(allFragezeichenCount))")
                }
                .tint(.accentColor)
                .padding(.horizontal)
                Gauge(value: Double(playedKidsCount), in: 0...Double(allKidsCount)) {
                    Text("Gehörte Kids Folgen (\(playedKidsCount)/\(allKidsCount))")
                }
                .tint(.blue)
                .padding(.horizontal)
                Spacer()
            }
            .padding(.bottom)
        }
        .environment(\.colorScheme, .dark)
        .padding(.horizontal, 15)
//        .frame(height: 230)
        .offset(y: -20)
        .task {
            await loadData()
        }
    }
    @MainActor
    func loadData() async {
        do {
            
            playedFragezeichenCount = await (try? dataManager.manager.fetchCount( {
                let fetchDescriptor = FetchDescriptor<Hoerspiel>(predicate: #Predicate { hoerspiel in
                    hoerspiel.played == true && hoerspiel.artist == "Die drei ???"
                })
                return fetchDescriptor
            })) ?? 0
        }
        do {
            
            allFragezeichenCount = await (try? dataManager.manager.fetchCount( {
                let fetchDescriptor = FetchDescriptor<Hoerspiel>(predicate: #Predicate { hoerspiel in
                    hoerspiel.artist == "Die drei ???"
                })
                return fetchDescriptor
            })) ?? 0
        }
        
        do {
            playedKidsCount = await (try? dataManager.manager.fetchCount( {
                FetchDescriptor<Hoerspiel>(predicate: #Predicate { hoerspiel in
                    hoerspiel.played == true && hoerspiel.artist == "Die drei ??? Kids"
                })})) ?? 0
        }
        do {
            allKidsCount = await (try? dataManager.manager.fetchCount({
                FetchDescriptor<Hoerspiel>(predicate: #Predicate { hoerspiel in
                hoerspiel.artist == "Die drei ??? Kids"
            })})) ?? 0
        }
    }
    
}
