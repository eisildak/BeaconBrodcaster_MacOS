# iBeacon Broadcaster

A native macOS application that turns your Mac into an iBeacon broadcaster.

## Features

- ✅ Broadcast iBeacon signals using Bluetooth Low Energy
- ✅ Customize UUID, Major, Minor, and Measured Power values
- ✅ Simple and intuitive SwiftUI interface
- ✅ Save and restore previous configurations
- ✅ Automatic stop/resume on system sleep/wake
- ✅ Native macOS experience with App Sandbox support

## Requirements

- macOS 13.0 or later
- Bluetooth Low Energy capable Mac
- Xcode 15.0 or later (for building from source)

## Installation

### From Source

1. Clone this repository
2. Open `iBeaconBroadcaster.xcodeproj` in Xcode
3. Select your development team in the project settings
4. Build and run the project

## Usage

1. Launch the app
2. Enter or generate a UUID
3. Set Major and Minor values (0-65535)
4. Adjust Measured Power if needed (-128 to 127)
5. Click "Start Broadcasting" to begin transmitting
6. Use nearby devices with iBeacon detection to verify the signal

## Configuration

- **UUID**: Unique identifier for your beacon (128-bit)
- **Major**: Most significant value for grouping (16-bit unsigned integer, 0-65535)
- **Minor**: Least significant value for identification (16-bit unsigned integer, 0-65535)
- **Measured Power**: Signal strength at 1 meter distance (signed 8-bit integer, default: -59)

## Technical Details

This app uses:
- CoreBluetooth framework for BLE peripheral management
- SwiftUI for the user interface
- App Sandbox with Bluetooth entitlements
- AppStorage for persisting user preferences

## License

MIT License - see LICENSE file for details

## Disclaimer

This is a completely original implementation written from scratch. The concept of iBeacon broadcasting is based on Apple's publicly documented iBeacon specification.

## App Store Distribution

This project is ready for App Store distribution:
- ✅ Uses MIT License (App Store compatible)
- ✅ Implements App Sandbox
- ✅ Includes required Bluetooth usage descriptions
- ✅ No third-party dependencies
- ✅ Original codebase

Before submitting to the App Store:
1. Update the Bundle Identifier in project settings
2. Add your development team
3. Create app icons
4. Add screenshots and app description
5. Configure app pricing and availability

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues.

## Support

For issues and questions, please use the GitHub issue tracker.
