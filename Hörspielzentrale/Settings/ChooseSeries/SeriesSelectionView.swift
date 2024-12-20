//
//  OnboardingSeriesView.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 21.11.24.
//

@preconcurrency import MusicKit
import OSLog
import SwiftUI
import TelemetryDeck

/// A view to let the user slelect series
struct SeriesSelectionView: View {
    // MARK: - Properties
    @State private var selectedArtists = [Artist]()
    
    /// Boolean to present the search sheet
    @State private var showSearchSheet = false
    
    @Environment(SeriesManager.self) var seriesManager
    
    /// An Observable Class responsible for data
    @Environment(DataManagerClass.self) var dataManager
    
    /// A boolean that indicates the buttn pressed
    @State private var buttonPressed = false
    
    /// Speficies the colums of the grid
    let colums: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    /// A closure to run to dismiss the view
    var onFinished: () -> Void
    
    /// Storing the artist that is in the process of being deleted
    @State private var seriesToDelete: Artist?
    
    /// Boolean to represent the presentation of the alert
    @State private var showSeriesDeleteAlert = false
    
    /// The current view state
    @State private var state = ViewState.loading

    // MARK: - View
    var body: some View {
        Group {
            switch state {
            case .loading:
                ProgressView()
            case .loadingButResults, .finished:
                ScrollView {
                    if selectedArtists.isEmpty {
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
                            ForEach(selectedArtists) { artist in
                                SeriesSelectionCircleView(series: artist)
                                    .contextMenu {
                                        if seriesManager.currentlyDownloadingArtist != artist {
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
        .navigationTitle("Serien hinzufügen")
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
        .safeAreaInset(edge: .bottom) {
            if !selectedArtists.isEmpty {
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
                        } else if oldValue.count > newValue.count {
                            buttonPressed = false
                        }
                    }
                }
                .background(seriesManager.currentlyDownloadingArtist != nil ?
                            AnyShapeStyle(Material.ultraThickMaterial) :
                                AnyShapeStyle(Color.clear))
            }
        }
        .sheet(isPresented: $showSearchSheet) {
            SeriesSearchView(selectedSeries: $selectedArtists)
        }
        .task {
            do {
                let series = try await dataManager.manager.fetchAllSeries()
                let chunkedSeries = series.chunked(into: 25)
                for serie in chunkedSeries {
                    // swiftlint:disable:next line_length
                    let request = MusicCatalogResourceRequest<Artist>(matching: \.id, memberOf: serie.map { MusicItemID($0.musicItemID) })
                    let response = try await request.response()
                    selectedArtists.append(contentsOf: response.items)
                }
                state = .finished
            } catch {
                state = .error(error: error)
            }
        }
        .alert("Bist du sicher?", isPresented: $showSeriesDeleteAlert) {
            Button {
                
            } label: {
                Text("Abbrechen")
            }
            
            Button {
                guard let series = seriesToDelete else { return }
                selectedArtists.removeAll(where: { $0 == series })
                seriesManager.removeSeries(series)
                seriesToDelete = nil
            } label: {
                Text("Löschen")
            }
        } message: {
            Text("Alle Hörspiele und ihre Bookmarks von \(seriesToDelete?.name ?? "N/A") werden gelöscht. ")
        }
        .trackNavigation(path: "SeriesSelection")
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
