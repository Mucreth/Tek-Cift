# Handclash - Development Guide

## 📁 Project Structure

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_constants.dart     # App-wide constants
│   │   ├── asset_constants.dart   # Asset paths
│   │   └── route_constants.dart   # Navigation routes
│   ├── config/
│   │   ├── env_config.dart       # Environment URLs
│   │   ├── secrets.dart          # API keys (gitignored)
│   │   ├── api_config.dart       # API settings
│   │   └── secrets.dart.example  # Template for secrets
│   ├── sound/
│   │   ├── sound_manager.dart    # Sound management
│   │   ├── sound_types.dart      # Sound enums and types
│   │   └── assets/              # Sound files
│   │       ├── ui/              
│   │       └── game/            
│   ├── haptic/
│   │   ├── haptic_manager.dart   # Haptic feedback management
│   │   └── haptic_types.dart     # Haptic types and enums
│   ├── init/
│   │   ├── navigation_service.dart
│   │   ├── network_manager.dart
│   │   └── socket_manager.dart
│   ├── base/
│   │   ├── base_view.dart
│   │   └── base_viewmodel.dart
│   └── utils/
│       ├── helpers.dart
│       └── extensions.dart
├── features/
│   ├── auth/
│   │   ├── view/
│   │   ├── viewmodel/
│   │   └── service/
│   ├── game/
│   │   ├── view/
│   │   ├── viewmodel/
│   │   └── service/
│   ├── profile/
│   │   └── ...
│   └── store/
│       └── ...
└── shared/
    ├── widgets/
    ├── models/
    └── services/
```

## 🔒 Environment & Config Management

### Config Files Structure
```
lib/core/config/
├── env_config.dart       # Environment URLs and settings
├── secrets.dart          # API keys (gitignored)
├── api_config.dart       # API configuration
└── secrets.dart.example  # Template for secrets
```

## 🔊 Sound & Haptic Feedback System

### Sound Structure
```
lib/core/sound/
├── sound_manager.dart    # Central sound management
├── sound_types.dart      # Sound types and enums
└── assets/              # Sound files (.mp3)
    ├── ui/              # UI sounds
    │   ├── button.mp3
    │   └── error.mp3
    └── game/            # Game sounds
        ├── card_flip.mp3
        ├── card_select.mp3
        ├── win.mp3
        ├── lose.mp3
        └── draw.mp3
```

### Haptic Feedback Types
- Light Impact (Selection)
- Medium Impact (Card Flip)
- Heavy Impact (Win/Lose)

### Sound & Haptic Events
- Button Press: Light haptic + click sound
- Card Selection: Light haptic + selection sound
- Card Flip: Medium haptic + flip sound
- Game Result: Heavy haptic + result sound
- Settings menu for sound/haptic controls

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  provider: ^6.0.0
  
  # Network
  dio: ^5.0.0
  socket_io_client: ^2.0.0
  
  # Local Storage
  shared_preferences: ^2.0.0
  hive: ^2.0.0
  
  # Utils
  easy_localization: ^3.0.0
  logger: ^1.0.0
  
  # UI
  flutter_screenutil: ^5.0.0
  cached_network_image: ^3.0.0
  
  # Auth
  sign_in_with_apple: ^4.0.0
  device_info_plus: ^8.0.0

  # Sound & Haptic
  audioplayers: ^5.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.6
  flutter_lints: ^2.0.0
```

## 🏗 Architecture

### MVVM Pattern Structure
- View: UI components
- ViewModel: Business logic and state management
- Model: Data structures and repositories
- Services: API calls and device operations

## 🌐 Network Layer

### Components
- Network Manager: Central HTTP request management
- Socket Manager: Real-time game communication
- API Services: Feature-specific API calls
- Error Handling: Centralized error management

## 📊 Performance Guidelines

### Widget Optimization
- Use const constructors
- Implement shouldRebuild
- Use RepaintBoundary for animations
- Cache images and computations

### Memory Management
- Dispose controllers and animations
- Clean up socket listeners
- Use weak references
- Monitor memory usage

## 🚀 Build & Release Process

### Build Types
- Debug: `flutter build apk --debug`
- Release: `flutter build apk --release`
- Custom: `flutter build apk --dart-define=API_URL=https://api.handclash.com`

## 📋 Code Style Guidelines

### Naming Conventions
- camelCase: variables, functions
- PascalCase: classes, enums
- snake_case: files, folders

### File Organization
- Max 300 lines per file
- Clear documentation for public APIs
- Follow Flutter style guide

## 🔄 Git Workflow

### Development Process
1. Feature branch from development
2. Development and testing
3. Pull request
4. Code review
5. Merge to development
6. Staging deployment
7. Production merge

## 🐛 Debugging Guidelines

### Tools
- Flutter DevTools
- Network logging
- Logger package
- Error tracking

## 📚 Resources & Links

### Official Documentation
- [Flutter Docs](https://flutter.dev/docs)
- [Dart Docs](https://dart.dev/guides)
- [Provider Package](https://pub.dev/packages/provider)
- [Socket.io Client](https://pub.dev/packages/socket_io_client)