//
//  Acknowledgements.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 15.06.24.
//

import AcknowList
import Foundation

/// An array of Packages shown in the `AcknowListView`
@MainActor let acknowledgements: [Acknow] = [
    Acknow(title: "Roadmap", repository: URL(string: "https://github.com/AvdLee/Roadmap")),
    Acknow(title: "AcknowList", repository: URL(string: "https://github.com/vtourraine/AcknowList")),
    Acknow(title: "WhatsNewKit", repository: URL(string: "https://github.com/SvenTiigi/WhatsNewKit")),
    Acknow(title: "dreimetadaten", repository: URL(string: "https://github.com/YourMJK/dreimetadaten")),
    Acknow(title: "Connectivity", repository: URL(string: "https://github.com/rwbutler/Connectivity")),
    Acknow(title: "CloudKitSyncMonitor", repository: URL(string: "https://github.com/ggruen/CloudKitSyncMonitor")),
    Acknow(title: "SwiftLintPlugins", repository: URL(string: "https://github.com/SimplyDanny/SwiftLintPlugins"))
].sorted { $0.title < $1.title}
