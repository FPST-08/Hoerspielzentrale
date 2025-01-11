//
//  Extensions.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 11.01.25.
//

import Foundation

extension Array where Element == SendableStoredTrack {
    /// Sorts an array of ``SendableStoredTrack`` starting with the lowest index
    /// - Returns: The sorted array
    func sorted() -> [SendableStoredTrack] {
        self.sorted { $0.index < $1.index }
    }
}
