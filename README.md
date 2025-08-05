# Vibroline - Flutter Mobile Application

[![Flutter](https://img.shields.io/badge/Flutter-3.32.1-blue.svg)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.8.1-blue.svg)](https://dart.dev/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## 📱 Project Overview

**Vibroline** is a digital wireless system designed for the social rehabilitation of citizens with hearing disabilities. It provides notifications about doorbells, phones, intercoms, baby monitors, and other household signals through a mobile application working with ESP8266 hardware.

### 🎯 Key Features

- **Dual Mode Operation**: AP (Access Point) and STA (Station) modes
- **Wi-Fi Connectivity**: Automatic mode detection and connection
- **WebSocket Communication**: Real-time communication with ESP8266 device
- **Sensor Detection**: Doorbell, phone, intercom, baby monitor, smoke, gas sensors
- **Push Notifications**: Real-time alerts with source information
- **Wi-Fi Configuration**: Set WiFi credentials via app
- **Russian Language Interface**: All sUI elements in Russian

## 🏗️ System Architecture

```
┌─────────────────┐    HTTP/WebSocket    ┌─────────────────┐
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
  web_socket_channel: ^2.4.0
```

## 📁 Project Structure

```
vibroline/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── core/
│   │   ├── connection_service.dart      # Connection mode detection
│   │   ├── auto_connection_service.dart # Auto connection management
│   │   ├── notification_service.dart    # Push notifications
│   │   └── websocket_service.dart      # WebSocket communication
│   ├── models/
│   │   └── device_message.dart         # Device message model
│   ├── screens/
│   │   └── auto_home_screen.dart       # Main screen
│   └── widgets/                        # UI components
├── android/                      # Android specific files
├── ios/                         # iOS specific files
├── test/                        # Test files
├── pubspec.yaml                 # Dependencies
└── TECHNICAL_SPECIFICATION.md   # Technical specification
```

## 🔧 Core Components

### Connection Service
Handles connection mode detection and device information.

```dart
class ConnectionService {
  // Determine connection mode (AP vs STA)
  Future<String?> determineConnectionMode() async
  
  // Get device information from API
  Future<Map<String, dynamic>?> getDeviceInfo() async
  
  // Test device connectivity
  Future<bool> testConnection(String ip) async
}
```

### Auto Connection Service
Manages automatic connection and WebSocket communication.

```dart
class AutoConnectionService {
  // Initialize connection
  Future<void> initialize() async
  
  // Send commands to device
  void sendCommand(Map<String, dynamic> command)
  
  // Set WiFi credentials
  void setWiFi(String ssid, String password)
}
```

### Device Message Model
Handles device message parsing and formatting.

```dart
class DeviceMessage {
  final String? mac;
  final int? rssi;
  final Map<String, int>? gpio;
  final Map<String, int>? alarm;
  final Map<String, int>? batteryLow;
}
```

## 🌐 API Documentation

### Connection Mode Detection

#### GET https://www.kbkontur.ru/iot/get.php
Returns device information for STA mode detection.

**Response Format**:
```json
{
  "local_ip": "192.168.31.18",
  "mac": "44:17:93:10:F9:A3",
  "global_ip": "78.84.84.235"
}
```

### ESP8266 Endpoints

#### GET /status
Device availability check.

**Response**:
```json
{
  "status": "ok"
}
```

#### GET /wifi
WiFi information.

**Response**:
```json
{
  "ssid": "WiFiName",
  "rssi": -65,
  "ip": "192.168.1.100",
  "gateway": "192.168.1.1"
}
```

#### WebSocket /ws
Real-time data exchange.

**Connection URLs**:
- STA mode: `ws://<local_ip>/ws`
- AP mode: `ws://192.168.4.1/ws`

### WebSocket Message Format

#### Device to App Messages

**Initial connection**:
```json
{
  "mac": "44:17:93:10:F9:A3",
  "rssi": 0,
  "gpio": {
    "GPIO1": 1,
    "GPIO2": 1
  }
}
```

**GPIO changes**:
```json
{
  "gpio": {
    "GPIO1": 0
  }
}
```

**Alarm events**:
```json
{
  "alarm": {
    "doorbell": 1
  }
}
```

**Battery low warnings**:
```json
{
  "batterylow": {
    "doorbell": 0
  }
}
```

#### App to Device Commands

**WiFi configuration**:
```json
{
  "cmd": "setwifi",
  "ssid": "WiFiName",
  "pass": "password"
}
```

**Mode switching**:
```json
{
  "cmd": "switch_to_ap"
}
```

### Sensor Types

- `doorbell` - Дверной звонок
- `intercom` - Домофон
- `phone` - Телефон
- `babycry` - Плач ребёнка
- `test` - Тестирование системы
- `smoke` - Датчик дыма
- `gas` - Датчик утечки бытового газа

## 🎨 UI/UX Features

### Design Principles
- **Material Design 3** - Modern Android design
- **Russian Language** - All text in Russian
- **Accessibility** - Support for hearing-impaired users
- **Responsive** - Works on different screen sizes

### Main Screen Features
- **Connection Status** - Shows current mode and IP
- **WiFi Information** - Network name and signal strength
- **Message History** - All device events
- **Control Buttons** - Reconnect, WiFi settings

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
#include <WebSocketsServer.h>

const char* ap_ssid = "VibroLine";
const char* ap_password = "12345678";

ESP8266WebServer server(80);
WebSocketsServer webSocket = WebSocketsServer(81);

void setup() {
  // Initialize sensors
  // Setup WiFi modes
  // Start web server and WebSocket
}

void loop() {
  // Check sensors
  // Handle WebSocket events
  // Send notifications
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
- [x] **ESP8266 Integration** - Hardware implementation
- [x] **Dual Mode Support** - AP and STA modes
- [x] **WiFi Information Display** - Network details
- [ ] **Production Deployment** - App store release
- [ ] **Advanced Features** - Phase 2 & 3 features

---

**📝 Note**: This is a living document. For the most current information, always refer to the latest version in the repository.

**⭐ Star this repository if you find it helpful!**
