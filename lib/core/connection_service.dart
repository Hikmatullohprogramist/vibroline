import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ConnectionService {
  static const String _apiUrl = 'https://www.kbkontur.ru/iot/get.php';
  static const String _apIp = '192.168.4.1';
  static const Duration _timeout = Duration(seconds: 5);

  // Determine connection mode and get device IP according to technical specification
  Future<String?> determineConnectionMode() async {
    try {
      // First try to get device info from API (STA mode)
      final response = await http.get(Uri.parse(_apiUrl)).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        // Check if we have local_ip (device connected to router)
        if (data.containsKey('local_ip') && data['local_ip'] != null) {
          debugPrint('STA mode detected: ${data['local_ip']}');
          return data['local_ip'] as String;
        }
      }
    } catch (e) {
      debugPrint('API not available (STA mode failed): $e');
    }

    // If API fails, try AP mode
    debugPrint('Falling back to AP mode: $_apIp');
    return _apIp;
  }

  // Get device info from API according to technical specification
  Future<Map<String, dynamic>?> getDeviceInfo() async {
    try {
      final response = await http.get(Uri.parse(_apiUrl)).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        debugPrint('Device info received: $data');
        return data;
      }
    } catch (e) {
      debugPrint('Error getting device info: $e');
    }

    return null;
  }

  // Get WiFi information from device
  Future<WiFiInfo?> getWiFiInfo(String ip) async {
    try {
      final response = await http
          .get(Uri.parse('http://$ip/wifi'))
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return WiFiInfo.fromJson(data);
      }
    } catch (e) {
      debugPrint('Error getting WiFi info from $ip: $e');
    }

    return null;
  }

  // Check if connected via AP mode
  Future<bool> isConnectedViaAP() async {
    final deviceInfo = await getDeviceInfo();
    return deviceInfo == null;
  }

  // Check if connected via STA mode
  Future<bool> isConnectedViaSTA() async {
    final deviceInfo = await getDeviceInfo();
    return deviceInfo != null && deviceInfo.containsKey('local_ip');
  }

  // Test connection to a specific IP
  Future<bool> testConnection(String ip) async {
    try {
      final response = await http
          .get(Uri.parse('http://$ip/status'))
          .timeout(const Duration(seconds: 3));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Connection test failed for $ip: $e');
      return false;
    }
  }

  // Get connection status with enhanced logic according to technical specification
  Future<ConnectionStatus> getConnectionStatus() async {
    try {
      final deviceInfo = await getDeviceInfo();

      if (deviceInfo != null && deviceInfo.containsKey('local_ip')) {
        // STA mode - device connected to router
        final localIp = deviceInfo['local_ip'] as String;
        final isReachable = await testConnection(localIp);

        // Get WiFi info for STA mode
        WiFiInfo? wifiInfo;
        if (isReachable) {
          wifiInfo = await getWiFiInfo(localIp);
        }

        return ConnectionStatus(
          mode: ConnectionMode.router,
          localIp: localIp,
          globalIp: deviceInfo['global_ip'] as String?,
          mac: deviceInfo['mac'] as String?,
          isReachable: isReachable,
          wifiInfo: wifiInfo,
        );
      } else {
        // AP mode - device in access point mode
        final isReachable = await testConnection(_apIp);

        // Get WiFi info for AP mode
        WiFiInfo? wifiInfo;
        if (isReachable) {
          wifiInfo = await getWiFiInfo(_apIp);
        }

        return ConnectionStatus(
          mode: ConnectionMode.ap,
          localIp: _apIp,
          globalIp: null,
          mac: null,
          isReachable: isReachable,
          wifiInfo: wifiInfo,
        );
      }
    } catch (e) {
      debugPrint('Error getting connection status: $e');
      // Fallback to AP mode
      return ConnectionStatus(
        mode: ConnectionMode.ap,
        localIp: _apIp,
        globalIp: null,
        mac: null,
        isReachable: false,
        wifiInfo: null,
      );
    }
  }

  // Get available connection modes
  Future<List<ConnectionMode>> getAvailableModes() async {
    final modes = <ConnectionMode>[];

    // Always add AP mode as fallback
    modes.add(ConnectionMode.ap);

    // Check if STA mode is available
    if (await isConnectedViaSTA()) {
      modes.add(ConnectionMode.router);
    }

    return modes;
  }
}

enum ConnectionMode {
  router, // STA mode - connected to router
  ap, // AP mode - access point
}

class WiFiInfo {
  final String? ssid;
  final String? password;
  final int? rssi;
  final String? ip;
  final String? gateway;
  final String? subnet;

  WiFiInfo({
    this.ssid,
    this.password,
    this.rssi,
    this.ip,
    this.gateway,
    this.subnet,
  });

  factory WiFiInfo.fromJson(Map<String, dynamic> json) {
    return WiFiInfo(
      ssid: json['ssid'] as String?,
      password: json['password'] as String?,
      rssi: json['rssi'] as int?,
      ip: json['ip'] as String?,
      gateway: json['gateway'] as String?,
      subnet: json['subnet'] as String?,
    );
  }

  String get displayName {
    if (ssid != null && ssid!.isNotEmpty) {
      return ssid!;
    }
    return 'Неизвестная сеть';
  }

  String get signalStrength {
    if (rssi == null) return 'Неизвестно';

    if (rssi! >= -50) return 'Отличный';
    if (rssi! >= -60) return 'Хороший';
    if (rssi! >= -70) return 'Средний';
    if (rssi! >= -80) return 'Слабый';
    return 'Очень слабый';
  }
}

class ConnectionStatus {
  final ConnectionMode mode;
  final String? localIp;
  final String? globalIp;
  final String? mac;
  final bool isReachable;
  final WiFiInfo? wifiInfo;

  ConnectionStatus({
    required this.mode,
    this.localIp,
    this.globalIp,
    this.mac,
    this.isReachable = false,
    this.wifiInfo,
  });

  bool get isConnectedViaRouter => mode == ConnectionMode.router;
  bool get isConnectedViaAP => mode == ConnectionMode.ap;

  String get modeDescription {
    switch (mode) {
      case ConnectionMode.router:
        return 'Роутер (STA)';
      case ConnectionMode.ap:
        return 'Точка доступа (AP)';
    }
  }

  String get statusDescription {
    if (!isReachable) {
      return 'Недоступен';
    }
    return modeDescription;
  }

  String get wifiDisplayInfo {
    if (wifiInfo == null) {
      return 'WiFi: Неизвестно';
    }

    if (isConnectedViaRouter) {
      return 'WiFi: ${wifiInfo!.displayName} (${wifiInfo!.signalStrength})';
    } else {
      return 'AP: ${wifiInfo!.displayName}';
    }
  }
}
