//
//  BeaconModel.swift
//  iBeaconBroadcaster
//
//  Created on February 9, 2026.
//

import Foundation

struct Beacon: Identifiable, Codable {
    let id: UUID
    var name: String
    var uuidString: String
    var major: UInt16
    var minor: UInt16
    var measuredPower: Int8
    var isEnabled: Bool
    var isFavorite: Bool
    
    init(
        id: UUID = UUID(),
        name: String = "New Beacon",
        uuidString: String = UUID().uuidString,
        major: UInt16 = 1,
        minor: UInt16 = 1,
        measuredPower: Int8 = -59,
        isEnabled: Bool = true,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.name = name
        self.uuidString = uuidString
        self.major = major
        self.minor = minor
        self.measuredPower = measuredPower
        self.isEnabled = isEnabled
        self.isFavorite = isFavorite
    }
    
    var beaconUUID: UUID? {
        UUID(uuidString: uuidString)
    }
}
