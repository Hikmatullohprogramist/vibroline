# Vibroline - Flutter Mobile Application

[![Flutter](https://img.shields.io/badge/Flutter-3.32.1-blue.svg)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.8.1-blue.svg)](https://dart.dev/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## 📱 Project Overview

**Vibroline** is a digital wireless system designed for the social rehabilitation of citizens with hearing disabilities. It provides notifications about doorbells, phones, intercoms, baby monitors, and other household signals through a mobile application working with ESP8266 hardware.

### 🎯 MVP Features

- **Wi-Fi Connectivity**: Device works in AP (Access Point) or STA (Client) mode
- **WebSocket Communication**: Real-time communication with ESP8266 device
- **Automatic Mode Detection**: Determines connection mode via API
- **Sensor Detection**: Doorbell, phone, intercom, baby monitor, smoke, gas sensors
- **Push Notifications**: Real-time alerts with source information
- **Wi-Fi Configuration**: Set WiFi credentials via app
- **Russian Language Interface**: All UI elements in Russian

## 🏗️ System Architecture

```
┌─────────────────┐    HTTP Requests    ┌─────────────────┐
│   Flutter App   │ ◄─────────────────► │   ESP8266       │
│   (Android)     │                     │   (Arduino)     │
└─────────────────┘                     └─────────────────┘
         │                                       │
         │                                       │
         ▼                                       ▼
┌─────────────────┐                     ┌─────────────────┐
│   Push          │                     │   Sensors       │
│   Notifications │                     │   (Doorbell,    │
└─────────────────┘                     │    Phone, etc.) │
                                       └─────────────────┘
```

## 🚀 Quick Start

### Prerequisites

- Flutter SDK 3.32.1+
- Dart SDK 3.8.1+
- Android Studio / VS Code
- Arduino IDE (for ESP8266)
- ESP8266 development board

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd vibroline
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the application**
   ```bash
   flutter run
   ```

### Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  http: ^1.4.0
  flutter_local_notifications: ^19.4.0
  permission_handler: ^12.0.1
  tailwind_cli: ^0.7.7
```

## 📁 Project Structure

```
vibroline/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── core/
│   │   ├── network_service.dart  # HTTP communication
│   │   └── notification_service.dart # Push notifications
│   ├── models/
│   │   └── event_model.dart      # Event data model
│   ├── screens/
│   │   ├── home_screen.dart      # Main screen
│   │   └── settings_screen.dart  # Settings (future)
│   ├── widgets/
│   │   ├── event_history_list.dart # Event history widget
│   │   └── status_panel.dart     # Status indicator
│   └── styles/
│       └── tailwind.css          # Tailwind CSS
├── android/                      # Android specific files
├── ios/                         # iOS specific files
├── test/                        # Test files
├── pubspec.yaml                 # Dependencies
├── tailwind.config.js           # Tailwind config
└── package.json                 # Node.js dependencies
```

## 🔧 Core Components

### Network Service
Handles HTTP communication with ESP8266 device.

```dart
class NetworkService {
  Future<String?> fetchEvent(String ip) async {
    try {
      final response = await http.get(Uri.parse('http://$ip/event'));
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        return response.body;
      }
    } catch (_) {}
    return null;
  }
}
```

### Notification Service
Manages push notifications and permissions.

```dart
class NotificationService {
  Future<void> show(String source) async {
    const android = AndroidNotificationDetails(
      'vibroline_channel', 'Vibroline',
      importance: Importance.max, priority: Priority.high,
    );
    await notificationsPlugin.show(0, 'Vibroline', 'Сработал: $source',
        notificationDetails);
  }
}
```

## 🌐 API Documentation

### ESP8266 Endpoints

#### GET /event
Returns current event status from ESP8266

**Response Format**:
```json
{
  "source": "doorbell" | "phone" | "intercom" | "baby" | "unknown"
}
```

**Event Types**:
- `doorbell` - Дверной звонок
- `phone` - Телефон
- `intercom` - Домофон
- `baby` - Детский плач
- `unknown` - Неизвестно

## 🎨 UI/UX Features

### Design Principles
- **Material Design 3** - Modern Android design
- **Russian Language** - All text in Russian
- **Accessibility** - Support for hearing-impaired users
- **Responsive** - Works on different screen sizes

### Color Scheme
```dart
// Primary colors
Colors.blue.shade500  // Primary blue
Colors.blue.shade600  // Hover state
Colors.blue.shade700  // Focus state
Colors.blue.shade800  // Active state

// Status colors
Colors.green          // Connected
Colors.red            // Error/Disconnected
Colors.orange         // Warning
```

## 🧪 Testing

### Run Tests
```bash
# Unit tests
flutter test

# Widget tests
flutter test test/widget_test.dart

# Integration tests
flutter test test/integration_test.dart
```

### Test Coverage
```bash
# Generate coverage report
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

## 🚀 Deployment

### Android Build
```bash
# Build APK
flutter build apk --release

# Build App Bundle
flutter build appbundle --release
```

### Release Checklist
- [ ] Update version in `pubspec.yaml`
- [ ] Test on real device
- [ ] Update app icon and metadata
- [ ] Configure signing keys
- [ ] Upload to Google Play Console

## 🔌 ESP8266 Integration

### Hardware Requirements
- ESP8266 development board
- Sensors (doorbell, phone, intercom, baby monitor)
- Power supply
- Wi-Fi antenna

### Arduino Code Example
```cpp
#include <ESP8266WiFi.h>
#include <ESP8266WebServer.h>

const char* ssid = "YourWiFiSSID";
const char* password = "YourWiFiPassword";

ESP8266WebServer server(80);

void setup() {
  // Initialize sensors
  // Connect to Wi-Fi
  // Start web server
}

void loop() {
  // Check sensors
  // Handle HTTP requests
}
```

## 🔧 Troubleshooting

### Common Issues

#### Network Connection Issues
**Problem**: App can't connect to ESP8266
**Solution**:
- Check IP address is correct
- Verify ESP8266 is powered on
- Check Wi-Fi connection
- Test with ping command

#### Notification Permissions
**Problem**: Notifications not showing
**Solution**:
- Check Android notification settings
- Verify permission_handler is working
- Test on real device (not emulator)

### Debug Commands
```bash
# Check Flutter version
flutter --version

# Clean and rebuild
flutter clean
flutter pub get
flutter run

# Check device connection
adb devices

# View logs
flutter logs
```

## 🔮 Future Enhancements

### Phase 2 Features
- [ ] **Settings Screen**: User preferences, polling interval
- [ ] **Wi-Fi Auto-Discovery**: Automatic ESP8266 detection
- [ ] **Data Persistence**: Local storage for event history
- [ ] **Advanced Notifications**: Custom sounds, vibration patterns

### Phase 3 Features
- [ ] **Cloud Integration**: Remote monitoring and alerts
- [ ] **Multi-Device Support**: Multiple ESP8266 devices
- [ ] **Analytics**: Usage statistics and patterns
- [ ] **Voice Commands**: Voice control for app functions

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📞 Support

### Development Team
- **Lead Developer**: [Your Name]
- **UI/UX Designer**: [Designer Name]
- **Hardware Engineer**: [Hardware Engineer Name]

### Contact
- **Email**: [your.email@example.com]
- **GitHub Issues**: [GitHub Issues URL]
- **Documentation**: [Wiki URL]

## 📊 Project Status

- [x] **MVP Development** - Core functionality implemented
- [x] **UI/UX Design** - Material Design 3 interface
- [x] **Testing Framework** - Unit and widget tests
- [ ] **ESP8266 Integration** - Hardware implementation
- [ ] **Production Deployment** - App store release
- [ ] **Advanced Features** - Phase 2 & 3 features

---

**📝 Note**: This is a living document. For the most current information, always refer to the latest version in the repository.

**⭐ Star this repository if you find it helpful!**
