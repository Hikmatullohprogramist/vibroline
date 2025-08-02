import 'dart:convert';
import 'package:http/http.dart' as http;

class ConnectionService {
  static const String _apiUrl = 'https://www.kbkontur.ru/iot/get.php';
  static const String _apIp = '192.168.4.1';

  // Determine connection mode and get device IP
  Future<String?> determineConnectionMode() async {
    try {
      // Try to get device info from API
      final response = await http.get(Uri.parse(_apiUrl));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        
        // Check if we have local_ip (device connected to router)
        if (data.containsKey('local_ip')) {
          return data['local_ip'] as String;
        }
      }
    } catch (e) {
      // API not available, probably connected via AP
      print('API not available: $e');
    }
    
    // Return AP IP if API fails
    return _apIp;
  }

  // Get device info from API
  Future<Map<String, dynamic>?> getDeviceInfo() async {
    try {
      final response = await http.get(Uri.parse(_apiUrl));
      
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      print('Error getting device info: $e');
    }
    
    return null;
  }

  // Check if connected via AP mode
  Future<bool> isConnectedViaAP() async {
    final deviceInfo = await getDeviceInfo();
    return deviceInfo == null;
  }

  // Get connection status
  Future<ConnectionStatus> getConnectionStatus() async {
    final deviceInfo = await getDeviceInfo();
    
    if (deviceInfo != null) {
      return ConnectionStatus(
        mode: ConnectionMode.router,
        localIp: deviceInfo['local_ip'],
        globalIp: deviceInfo['global_ip'],
        mac: deviceInfo['mac'],
      );
    } else {
      return ConnectionStatus(
        mode: ConnectionMode.ap,
        localIp: _apIp,
        globalIp: null,
        mac: null,
      );
    }
  }
}

enum ConnectionMode {
  router,
  ap,
}

class ConnectionStatus {
  final ConnectionMode mode;
  final String? localIp;
  final String? globalIp;
  final String? mac;

  ConnectionStatus({
    required this.mode,
    this.localIp,
    this.globalIp,
    this.mac,
  });

  bool get isConnectedViaRouter => mode == ConnectionMode.router;
  bool get isConnectedViaAP => mode == ConnectionMode.ap;
} 