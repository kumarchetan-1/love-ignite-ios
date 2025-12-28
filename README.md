# Love Ignite

Love Ignite is a beautifully designed romantic challenge app for couples, built with SwiftUI. It features a collection of intimate and fun challenges categorized by difficulty and type, allowing couples to spark excitement and track their journey together.

## 📱 Features

- **Interactive Challenges**: Scratch-off interface to reveal challenges.
- **Categorized Content**: Tasks ranging from "General" to "Extra Hot" and "Techniques".
- **Difficulty Levels**: From Easy to Extreme, catering to all comfort levels.
- **Progress Tracking**: Achievement system and cloud synchronization.
- **Modern UI**: Neon-themed interface with customizable themes and haptic feedback.
- **In-App Purchases**: Premium content unlocking via StoreKit.

## 🛠 Tech Stack

- **Language**: Swift
- **Framework**: SwiftUI
- **Architecture**: MVVM
- **Backend Service**: Custom Node.js API (see `loveIgnite-backend`)
- **Persistence**: UserDefaults & Backend Cloud Sync
- **Feedback**: CoreHaptics

## 📁 Project Structure

```text
love-ignite/
├── App/                # App entry point and global state
├── Views/              # SwiftUI views organized by feature
├── ViewModels/         # Logic and data transformation
├── Models/             # Data structures and enums
├── Services/           # API, Storage, and StoreKit managers
├── Utils/              # Helpers, UI extensions, and styles
└── Assets.xcassets/    # App icons, colors, and SVG challenge images
```

## 🚀 Getting Started

### Prerequisites

- Mac with **Xcode 15+** installed.
- iOS 17.0+ (minimum target).

### Setup

1. Open `love-ignite.xcodeproj` in Xcode.
2. Select your target device or simulator.
3. Build and Run (**Cmd + R**).

> **Note**: To use cloud sync features, ensure the [Backend Service](./loveIgnite-backend) is running and the `baseURL` in `BackendService.swift` is correctly configured.

## 🔗 Related Projects

- [Love Ignite Backend](./loveIgnite-backend) - The Node.js API that powers cloud sync and user accounts.

