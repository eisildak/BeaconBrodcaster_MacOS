//
//  BroadcasterViewModel.swift
//  iBeaconBroadcaster
//
//  Created on February 9, 2026.
//

import Foundation
import SwiftUI
import CoreBluetooth
import Combine

class BroadcasterViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var uuidString: String
    @Published var major: UInt16
    @Published var minor: UInt16
    @Published var measuredPower: Int8
    @Published var isAdvertising: Bool = false
    @Published var statusMessage: String = "Ready"
    @Published var bluetoothState: CBManagerState = .unknown
    
    // MARK: - Private Properties
    @AppStorage("savedUUID") private var savedUUID: String?
    @AppStorage("savedMajor") private var savedMajor: Int?
    @AppStorage("savedMinor") private var savedMinor: Int?
    @AppStorage("savedPower") private var savedPower: Int?
    
    private let broadcaster = BeaconBroadcaster()
    private var shouldRestartAfterSleep = false
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var canStartBroadcasting: Bool {
        bluetoothState == .poweredOn && !isAdvertising
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
        
        // Then load saved values with safe conversions
        self.uuidString = savedUUID ?? UUID().uuidString
        
        // Safe conversion for major - clamp to UInt16 range
        if let savedMajorValue = savedMajor {
            self.major = UInt16(clamping: savedMajorValue)
        } else {
            self.major = 1
        }
        
        // Safe conversion for minor - clamp to UInt16 range
        if let savedMinorValue = savedMinor {
            self.minor = UInt16(clamping: savedMinorValue)
        } else {
            self.minor = 1
        }
        
        // Safe conversion for measured power - clamp to Int8 range
        if let savedPowerValue = savedPower {
            self.measuredPower = Int8(clamping: savedPowerValue)
        } else {
            self.measuredPower = -59
        }
        
        setupObservers()
        setupBroadcasterBindings()
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
    
    private func setupBroadcasterBindings() {
        // Bind broadcaster's published properties to our published properties
        broadcaster.$isAdvertising
            .assign(to: &$isAdvertising)
        
        broadcaster.$statusMessage
            .assign(to: &$statusMessage)
        
        broadcaster.$bluetoothState
            .assign(to: &$bluetoothState)
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
