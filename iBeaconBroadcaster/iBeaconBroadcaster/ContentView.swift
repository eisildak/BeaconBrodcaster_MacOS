//
//  ContentView.swift
//  iBeaconBroadcaster
//
//  Created on February 9, 2026.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = BroadcasterViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with Logo and App Name
            HStack(spacing: 12) {
                // Try SwiftUI Image directly from Assets
                Image("AppLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .cornerRadius(8)
                
                Text("Beacon Broadcaster Pro Desktop")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Beacon List Section
            List {
                Section(header: Text("Beacons")) {
                    if viewModel.beacons.isEmpty {
                        Text("No beacons added yet")
                            .foregroundColor(.secondary)
                            .italic()
                            .frame(minHeight: 100)
                    } else {
                        ForEach(viewModel.beacons) { beacon in
                            BeaconRow(beacon: beacon, viewModel: viewModel)
                        }
                        .onDelete { indexSet in
                            indexSet.forEach { index in
                                viewModel.removeBeacon(viewModel.beacons[index])
                            }
                        }
                    }
                }
            }
            .frame(minHeight: 250)
            
            Divider()
            
            // Add Beacon Section
            VStack(spacing: 12) {
                Text("Add New Beacon")
                    .font(.headline)
                    .padding(.top, 16)
                
                Form {
                    // Beacon Name
                    TextField("Beacon Name", text: $viewModel.beaconName)
                        .textFieldStyle(.roundedBorder)
                    
                    // UUID Section
                    HStack {
                        TextField("UUID", text: $viewModel.uuidString)
                            .textFieldStyle(.roundedBorder)
                        
                        Button(action: viewModel.generateNewUUID) {
                            Image(systemName: "arrow.clockwise")
                        }
                        .help("Generate new UUID")
                        
                        Button(action: viewModel.copyUUIDToClipboard) {
                            Image(systemName: "doc.on.doc")
                        }
                        .help("Copy UUID to clipboard")
                    }
                    
                    // Major Value
                    TextField(
                        "Major (0-65535)",
                        value: $viewModel.major,
                        formatter: viewModel.numberFormatter
                    )
                    .textFieldStyle(.roundedBorder)
                    
                    // Minor Value
                    TextField(
                        "Minor (0-65535)",
                        value: $viewModel.minor,
                        formatter: viewModel.numberFormatter
                    )
                    .textFieldStyle(.roundedBorder)
                    
                    // Measured Power
                    TextField(
                        "Measured Power (-128 to 127)",
                        value: $viewModel.measuredPower,
                        formatter: viewModel.powerFormatter
                    )
                    .textFieldStyle(.roundedBorder)
                    
                    // Add Button
                    Button(action: viewModel.addBeacon) {
                        HStack {
                            Spacer()
                            Image(systemName: "plus.circle.fill")
                            Text("Add Beacon")
                            Spacer()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.canAddBeacon)
                    .controlSize(.large)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .background(Color(NSColor.controlBackgroundColor))
            
            // Status Bar
            HStack {
                Text(viewModel.statusMessage)
                    .foregroundColor(viewModel.isAdvertising ? .green : .secondary)
                    .font(.caption)
                Spacer()
                if viewModel.isAdvertising {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(minWidth: 700, idealWidth: 800, minHeight: 600, idealHeight: 650)
        .overlay(
            ToastView(message: viewModel.toastMessage, isShowing: $viewModel.showToast)
        )
        .onDisappear {
            viewModel.saveSettings()
        }
    }
}

struct ToastView: View {
    let message: String
    @Binding var isShowing: Bool
    
    var body: some View {
        VStack {
            Spacer()
            if isShowing {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.white)
                    Text(message)
                        .foregroundColor(.white)
                        .font(.system(size: 14, weight: .medium))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.orange.opacity(0.95))
                .cornerRadius(10)
                .shadow(radius: 10)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(), value: isShowing)
                .padding(.bottom, 20)
            }
        }
    }
}

struct BeaconRow: View {
    let beacon: Beacon
    let viewModel: BroadcasterViewModel
    
    var isCurrentlyBroadcasting: Bool {
        viewModel.currentBroadcastingBeaconId == beacon.id
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Enable/Disable Toggle
            Toggle("", isOn: Binding(
                get: { beacon.isEnabled },
                set: { _ in viewModel.toggleBeacon(beacon) }
            ))
            .toggleStyle(.switch)
            .labelsHidden()
            .disabled(!viewModel.canEnableBeacon(beacon))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(beacon.name)
                    .font(.headline)
                
                Text("UUID: \(beacon.uuidString)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 16) {
                    Text("Major: \(beacon.major)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Minor: \(beacon.minor)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Power: \(beacon.measuredPower)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Status Indicator
            if beacon.isEnabled {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                    Text("Broadcasting")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            // Delete Button
            Button(action: {
                viewModel.removeBeacon(beacon)
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
            .help("Delete beacon")
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }
}

#Preview {
    ContentView()
}

