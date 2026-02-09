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
    
    // MARK: - Private Properties
    private var peripheralManager: CBPeripheralManager?
    private var currentBeaconData: [String: Data]?
    
    // MARK: - Initialization
    override init() {
        super.init()
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    // MARK: - Public Methods
    
    /// Start broadcasting iBeacon with specified parameters
    func startBroadcasting(uuid: UUID, major: UInt16, minor: UInt16, measuredPower: Int8) {
        guard let manager = peripheralManager,
              manager.state == .poweredOn else {
            statusMessage = "Bluetooth is not ready"
            return
        }
        
        let beaconData = createBeaconAdvertisementData(
            uuid: uuid,
            major: major,
            minor: minor,
            measuredPower: measuredPower
        )
        
        currentBeaconData = beaconData
        manager.startAdvertising(beaconData)
        statusMessage = "Broadcasting started"
    }
    
    /// Stop broadcasting
    func stopBroadcasting() {
        peripheralManager?.stopAdvertising()
        currentBeaconData = nil
        isAdvertising = false
        statusMessage = "Broadcasting stopped"
    }
    
    // MARK: - Private Methods
    
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
        case .poweredOn:
            statusMessage = "Bluetooth is ready"
        case .unauthorized:
            statusMessage = "Bluetooth access is not authorized"
        case .unsupported:
            statusMessage = "Bluetooth Low Energy is not supported"
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
            statusMessage = "Failed to start: \(error.localizedDescription)"
            isAdvertising = false
        } else {
            isAdvertising = true
            statusMessage = "Broadcasting iBeacon signal"
        }
    }
}
