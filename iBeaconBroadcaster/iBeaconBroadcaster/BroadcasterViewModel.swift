//
//  BroadcasterViewModel.swift
//  iBeaconBroadcaster
//
//  Created on February 9, 2026.
//

import Foundation
import SwiftUI
import CoreBluetooth

class BroadcasterViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var uuidString: String
    @Published var major: UInt16
    @Published var minor: UInt16
    @Published var measuredPower: Int8
    
    // MARK: - Private Properties
    @AppStorage("savedUUID") private var savedUUID: String?
    @AppStorage("savedMajor") private var savedMajor: Int?
    @AppStorage("savedMinor") private var savedMinor: Int?
    @AppStorage("savedPower") private var savedPower: Int?
    
    private let broadcaster = BeaconBroadcaster()
    private var shouldRestartAfterSleep = false
    
    // MARK: - Computed Properties
    var isAdvertising: Bool {
        broadcaster.isAdvertising
    }
    
    var statusMessage: String {
        broadcaster.statusMessage
    }
    
    var canStartBroadcasting: Bool {
        broadcaster.bluetoothState == .poweredOn && !isAdvertising
    }
    
    // MARK: - Formatters
    let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.allowsFloats = false
        formatter.minimum = 0
        formatter.maximum = NSNumber(value: UInt16.max)
        return formatter
    }()
    
    let powerFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.allowsFloats = false
        formatter.minimum = NSNumber(value: Int8.min)
        formatter.maximum = NSNumber(value: Int8.max)
        return formatter
    }()
    
    // MARK: - Initialization
    init() {
        // Initialize stored properties first
        self.uuidString = ""
        self.major = 0
        self.minor = 0
        self.measuredPower = -59
        
        // Then load saved values
        self.uuidString = savedUUID ?? UUID().uuidString
        self.major = UInt16(savedMajor ?? 1)
        self.minor = UInt16(savedMinor ?? 1)
        self.measuredPower = Int8(savedPower ?? -59)
        
        setupObservers()
    }
    
    // MARK: - Public Methods
    
    func toggleBroadcasting() {
        if isAdvertising {
            stopBroadcasting()
        } else {
            startBroadcasting()
        }
    }
    
    func generateNewUUID() {
        uuidString = UUID().uuidString
    }
    
    func copyUUIDToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(uuidString, forType: .string)
    }
    
    func saveSettings() {
        savedUUID = uuidString
        savedMajor = Int(major)
        savedMinor = Int(minor)
        savedPower = Int(measuredPower)
    }
    
    // MARK: - Private Methods
    
    private func startBroadcasting() {
        guard let uuid = UUID(uuidString: uuidString) else {
            return
        }
        
        broadcaster.startBroadcasting(
            uuid: uuid,
            major: major,
            minor: minor,
            measuredPower: measuredPower
        )
    }
    
    private func stopBroadcasting() {
        broadcaster.stopBroadcasting()
    }
    
    private func setupObservers() {
        // Observe system sleep/wake notifications
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleSleepNotification),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )
        
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleWakeNotification),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }
    
    @objc private func handleSleepNotification() {
        if isAdvertising {
            shouldRestartAfterSleep = true
            stopBroadcasting()
        }
    }
    
    @objc private func handleWakeNotification() {
        if shouldRestartAfterSleep {
            startBroadcasting()
            shouldRestartAfterSleep = false
        }
    }
}
