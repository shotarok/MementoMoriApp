# Memento Mori Widget

A SwiftUI iOS app and widget that displays your life as a visual grid — in weeks, months, or years. A daily reminder to live intentionally.

## Features

- **Main App**: Configure your birthdate and life expectancy, preview the calendar in weeks, months, or years
- **Widgets**: Small, Medium, and Large home screen widgets plus Lock Screen widgets
- **Shared Data**: App and widgets share data via App Groups
- **Light/Dark App Icon**: Hourglass icon that adapts to system appearance

## Project Structure

```
MementoMoriWidget/
├── MementoMori.xcodeproj/
└── MementoMori/
    ├── MementoMoriApp.swift          # App entry point
    ├── ContentView.swift              # Main app UI with settings
    ├── LifeData.swift                 # Shared data model (used by app + widget)
    ├── Assets.xcassets/               # App icons (light/dark) and colors
    ├── MementoMori.entitlements
    └── MementoMoriWidget/
        ├── MementoMoriWidgetBundle.swift  # Widget entry point
        ├── MementoMoriWidget.swift        # Widget views for all sizes
        ├── Info.plist                     # Widget extension config
        ├── Assets.xcassets/
        └── MementoMoriWidgetExtension.entitlements
```

## Setup Instructions

### 1. Open in Xcode
Open `MementoMori.xcodeproj` in Xcode 15+.

### 2. Configure Bundle Identifiers
Update the bundle identifiers to match your Apple Developer account:
- Main app: `com.YOURNAME.mementomori`
- Widget: `com.YOURNAME.mementomori.widget`

### 3. Configure App Group
1. In Xcode, select the **MementoMori** target
2. Go to **Signing & Capabilities**
3. Update the App Group to `group.com.YOURNAME.mementomori`
4. Repeat for the **MementoMoriWidgetExtension** target

Also update `LifeDataStore.appGroupIdentifier` in `LifeData.swift`:
```swift
static let appGroupIdentifier = "group.com.YOURNAME.mementomori"
```

### 4. Add Development Team
Select your development team for both targets in Signing & Capabilities.

### 5. Build and Run
- Select an iOS 17+ simulator or device
- Build and run the app
- Long-press on home screen → Add Widget → Find "Memento Mori"

## Widget Sizes

| Size | Display | Description |
|------|---------|-------------|
| Small | Years grid (10x9) | Quick glance at life in years |
| Medium | Weeks grid grouped by decade + stats | Percentage lived, weeks lived/remaining |
| Large | Full weeks grid (52 columns) | Complete life calendar in weeks |
| Lock Screen (Circular) | Gauge | Percentage of life as ring |
| Lock Screen (Rectangular) | Progress bar | Weeks remaining |
| Lock Screen (Inline) | Text | "⏳ X weeks left" |

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## License

MIT License - Feel free to use and modify.
