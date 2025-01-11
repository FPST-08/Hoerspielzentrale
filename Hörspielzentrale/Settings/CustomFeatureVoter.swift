//
//  CustomFeatureVoter.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 18.06.24.
//

import OSLog
import Roadmap
import SwiftUI

/// A Feature Voter used to track votes from `RoadMap`
struct CustomFeatureVoter: FeatureVoter {
    /// The current value for a given feature
    @State var count = 0
    
    /// Fetches the current count for the given feature.
    func fetch(for feature: RoadmapFeature) async -> Int {
        let url = URL(string: "https://api.counterapi.dev/v1/hoerspielzentrale/\(feature.id)")!
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            if let statuscode = (response as? HTTPURLResponse)?.statusCode {
                if statuscode == 200 {
                    let decodedResponse = try JSONDecoder().decode(CounterAPIResponse.self, from: data)
                        count = decodedResponse.count ?? 0
                        return decodedResponse.count ?? 0
                    
                } else {
                    Logger.roadmap.error("Roadmap API returned \(statuscode) status code.")
                    Logger.roadmap.debug("\(url) \(data.base64EncodedString())")
                }
            }
        } catch {
            Logger.roadmap.fullError(error, sendToTelemetryDeck: false)
        }
        Logger.roadmap.warning("Unable to get count for \(feature.title ?? "N/A")")
        return 0
    }
    /// Votes for the given feature.
    /// - Returns: The new `count` if successful.
    func vote(for feature: RoadmapFeature) async -> Int? {
        let url = URL(string: "https://api.counterapi.dev/v1/hoerspielzentrale/\(feature.id)/up")!
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let decodedResponse = try? JSONDecoder().decode(CounterAPIResponse.self, from: data) {
                count = decodedResponse.count ?? 0
                return decodedResponse.count ?? 0
            } else {
                Logger.roadmap.error(
                    "Unable to decode response: \(String(data: data, encoding: .utf8) ?? "Unable to use utf8")")
            }
        } catch {
            Logger.roadmap.fullError(error, sendToTelemetryDeck: false)
        }
        return count
    }
    
    /// Removes a vote for the given feature.
    /// - Returns: The new `count` if successful.
    func unvote(for feature: Roadmap.RoadmapFeature) async -> Int? {
        let url = URL(string: "https://api.counterapi.dev/v1/hoerspielzentrale/\(feature.id)/down")!
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let decodedResponse = try? JSONDecoder().decode(CounterAPIResponse.self, from: data) {
                count = decodedResponse.count ?? 0
                return decodedResponse.count ?? 0
            }
            count -= 1
        } catch {
            Logger.roadmap.fullError(error, sendToTelemetryDeck: false)
        }
        return count
    }
}

/// A struct to decode the JSON Response of the CounterAPI
struct CounterAPIResponse: Codable {
    let count: Int?
}
