//
//  SuggestionView.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 18.10.24.
//

import OSLog
import SwiftData
import SwiftUI

/// A view used to display a ``SendableHoerspiel`` in multiple ways
struct HoerspielDisplayView: View {
    // MARK: - Properties
    
    /// The ``SendableHoerspiel`` to display in this view
    let sendableHoerspiel: SendableHoerspiel
    
    /// The displaymode of the current view
    @State private var displaymode: DisplayMode
    
    /// Referencing an `@Observable` class responsible for loading and caching covers
    @Environment(ImageCache.self) var imageCache
    
    /// An Observable Class responsible for data
    @Environment(DataManagerClass.self) var dataManager
    
    /// The cover
    @State private var image: Image?
    
    /// The description of the ``SendableHoerspiel``
    @State private var description = String()
    
    /// The dominant color of the cover
    @State private var dominantColor = Color.black
    
    @Namespace var namespace
    
    /// The width of the view
    var width: CGFloat {
        switch displaymode {
        case .rectangular:
            if UIDevice.isIpad {
                return 400
            } else {
                return UIScreen.screenWidth * 0.9
            }
            
        case .coverOnly:
            return 120
        case .big:
            if UIDevice.isIpad {
                return 300
            } else {
                return UIScreen.screenWidth * 0.9
            }
            
        case .rectangularSmall:
            if UIDevice.isIpad {
                return 400
            } else {
                return UIScreen.screenWidth * 0.8
            }
        }
    }
    
    /// The height of the view
    var height: CGFloat {
        switch displaymode {
        case .rectangular, .rectangularSmall:
            return 140
        case .coverOnly:
            return 120
        case .big:
            if UIDevice.isIpad {
                return 300
            } else {
                return UIScreen.screenWidth * 0.9
            }
        }
    }
    
    // MARK: - View
    var body: some View {
        NavigationLink {
            HoerspielDetailView(sendableHoerspiel)
                .backwardsNavigationTransition("zoom", in: namespace)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .foregroundStyle(Color.white.opacity(0.3))
                RoundedRectangle(cornerRadius: 15)
                    .foregroundStyle(dominantColor)
                    .padding(1)
                switch displaymode {
                case .rectangular, .rectangularSmall:
                    rectangular
                case .coverOnly:
                    if let image {
                        image
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(15)
                            
                    }
                case .big:
                    ZStack(alignment: .bottomTrailing) {
                        if let image {
                            image
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(15)
                        }
                        PlayPreView(
                            backgroundColor: .white,
                            textColor: dominantColor,
                            persistentIdentifier: sendableHoerspiel.persistentModelID)
                            .frame(alignment: .bottomTrailing)
                            .padding()
                    }
                }
            }
            .frame(width: width, height: height)
            .backwardsMatchedTransitionSource(id: "zoom", in: namespace)
        }
        .task {
            if image == nil && description == "" {
                await loadData()
            }
        }
    }
    
    /// The view used for a rectangular presentation mode
    var rectangular: some View {
        HStack(spacing: 0) {
            if let image {
                image
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(15)
                    .frame(maxHeight: .infinity)
                    .padding(8)
            } else {
                RoundedRectangle(cornerRadius: 15)
                    .foregroundStyle(Color.gray)
                    .frame(width: 125)
                    .frame(maxHeight: .infinity)
                    .padding(8)
            }
            VStack(alignment: .leading) {
                Text(sendableHoerspiel.title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundStyle(dominantColor.adaptedTextColor())
                    .padding(.top, 5)
                    .multilineTextAlignment(.leading)
                Text(description)
                    .font(.subheadline)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(dominantColor.adaptedTextColor().secondary)
                Spacer()
                HStack {
                    PlayPreView(
                        backgroundColor: .white,
                        textColor: dominantColor,
                        persistentIdentifier: sendableHoerspiel.persistentModelID)
                        .padding(.bottom, 10)
                    Spacer()
                }
            }
            Spacer()
        }
    }

    // MARK: - Functions

    /// Loads all data required for this view
    func loadData() async {
        do {
            guard let uiimage = await imageCache.uiimage(for: sendableHoerspiel,
                                                         size: displaymode == .big ? .fullResolution : .small) else {
                return
            }
            Task.detached {
                guard let uicolor = uiimage.averageColor else {
                    return
                }
                await MainActor.run {
                    dominantColor = Color(uiColor: uicolor)
                }
            }
            image = Image(uiImage: uiimage)

            if sendableHoerspiel.releaseDate.isFuture() {
                description = "Erscheint am \(sendableHoerspiel.releaseDate.formatted(date: .long, time: .omitted))"
            } else {
                let metadata = try? await sendableHoerspiel.loadMetaData()
                description = (metadata?.beschreibung ?? "") + " " + (metadata?.kurzbeschreibung ?? "")
                    .trimmingCharacters(in: .whitespaces)
            }
        }
    }

    init(_ sendableHoerspiel: SendableHoerspiel, _ displaymode: DisplayMode = .rectangular) {
        self.image = nil
        self.sendableHoerspiel = sendableHoerspiel
        self.displaymode = displaymode
    }
}

enum DisplayMode {
    case rectangular, coverOnly, big, rectangularSmall
}
