//
//  SeriesSelectionWorkingView.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 31.01.25.
//

import MusicKit
import SwiftUI

/// A view to let the user slelect series if a network connection exists
struct SeriesSelectionWorkingView: View {
    
    /// The current view state
    @State private var state = ViewState.loading
    
    /// Boolean to present the search sheet
    @State private var showSearchSheet = false
    
    /// An Observable Class responsible for data
    @Environment(DataManagerClass.self) var dataManager
    
    @Environment(SeriesManager.self) var seriesManager
    
    /// A closure to run to dismiss the view
    let onFinished: () -> Void
    
    /// Boolean to represent the presentation of the alert
    @State private var showSeriesDeleteAlert = false
    
    /// Storing the artist that is in the process of being deleted
    @State private var seriesToDelete: Artist?
    
    /// A boolean that indicates the buttn pressed
    @State private var buttonPressed = false
    
    /// Speficies the colums of the grid
    let colums: [GridItem] = [
        GridItem(.adaptive(minimum: 120))
    ]
    
    var body: some View {
        Group {
            switch state {
            case .loading:
                ProgressView()
            case .loadingButResults, .finished:
                ScrollView {
                    if seriesManager.selectedArtists.isEmpty {
                        ContentUnavailableView {
                            Label("Füge Serien hinzu", systemImage: "rectangle.stack.badge.plus.fill")
                        } description: {
                            Text("Drücke auf das + um deine Lieblingsserien zu finden.")
                        } actions: {
                            Button("Suchen") {
                                showSearchSheet.toggle()
                            }
                            .buttonStyle(BorderedProminentButtonStyle())
                        }
#if DEBUG
                        Button("Screenshots") {
                            Task {
                                await dataManager.manager.populateForScreenshots()
                                onFinished()
                            }
                            
                        }
#endif
                    } else {
                        LazyVGrid(columns: colums) {
                            ForEach(seriesManager.selectedArtists) { artist in
                                SeriesSelectionCircleView(series: artist)
                                    .contextMenu {
                                        if !(seriesManager.currentlyDownloadingArtist == artist) {
                                            Button(role: .destructive) {
                                                seriesToDelete = artist
                                                showSeriesDeleteAlert.toggle()
                                            } label: {
                                                Label("Löschen", systemImage: "trash")
                                            }
                                        }
                                    } preview: {
                                        if let artwork = artist.artwork {
                                            ArtworkImage(artwork, width: 100)
                                        }
                                    }
                            }
                        }
                    }
                    
                }
                .scrollBounceBehavior(.basedOnSize)
            case .error(let error):
                ContentUnavailableView("Es ist ein Fehler aufgetreten",
                                       systemImage: "exclamationmark.triangle",
                                       description: Text(error.localizedDescription))
            }
        }
        .task {
            do {
                let series = try await dataManager.manager.fetchAllSeries()
                let chunkedSeries = series.chunked(into: 25)
                var artists = [Artist]()
                for serie in chunkedSeries {
                    let musicItemIDs = serie.map { MusicItemID($0.musicItemID) }
                    let request = MusicCatalogResourceRequest<Artist>(matching: \.id,
                                                                      memberOf: musicItemIDs)
                    let response = try await request.response()
                    artists.append(contentsOf: response.items)
                }
                seriesManager.selectedArtists = artists.sorted { $0.name < $1.name }
                state = .finished
            } catch {
                state = .error(error: error)
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !seriesManager.selectedArtists.isEmpty {
                VStack {
                    if seriesManager.currentlyDownloadingArtist != nil {
                        ProgressView(value: seriesManager.currentProgressValue) {
                            Text(seriesManager.currentProgressLabel)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 30)
                    }
                    Button {
                        if !seriesManager.seriesToDownload.isEmpty {
                            buttonPressed = true
                        } else {
                            requestReviewIfAppropriate()
                            onFinished()
                        }
                    } label: {
                        Text("Weiter")
                    }
                    .buttonStyle(PrimaryButtonStyle(loading: buttonPressed, color: Color.red))
                    .padding(.horizontal, 30)
                    .onChange(of: seriesManager.seriesToDownload) { oldValue, newValue in
                        if newValue.isEmpty && buttonPressed {
                            onFinished()
                        } else if oldValue.count < newValue.count {
                            buttonPressed = false
                        }
                    }
                }
                .background(seriesManager.currentlyDownloadingArtist != nil ?
                            AnyShapeStyle(Material.ultraThickMaterial) :
                                AnyShapeStyle(Color.clear))
            }
        }
        .navigationBarBackButtonHidden()
        .toolbar {
            if state == .loadingButResults {
                ToolbarItem {
                    ProgressView()
                }
            }
            ToolbarItem {
                Button {
                    showSearchSheet.toggle()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .alert("Bist du sicher?", isPresented: $showSeriesDeleteAlert) {
            Button(role: .destructive) {
                guard let series = seriesToDelete else { return }
                seriesManager.removeSeries(series)
                seriesToDelete = nil
            } label: {
                Text("Löschen")
            }
        } message: {
            Text("Alle Hörspiele und ihre Bookmarks von \(seriesToDelete?.name ?? "N/A") werden gelöscht. ")
        }
        .sheet(isPresented: $showSearchSheet) {
            SeriesSearchView()
        }
    }
    
    /// An enum that represents the viewstate of the view
    enum ViewState {
        case loading, loadingButResults, finished, error(error: Error)
        
        static func == (lhs: ViewState, rhs: ViewState) -> Bool {
            switch (lhs, rhs) {
            case (.loading, .loading): return true
            case (.loadingButResults, .loadingButResults): return true
            case (.finished, .finished): return true
            case (.error, .error): return true
            default: return false
            }
        }
    }
}
