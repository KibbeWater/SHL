# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Always use context7 when I need code generation, setup or configuration steps, or
library/API documentation. This means you should automatically use the Context7 MCP
tools to resolve library id and get library docs without me having to explicitly ask.

## Build Commands

```bash
# Build the app
xcodebuild -project SHL.xcodeproj -scheme SHL -destination 'platform=iOS Simulator,name=iPhone 16' build

# Build for release
xcodebuild -project SHL.xcodeproj -scheme SHL -configuration Release build
```

No test targets are currently configured.

## Architecture Overview

**SwiftUI iOS app** for tracking Swedish Hockey League (SHL) matches with Live Activities, push notifications, and iCloud sync.

### Key Patterns

- **MVVM**: Views in `Views/`, ViewModels in `ViewModels/` (all `@MainActor`, `ObservableObject`)
- **Singletons**: `Settings.shared`, `SHLAPIClient.shared`, `AuthenticationManager.shared`, `KeychainManager.shared`
- **CloudKit sync**: `@CloudStorage` property wrapper syncs user preferences across devices
- **Async/await**: All network calls use modern concurrency

### Project Structure

```
SHL/                          # Main app target
├── Network/
│   ├── API/                  # SHLAPIClient (Moya), SHLAPIService (endpoints)
│   ├── LiveListener/         # SSE for real-time match updates
│   └── Models/               # Codable data models
├── Views/                    # SwiftUI views
├── ViewModels/               # MVVM view models
├── Managers/                 # Auth, push notifications, iCloud sync, navigation
├── Extensions/               # Settings, ActivityUpdater, image processing
└── Security/                 # KeychainManager

SHLWidget/                    # Widget extension
├── SHLWidgetLiveActivity.swift   # Live Activity (Dynamic Island, Lock Screen)
└── SHLWidgetUpcoming.swift       # Upcoming matches widget
```

### Network Layer

- **API Base**: `https://api.lrlnet.se` (configurable via `SHL_BASE_URL` env var)
- **Add endpoint**: Add case to `SHLAPIService.swift`, add method to `SHLAPIClient.swift`
- **Real-time**: SSE streaming via `LiveMatchListener` for live match updates

### Live Activities & Push

- `ActivityUpdater.swift`: Manages Live Activities and push-to-start tokens (iOS 17.2+)
- `PushNotificationManager.swift`: APNS token registration
- Deep linking: `shltracker://open-game?id=<matchId>`

### Authentication Flow

1. Device-based registration via `/auth/register`
2. JWT stored in Keychain (with iCloud sync option)
3. Auto-refresh on app launch or token expiration
4. `iCloudSyncManager` syncs auth state across devices

### State Persistence

- **CloudKit** (`@CloudStorage`): Cross-device synced preferences (teams, notifications)
- **UserDefaults**: Local-only settings
- **Keychain**: Secure token storage
- **App Group**: `group.kibbewater.shl` for widget data sharing

## Key Files

| Purpose | File |
|---------|------|
| App entry | `SHLApp.swift`, `AppDelegate.swift` |
| Navigation | `Root.swift`, `NavigationCoordinator.swift` |
| API client | `SHLAPIClient.swift`, `SHLAPIService.swift` |
| Settings | `Settings.swift` |
| Live Activities | `ActivityUpdater.swift` |
| Auth | `AuthenticationManager.swift`, `KeychainManager.swift` |
| Widget attributes | `SHLWidget/Types/SHLWidgetAttributes.swift` |

## Dependencies (SPM)

- Moya/Alamofire (networking)
- Kingfisher (image caching)
- PostHog (analytics, disabled in DEBUG)
- SVGKit (SVG rendering)
- RxSwift (reactive, used by Moya)
