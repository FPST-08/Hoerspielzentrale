//
//  RunViewModifier.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 23.09.24.
//

import OSLog
import SwiftUI

extension View {
    /// A view modifer to run a specific block of code at a specific time interval
    /// - Parameters:
    ///   - timeInterval: A time interval the code should be run after each time. specified in seconds
    ///   - block: A code block that is run at the timeinterval
    /// - Returns: Returns the same view with the modifier attached
    /// - The block will automatically start running when the parent view appeared
    /// and stop running once the view disappeared
    func run(
        everyTimeInterval timeInterval: TimeInterval,
        block: (@escaping () -> Void)
    ) -> some View {
        modifier(RunViewModifier(timeInterval: timeInterval, block: block))
    }
}

/// A ViewModifier Struct to run a specifc block of code at a specified time interval
struct RunViewModifier: ViewModifier {
    /// A time interval the code should be run after each time. specified in seconds
    let timeInterval: TimeInterval
    /// A code block that is run at the timeinterval
    let block: (() -> Void)
    
    @State private var timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: { _ in })
    
    /// Creates the body of the modifier
    /// - Parameter content: The view that the modifier will be attached to
    /// - Returns: Returns the view with the modifier attached
    func body(content: Content) -> some View {
        content
            .onAppear {
                Logger.runViewModifier.info("Started timer with timeInterval \(timeInterval)")
                timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true, block: { _ in
                    block()
                    Logger.runViewModifier.info("Ran block")
                })
            }
            .onDisappear {
                timer.invalidate()
                Logger.runViewModifier.info("Timer was invalidated")
            }
    }
    
    /// Initializer of the ViewModifier Struct
    /// - Parameters:
    ///   - timeInterval: A time interval the code should be run after each time. specified in seconds
    ///   - block: A code block that is run at the timeinterval
    init(timeInterval: TimeInterval, block: @escaping (() -> Void)) {
        self.timeInterval = timeInterval
        self.block = block
    }
}
