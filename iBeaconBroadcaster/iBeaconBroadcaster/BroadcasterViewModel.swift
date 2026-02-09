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
    @Published var beacons: [Beacon] = []
    @Published var uuidString: String
    @Published var major: UInt16
    @Published var minor: UInt16
    @Published var measuredPower: Int8
    @Published var beaconName: String = ""
    @Published var isAdvertising: Bool = false
    @Published var statusMessage: String = "Ready"
    @Published var bluetoothState: CBManagerState = .unknown
    @Published var currentBroadcastingBeaconId: UUID?
    @Published var showToast: Bool = false
    @Published var toastMessage: String = ""
    
    // MARK: - Private Properties
    @AppStorage("savedBeacons") private var savedBeaconsData: Data?
    
    private let broadcaster = BeaconBroadcaster()
    private var shouldRestartAfterSleep = false
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var canStartBroadcasting: Bool {
        bluetoothState == .poweredOn && !isAdvertising
    }
    
    var canAddBeacon: Bool {
        UUID(uuidString: uuidString) != nil
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
        self.uuidString = UUID().uuidString
        self.major = 1
        self.minor = 1
        self.measuredPower = -59
        
        // Load saved beacons
        loadBeacons()
        
        setupObservers()
        setupBroadcasterBindings()
    }
    
    // MARK: - Public Methods
    
    func addBeacon() {
        guard let uuid = UUID(uuidString: uuidString) else {
            return
        }
        
        let newBeacon = Beacon(
            name: beaconName.isEmpty ? "Beacon \(beacons.count + 1)" : beaconName,
            uuidString: uuid.uuidString,
            major: major,
            minor: minor,
            measuredPower: measuredPower,
            isEnabled: false
        )
        
        beacons.append(newBeacon)
        saveBeacons()
        
        // Reset form
        generateNewUUID()
        beaconName = ""
        major = 1
        minor = 1
        measuredPower = -59
    }
    
    func removeBeacon(_ beacon: Beacon) {
        if beacon.isEnabled && isAdvertising {
            broadcaster.stopBroadcastingBeacon(id: beacon.id)
        }
        beacons.removeAll { $0.id == beacon.id }
        saveBeacons()
        updateBroadcastingState()
    }
    
    func toggleBeacon(_ beacon: Beacon) {
        if let index = beacons.firstIndex(where: { $0.id == beacon.id }) {
            // Check if we're trying to enable a beacon
            if !beacons[index].isEnabled {
                // Count currently enabled beacons
                let enabledCount = beacons.filter { $0.isEnabled }.count
                
                // Don't allow more than 2 active beacons
                if enabledCount >= 2 {
                    showToastMessage("You can only broadcast 2 beacons at the same time!")
                    return
                }
            }
            
            beacons[index].isEnabled.toggle()
            
            if beacons[index].isEnabled {
                startBroadcastingBeacon(beacons[index])
            } else {
                broadcaster.stopBroadcastingBeacon(id: beacon.id)
                updateBroadcastingState()
            }
            
            saveBeacons()
        }
    }
    
    func canEnableBeacon(_ beacon: Beacon) -> Bool {
        if beacon.isEnabled {
            return true // Can always disable
        }
        let enabledCount = beacons.filter { $0.isEnabled }.count
        return enabledCount < 2
    }
    
    private func showToastMessage(_ message: String) {
        toastMessage = message
        showToast = true
        
        // Auto-hide after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.showToast = false
        }
    }
    
    func toggleBroadcasting() {
        if isAdvertising {
            stopAllBroadcasting()
        } else {
            startAllBroadcasting()
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
        saveBeacons()
    }
    
    // MARK: - Private Methods
    
    private func loadBeacons() {
        guard let data = savedBeaconsData else { return }
        
        do {
            let decoder = JSONDecoder()
            var loadedBeacons = try decoder.decode([Beacon].self, from: data)
            
            // Disable all beacons on app launch
            for index in loadedBeacons.indices {
                loadedBeacons[index].isEnabled = false
            }
            
            beacons = loadedBeacons
        } catch {
            print("Failed to load beacons: \(error)")
        }
    }
    
    private func saveBeacons() {
        do {
            let encoder = JSONEncoder()
            savedBeaconsData = try encoder.encode(beacons)
        } catch {
            print("Failed to save beacons: \(error)")
        }
    }
    
    private func startBroadcastingBeacon(_ beacon: Beacon) {
        guard let uuid = beacon.beaconUUID else {
            return
        }
        
        broadcaster.startBroadcastingBeacon(
            id: beacon.id,
            uuid: uuid,
            major: beacon.major,
            minor: beacon.minor,
            measuredPower: beacon.measuredPower
        )
        
        updateBroadcastingState()
    }
    
    private func startAllBroadcasting() {
        for beacon in beacons where beacon.isEnabled {
            startBroadcastingBeacon(beacon)
        }
    }
    
    private func stopAllBroadcasting() {
        broadcaster.stopAllBroadcasting()
        updateBroadcastingState()
    }
    
    private func updateBroadcastingState() {
        let activeBeacons = beacons.filter { $0.isEnabled }
        isAdvertising = !activeBeacons.isEmpty && broadcaster.hasActiveBeacons
        
        if isAdvertising {
            statusMessage = "Broadcasting \(activeBeacons.count) beacon(s)"
        } else {
            statusMessage = "Ready"
        }
    }
    
    private func startBroadcasting() {
        guard let uuid = UUID(uuidString: uuidString) else {
            return
        }
        
        broadcaster.startBroadcastingBeacon(
            id: UUID(),
            uuid: uuid,
            major: major,
            minor: minor,
            measuredPower: measuredPower
        )
    }
    
    private func stopBroadcasting() {
        broadcaster.stopAllBroadcasting()
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
        
        broadcaster.$currentBroadcastingBeaconId
            .assign(to: &$currentBroadcastingBeaconId)
    }
    
    @objc private func handleSleepNotification() {
        if isAdvertising {
            shouldRestartAfterSleep = true
            stopAllBroadcasting()
        }
    }
    
    @objc private func handleWakeNotification() {
        if shouldRestartAfterSleep {
            startAllBroadcasting()
            shouldRestartAfterSleep = false
        }
    }
}
