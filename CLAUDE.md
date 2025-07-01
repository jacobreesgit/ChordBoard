# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ChordBoard is an iOS application built with SwiftUI, targeting iOS 26.0. This is a basic iOS app with a minimal starter template structure.

## Development Commands

### Building
- **Build for iOS Simulator**: `xcodebuild -project ChordBoard.xcodeproj -scheme ChordBoard -destination 'platform=iOS Simulator,name=iPhone 16' build`
- **Build for iOS Device**: `xcodebuild -project ChordBoard.xcodeproj -scheme ChordBoard -destination generic/platform=iOS build`
- **Build for macOS (via Mac Catalyst)**: Not currently supported

### Running and Testing
- **Run on Simulator**: Build first, then use Xcode Simulator tools or `xcrun simctl`
- **Install on Device**: Requires proper code signing and provisioning profiles

### Project Management
- **Clean Build**: `xcodebuild -project ChordBoard.xcodeproj -scheme ChordBoard clean`
- **Show Build Settings**: `xcodebuild -project ChordBoard.xcodeproj -scheme ChordBoard -showBuildSettings`

## Architecture

### Project Structure
```
ChordBoard/
├── ChordBoard.xcodeproj/          # Xcode project file
└── ChordBoard/                    # Source code directory
    ├── ChordBoardApp.swift        # Main app entry point (@main)
    ├── ContentView.swift          # Primary SwiftUI view
    └── Assets.xcassets/           # App assets (icons, colors, images)
```

### Key Components
- **ChordBoardApp.swift:8**: Main app struct with `@main` attribute, defines the app's entry point and window configuration
- **ContentView.swift:10**: Primary SwiftUI view with basic "Hello, world!" content and system globe icon

### Configuration
- **Bundle Identifier**: `jaba.ChordBoard`
- **Deployment Target**: iOS 26.0
- **Supported Devices**: iPhone and iPad (Universal)
- **Architecture**: ARM64 (modern iOS devices)
- **Swift Version**: 5.0
- **Development Team**: 5RP4WRQ9V2

### Build System
Uses standard Xcode build system with:
- Automatic code signing enabled
- SwiftUI previews enabled
- Debug configuration with symbols and testability enabled
- Asset catalog compilation with automatic app icon and accent color handling