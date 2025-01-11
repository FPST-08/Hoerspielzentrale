//
//  SpeakerView.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 14.08.24.
//

import SwiftUI

/// A view that presents the speakers of a ``Hoerspiel``
struct SpeakerView: View {
    // MARK: - Properties
    /// An array of ``Sprechrolle`` that will be displayed
    let rollen: [Sprechrolle]
    
    // MARK: - View
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(rollen, id: \.self) { rolle in
                    Link(destination: rolle.sprecher.wikiURL()) {
                        VStack {
                            ZStack {
                                Circle()
                                    .frame(width: 90, height: 90)
                                    .foregroundStyle(Color.gray.gradient)
                                Text(rolle.sprecher.initials())
                                    .foregroundStyle(Color.white)
                                    .font(.title.bold())
                            }
                            Text(rolle.sprecher)
                                .foregroundStyle(Color.primary)
                                .font(.caption)
                                .lineLimit(1)
                            Text(rolle.rolle)
                                .font(.caption)
                                .foregroundStyle(Color.secondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                            Spacer()
                        }
                        .frame(width: 110)
                    }
                }
                
            }
        }
        .scrollIndicators(.never)
    }
}

extension String {
    /// Initials from a name
    /// - Returns: Returns a String consisting of two letters representing the initials
    func initials() -> String {
        let comps = self.components(separatedBy: " ")
        guard let first = comps.first else {
            return "\(self.prefix(2))"
        }
        guard let last = comps.last else {
            return "\(self.prefix(2))"
        }
        return "\(first.prefix(1))\(last.prefix(1))"
    }
}

extension String {
    /// The URL to a persom's wikipedia article
    /// - Returns: Returns the URL
    func wikiURL() -> URL {
        let name = self.replacingOccurrences(of: " ", with: "_")
        guard let url = URL(string: "https://de.wikipedia.org/wiki/\(name)") else {
            preconditionFailure()
        }
        return url
    }
}
