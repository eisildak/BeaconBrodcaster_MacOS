//
//  ContentView.swift
//  iBeaconBroadcaster
//
//  Created on February 9, 2026.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = BroadcasterViewModel()
    @State private var searchText: String = ""
    @State private var showingAddSheet = false
    @State private var showingInfoSheet = false
    
    var filteredBeacons: [Beacon] {
        let filtered: [Beacon]
        if searchText.isEmpty {
            filtered = viewModel.beacons
        } else {
            filtered = viewModel.beacons.filter { beacon in
                beacon.name.localizedCaseInsensitiveContains(searchText) ||
                beacon.uuidString.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Sort by favorite first, then by reverse order (newest first)
        let favorites = filtered.filter { $0.isFavorite }.reversed()
        let nonFavorites = filtered.filter { !$0.isFavorite }.reversed()
        
        return Array(favorites) + Array(nonFavorites)
    }
    
    var body: some View {
        HSplitView {
            // SIDEBAR
            VStack(spacing: 0) {
                // Sidebar Header
                HStack(spacing: 12) {
                    Image("AppLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                        .cornerRadius(8)
                    
                    Text("Beacon Broadcaster Pro")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                
                Divider()
                
                // Toolbar with action buttons
                HStack(spacing: 12) {
                    Button(action: { showingInfoSheet = true }) {
                        Image(systemName: "info.circle")
                            .imageScale(.large)
                    }
                    .buttonStyle(.plain)
                    .help("Info")
                    
                    Button(action: {
                        // Stop all enabled beacons
                        for beacon in viewModel.beacons where beacon.isEnabled {
                            viewModel.toggleBeacon(beacon)
                        }
                    }) {
                        Text("Stop All")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.red)
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .help("Stop all broadcasting beacons")
                    .disabled(viewModel.beacons.filter { $0.isEnabled }.isEmpty)
                    
                    Button(action: { showingAddSheet = true }) {
                        Text("Add Beacon")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue)
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .help("Add Beacon")
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                
                Divider()
                
                // Beacons Section Header
                Text("Beacons")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search beacons...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
                
                // Beacons List
                ScrollView {
                    LazyVStack(spacing: 0) {
                        if filteredBeacons.isEmpty {
                            Text(searchText.isEmpty ? "No beacons added yet" : "No beacons found")
                                .foregroundColor(.secondary)
                                .italic()
                                .padding(.top, 40)
                        } else {
                            ForEach(filteredBeacons) { beacon in
                                SidebarBeaconRow(
                                    beacon: beacon,
                                    viewModel: viewModel
                                )
                                Divider()
                                    .padding(.leading, 12)
                            }
                        }
                    }
                }
                
                // Footer with copyright
                VStack {
                    Divider()
                    Text("© 2026")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                }
            }
            .frame(minWidth: 280, idealWidth: 320, maxWidth: 400)
            .background(Color(NSColor.controlBackgroundColor))
            
            // MAIN CONTENT AREA
            VStack(spacing: 0) {
                Spacer()
                
                // Broadcast Button
                VStack(spacing: 16) {
                    Button(action: {
                        if viewModel.isAdvertising {
                            // Stop all broadcasting
                            for beacon in viewModel.beacons where beacon.isEnabled {
                                viewModel.toggleBeacon(beacon)
                            }
                        }
                    }) {
                        Text("Broadcast")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(width: 140, height: 40)
                            .background(viewModel.isAdvertising ? Color.red : Color.blue)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.beacons.filter { $0.isEnabled }.isEmpty)
                    
                    if viewModel.isAdvertising {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                            Text("Broadcasting \(viewModel.beacons.filter { $0.isEnabled }.count) beacon(s)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Status bar at bottom
                HStack {
                    Text(viewModel.statusMessage)
                        .foregroundColor(viewModel.isAdvertising ? .green : .secondary)
                        .font(.caption)
                    Spacer()
                    if viewModel.isAdvertising {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                            Text("Active")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
            }
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(minWidth: 800, idealWidth: 1000, minHeight: 600, idealHeight: 700)
        .overlay(
            ToastView(message: viewModel.toastMessage, isShowing: $viewModel.showToast)
        )
        .onDisappear {
            viewModel.saveSettings()
        }
        .sheet(isPresented: $showingAddSheet) {
            AddBeaconSheet(viewModel: viewModel, isPresented: $showingAddSheet)
        }
        .sheet(isPresented: $showingInfoSheet) {
            InfoSheet(isPresented: $showingInfoSheet)
        }
    }
}

// MARK: - Sidebar Beacon Row
struct SidebarBeaconRow: View {
    let beacon: Beacon
    let viewModel: BroadcasterViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Star Button
            Button(action: {
                viewModel.toggleFavorite(beacon)
            }) {
                Image(systemName: beacon.isFavorite ? "star.fill" : "star")
                    .foregroundColor(beacon.isFavorite ? .yellow : .gray)
                    .imageScale(.medium)
            }
            .buttonStyle(.plain)
            .help(beacon.isFavorite ? "Remove from favorites" : "Add to favorites")
            
            VStack(alignment: .leading, spacing: 4) {
                Text(beacon.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                
                Text("UUID: \(beacon.uuidString.prefix(18))...")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    Text("Major: \(beacon.major)")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Text("Minor: \(beacon.minor)")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Toggle Switch
            Toggle("", isOn: Binding(
                get: { beacon.isEnabled },
                set: { _ in viewModel.toggleBeacon(beacon) }
            ))
            .toggleStyle(.switch)
            .labelsHidden()
            
            // Delete Button
            Button(action: {
                viewModel.removeBeacon(beacon)
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .imageScale(.medium)
            }
            .buttonStyle(.plain)
            .help("Delete beacon")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}

// MARK: - Add Beacon Sheet
struct AddBeaconSheet: View {
    @ObservedObject var viewModel: BroadcasterViewModel
    @Binding var isPresented: Bool
    
    @State private var beaconName: String = ""
    @State private var uuidString: String = UUID().uuidString
    @State private var major: UInt16 = 1
    @State private var minor: UInt16 = 1
    @State private var measuredPower: Int8 = -59
    
    var canAdd: Bool {
        UUID(uuidString: uuidString) != nil
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Add New Beacon")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top, 20)
            
            Form {
                // Beacon Name
                TextField("Beacon Name", text: $beaconName)
                    .textFieldStyle(.roundedBorder)
                
                // UUID Section
                HStack {
                    TextField("UUID", text: $uuidString)
                        .textFieldStyle(.roundedBorder)
                    
                    Button(action: {
                        uuidString = UUID().uuidString
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .help("Generate new UUID")
                    
                    Button(action: {
                        let pasteboard = NSPasteboard.general
                        pasteboard.clearContents()
                        pasteboard.setString(uuidString, forType: .string)
                    }) {
                        Image(systemName: "doc.on.doc")
                    }
                    .help("Copy UUID to clipboard")
                }
                
                // Major Value
                TextField(
                    "Major (0-65535)",
                    value: $major,
                    formatter: viewModel.numberFormatter
                )
                .textFieldStyle(.roundedBorder)
                
                // Minor Value
                TextField(
                    "Minor (0-65535)",
                    value: $minor,
                    formatter: viewModel.numberFormatter
                )
                .textFieldStyle(.roundedBorder)
                
                // Measured Power
                TextField(
                    "Measured Power (-128 to 127)",
                    value: $measuredPower,
                    formatter: viewModel.powerFormatter
                )
                .textFieldStyle(.roundedBorder)
            }
            .padding(.horizontal, 20)
            
            // Buttons
            HStack(spacing: 12) {
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Add Beacon") {
                    addBeacon()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!canAdd)
            }
            .padding(.bottom, 20)
        }
        .frame(width: 500, height: 400)
    }
    
    private func addBeacon() {
        guard let uuid = UUID(uuidString: uuidString) else {
            return
        }
        
        let newBeacon = Beacon(
            name: beaconName.isEmpty ? "Beacon \(viewModel.beacons.count + 1)" : beaconName,
            uuidString: uuid.uuidString,
            major: major,
            minor: minor,
            measuredPower: measuredPower,
            isEnabled: false
        )
        
        viewModel.beacons.append(newBeacon)
        viewModel.saveSettings()
        isPresented = false
    }
}

// MARK: - Info Sheet
struct InfoSheet: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("About")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 24)
                
                Text("Beacon Broadcaster Pro")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.bottom, 20)
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Broadcasting Section
                    InfoSectionView(
                        title: "Broadcasting",
                        icon: "wifi",
                        iconColor: .blue,
                        backgroundColor: Color.blue.opacity(0.1)
                    ) {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 14))
                            
                            Text("Broadcast multiple beacons simultaneously - only 2 beacons are supported on macOS")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    
                    // Contact Section
                    InfoSectionView(
                        title: "Contact",
                        icon: "envelope.fill",
                        iconColor: .purple,
                        backgroundColor: Color.purple.opacity(0.1)
                    ) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("For feedback and suggestions:")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                            
                            Text("erolisildakk@gmail.com")
                                .font(.system(size: 14))
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
            
            Spacer()
            
            // Done Button
            Button(action: {
                isPresented = false
            }) {
                Text("Done")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .frame(width: 500, height: 450)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Info Section View
struct InfoSectionView<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    let backgroundColor: Color
    let content: Content
    
    init(
        title: String,
        icon: String,
        iconColor: Color,
        backgroundColor: Color,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.backgroundColor = backgroundColor
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 16))
                    .frame(width: 28, height: 28)
                    .background(backgroundColor)
                    .cornerRadius(6)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            content
                .padding(.leading, 36)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Toast View
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

#Preview {
    ContentView()
}

