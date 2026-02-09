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
        Form {
            // UUID Section
            HStack {
                TextField("UUID", text: $viewModel.uuidString)
                    .textFieldStyle(.roundedBorder)
                    .disabled(viewModel.isAdvertising)
                    .onSubmit { }
                
                Button(action: viewModel.generateNewUUID) {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.isAdvertising)
                .help("Generate new UUID")
                
                Button(action: viewModel.copyUUIDToClipboard) {
                    Image(systemName: "doc.on.doc")
                }
                .disabled(viewModel.isAdvertising)
                .help("Copy UUID to clipboard")
            }
            
            // Major Value
            TextField(
                "Major (0-65535)",
                value: $viewModel.major,
                formatter: viewModel.numberFormatter
            )
            .textFieldStyle(.roundedBorder)
            .disabled(viewModel.isAdvertising)
            .onSubmit { }
            
            // Minor Value
            TextField(
                "Minor (0-65535)",
                value: $viewModel.minor,
                formatter: viewModel.numberFormatter
            )
            .textFieldStyle(.roundedBorder)
            .disabled(viewModel.isAdvertising)
            .onSubmit { }
            
            // Measured Power
            TextField(
                "Measured Power (-128 to 127)",
                value: $viewModel.measuredPower,
                formatter: viewModel.powerFormatter
            )
            .textFieldStyle(.roundedBorder)
            .disabled(viewModel.isAdvertising)
            .onSubmit { }
            
            // Status Message
            Text(viewModel.statusMessage)
                .foregroundColor(viewModel.isAdvertising ? .green : .secondary)
                .font(.caption)
            
            // Toggle Button
            Button(action: viewModel.toggleBroadcasting) {
                HStack {
                    Spacer()
                    Image(systemName: viewModel.isAdvertising ? "stop.circle.fill" : "play.circle.fill")
                    Text(viewModel.isAdvertising ? "Stop Broadcasting" : "Start Broadcasting")
                    Spacer()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.canStartBroadcasting && !viewModel.isAdvertising)
            .controlSize(.large)
        }
        .padding()
        .frame(minWidth: 400, minHeight: 280)
        .onDisappear {
            viewModel.saveSettings()
        }
    }
}

#Preview {
    ContentView()
}
