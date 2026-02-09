//
//  BeaconBroadcaster.swift
//  iBeaconBroadcaster
//
//  Created on February 9, 2026.
//

import Foundation
import CoreBluetooth
import CoreLocation

/// Manages iBeacon broadcasting using CoreBluetooth
class BeaconBroadcaster: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var isAdvertising: Bool = false
    @Published var statusMessage: String = "Ready"
    @Published var bluetoothState: CBManagerState = .unknown
    @Published var currentBroadcastingBeaconId: UUID?
    
    // MARK: - Private Properties
    private var peripheralManager: CBPeripheralManager?
    private var beaconDataStore: [UUID: BeaconData] = [:]
    private var rotationTimer: Timer?
    private var rotationInterval: TimeInterval = 5.0 // 5 seconds per beacon
    private var currentRotationIndex: Int = 0
    
    var hasActiveBeacons: Bool {
        !beaconDataStore.isEmpty
    }
    
    private struct BeaconData {
        let id: UUID
        let uuid: UUID
        let major: UInt16
        let minor: UInt16
        let measuredPower: Int8
    }
    
    // MARK: - Initialization
    override init() {
        super.init()
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    // MARK: - Public Methods
    
    /// Start broadcasting a specific iBeacon
    func startBroadcastingBeacon(id: UUID, uuid: UUID, major: UInt16, minor: UInt16, measuredPower: Int8) {
        let data = BeaconData(
            id: id,
            uuid: uuid,
            major: major,
            minor: minor,
            measuredPower: measuredPower
        )
        
        beaconDataStore[id] = data
        
        // Start rotation if not already running
        if rotationTimer == nil {
            startRotation()
        }
        
        updateStatus()
    }
    
    /// Stop broadcasting a specific beacon
    func stopBroadcastingBeacon(id: UUID) {
        beaconDataStore.removeValue(forKey: id)
        
        // Stop rotation if no beacons left
        if beaconDataStore.isEmpty {
            stopRotation()
        } else {
            // If we removed the currently broadcasting beacon, move to next
            if currentBroadcastingBeaconId == id {
                rotateToNextBeacon()
            }
        }
        
        updateStatus()
    }
    
    /// Stop all broadcasting
    func stopAllBroadcasting() {
        stopRotation()
        beaconDataStore.removeAll()
        peripheralManager?.stopAdvertising()
        isAdvertising = false
        currentBroadcastingBeaconId = nil
        statusMessage = "Broadcasting stopped"
    }
    
    // MARK: - Private Methods
    
    private func startRotation() {
        guard peripheralManager?.state == .poweredOn else { return }
        
        // Start with the first beacon
        currentRotationIndex = 0
        rotateToNextBeacon()
        
        // Setup timer for rotation
        rotationTimer = Timer.scheduledTimer(withTimeInterval: rotationInterval, repeats: true) { [weak self] _ in
            self?.rotateToNextBeacon()
        }
    }
    
    private func stopRotation() {
        rotationTimer?.invalidate()
        rotationTimer = nil
        currentRotationIndex = 0
    }
    
    private func rotateToNextBeacon() {
        guard !beaconDataStore.isEmpty else { return }
        
        let beaconIds = Array(beaconDataStore.keys)
        
        // Get the beacon at current index
        if currentRotationIndex >= beaconIds.count {
            currentRotationIndex = 0
        }
        
        let beaconId = beaconIds[currentRotationIndex]
        
        if let beaconData = beaconDataStore[beaconId] {
            broadcastBeacon(beaconData)
            currentBroadcastingBeaconId = beaconId
        }
        
        // Move to next beacon
        currentRotationIndex += 1
        if currentRotationIndex >= beaconIds.count {
            currentRotationIndex = 0
        }
        
        updateStatus()
    }
    
    private func broadcastBeacon(_ beacon: BeaconData) {
        guard let manager = peripheralManager, manager.state == .poweredOn else { return }
        
        // Stop current advertising
        manager.stopAdvertising()
        
        // Create and start new advertisement
        let advertisementData = createBeaconAdvertisementData(
            uuid: beacon.uuid,
            major: beacon.major,
            minor: beacon.minor,
            measuredPower: beacon.measuredPower
        )
        
        manager.startAdvertising(advertisementData)
    }
    
    private func updateStatus() {
        let count = beaconDataStore.count
        
        if count > 0 {
            isAdvertising = true
            if count == 1 {
                statusMessage = "Broadcasting 1 beacon"
            } else {
                statusMessage = "Rotating \(count) beacons (\(Int(rotationInterval))s each)"
            }
        } else {
            isAdvertising = false
            statusMessage = "Ready"
        }
    }
    
    /// Creates the advertisement data for iBeacon format
    private func createBeaconAdvertisementData(
        uuid: UUID,
        major: UInt16,
        minor: UInt16,
        measuredPower: Int8
    ) -> [String: Data] {
        
        let beaconKey = "kCBAdvDataAppleBeaconKey"
        
        // Create 21-byte iBeacon advertisement data
        var advBytes = [UInt8](repeating: 0, count: 21)
        
        // Bytes 0-15: Proximity UUID
        let uuidBytes = withUnsafeBytes(of: uuid.uuid) { Array($0) }
        for i in 0..<16 {
            advBytes[i] = uuidBytes[i]
        }
        
        // Bytes 16-17: Major (big-endian)
        advBytes[16] = UInt8((major >> 8) & 0xFF)
        advBytes[17] = UInt8(major & 0xFF)
        
        // Bytes 18-19: Minor (big-endian)
        advBytes[18] = UInt8((minor >> 8) & 0xFF)
        advBytes[19] = UInt8(minor & 0xFF)
        
        // Byte 20: Measured Power
        advBytes[20] = UInt8(bitPattern: measuredPower)
        
        let advData = Data(advBytes)
        
        return [beaconKey: advData]
    }
}

// MARK: - CBPeripheralManagerDelegate
extension BeaconBroadcaster: CBPeripheralManagerDelegate {
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        bluetoothState = peripheral.state
        
        switch peripheral.state {
        case .poweredOff:
            statusMessage = "Bluetooth is powered off"
            isAdvertising = false
            stopRotation()
        case .poweredOn:
            // Start rotation if we have beacons
            if !beaconDataStore.isEmpty && rotationTimer == nil {
                startRotation()
            }
            updateStatus()
        case .unauthorized:
            statusMessage = "Bluetooth access is not authorized"
            stopRotation()
        case .unsupported:
            statusMessage = "Bluetooth Low Energy is not supported"
            stopRotation()
        case .resetting:
            statusMessage = "Bluetooth is resetting..."
        case .unknown:
            statusMessage = "Bluetooth state is unknown"
        @unknown default:
            statusMessage = "Unknown Bluetooth state"
        }
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error = error {
            print("Failed to start advertising: \(error.localizedDescription)")
        }
        updateStatus()
    }
}
