//
//  iBeaconBroadcasterApp.swift
//  iBeaconBroadcaster
//
//  Created on February 9, 2026.
//

import AppKit
import SwiftUI

@main
struct iBeaconBroadcasterApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    NSWindow.allowsAutomaticWindowTabbing = false
                }
        }.commands {
            CommandGroup(replacing: CommandGroupPlacement.newItem, addition: {})
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        return true
    }
}
