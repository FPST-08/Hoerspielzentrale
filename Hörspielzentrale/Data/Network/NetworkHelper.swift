//
//  networkhelper.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 04.07.24.
//

import Connectivity
import Foundation
import Network
import OSLog

/// A class that is responsible for checking the current network conditions
@Observable class NetworkHelper {
    let connectivity = Connectivity()
    
    /// The current connection status
    var connectionStatus = ConnectionStatus.working

    init() {
        let connectivityChanged: (Connectivity) -> Void = { [weak self] connectivity in
            self?.updateConnectionStatus(connectivity.status)
        }
        connectivity.whenConnected = connectivityChanged
        connectivity.whenDisconnected = connectivityChanged
        connectivity.startNotifier()
        Logger.network.info("Initializing network checking")
    }

    deinit {
        connectivity.stopNotifier()
    }
    
    /// Checks the current network condition
    func check() {
        connectivity.checkConnectivity { [weak self] connectivity in
            self?.updateConnectionStatus(connectivity.status)
        }
    }
    
    /// Updates the connectionStatus to current condition
    /// - Parameter status: The current status observed
    private func updateConnectionStatus(_ status: Connectivity.Status) {
        switch status {
        case .connected, .connectedViaCellular, .connectedViaEthernet, .connectedViaWiFi:
            connectionStatus = ConnectionStatus.working
        case .connectedViaWiFiWithoutInternet:
            connectionStatus = ConnectionStatus.notWorking(
                description: "Das WLAN scheint nicht mit dem Internet verbunden zu sein",
                systemName: "wifi.exclamationmark")
        
        case .connectedViaCellularWithoutInternet:
            connectionStatus = ConnectionStatus.notWorking(
                description: "Mobilfunk scheint nicht zu funktionieren",
                systemName: "antenna.radiowaves.left.and.right.slash")
        
        case .connectedViaEthernetWithoutInternet:
            connectionStatus = ConnectionStatus.notWorking(
                description: "Das Ethernet scheint nicht mit dem Internet verbunden zu sein",
                systemName: "network.slash")
        case .notConnected:
            connectionStatus = ConnectionStatus.notWorking(
                description: "Du scheinst nicht über WLAN oder Mobilfunk verbunden zu sein",
                systemName: "wifi.slash")
        default:
            connectionStatus = ConnectionStatus.notWorking(
                description: "Dein Verbindungsstatus ist unbekannt",
                systemName: "questionmark.square.dashed")
        }
        switch connectionStatus {
        case .working:
            Logger.network.info("Connection is working")
        case .notWorking(let description, _):
            Logger.network.notice("Connection is not working: \(description)")
        }
            
    }
}

/// An enum that indicates whether the device can establish a network condition
enum ConnectionStatus: Equatable {
    case working
    case notWorking(description: String, systemName: String)
}
