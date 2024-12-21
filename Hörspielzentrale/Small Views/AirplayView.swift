//
//  AirplayView.swift
//  diedreifragezeichenplayer
//
//  Created by Philipp Steiner on 22.04.24.
//

import AVKit
import AVRouting
import SwiftUI

/// A view that presents the `AirplayRountingView`on tap
struct AirPlayView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let routePickerView = AVRoutePickerView()
        routePickerView.backgroundColor = UIColor.clear
        routePickerView.activeTintColor = UIColor.black
        routePickerView.tintColor = UIColor.white
        return routePickerView
    }
    func updateUIView(_ uiView: UIView, context: Context) {
    }
}
