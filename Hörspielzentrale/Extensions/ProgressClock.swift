//
//  ProgressClock.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 22.11.24.
//

import SwiftUI

struct ProgressClockViewModifier: ViewModifier {
    let value: Double
    let color: Color
    let width: Double
    let height: Double
    let disabled: Bool
    func body(content: Content) -> some View {
        if disabled {
            content
                .frame(width: width, height: height)
        } else {
            GeometryReader { proxy in
                ZStack {
                    content
                    Circle()
                        .inset(by: proxy.size.width / 4)
                        .trim(from: 0, to: 1 - value)
                        .stroke(color, style: StrokeStyle(lineWidth: proxy.size.width / 2))
                        .rotationEffect(.radians(-.pi/2))
                        .animation(.linear, value: value)
                        .scaleEffect(x: -1)
                }
            }
            .frame(width: width, height: height)
        }
    }
}

extension View {
    func progressClock(value: Double,
                       color: Color,
                       width: Double,
                       height: Double,
                       disabled: Bool = false
    ) -> some View {
        modifier(ProgressClockViewModifier(value: value,
                                           color: color,
                                           width: width,
                                           height: height,
                                           disabled: disabled))
    }
}
