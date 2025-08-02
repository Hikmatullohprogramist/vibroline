import 'dart:convert';
import 'dart:io';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  bool _isConnected = false;
  Function(Map<String, dynamic>)? _onMessageCallback;
  Function(String)? _onErrorCallback;
  Function()? _onConnectedCallback;
  Function()? _onDisconnectedCallback;

  bool get isConnected => _isConnected;

  // Initialize WebSocket connection
  Future<bool> connect(String ip) async {
    try {
      final uri = Uri.parse('ws://$ip/ws');
      _channel = WebSocketChannel.connect(uri);
      
      _channel!.stream.listen(
        (message) {
          _handleMessage(message);
        },
        onError: (error) {
          _isConnected = false;
          _onErrorCallback?.call(error.toString());
        },
        onDone: () {
          _isConnected = false;
          _onDisconnectedCallback?.call();
        },
      );

      _isConnected = true;
      _onConnectedCallback?.call();
      return true;
    } catch (e) {
      _isConnected = false;
      _onErrorCallback?.call(e.toString());
      return false;
    }
  }

  // Handle incoming messages
  void _handleMessage(dynamic message) {
    try {
      if (message is String) {
        final data = json.decode(message) as Map<String, dynamic>;
        _onMessageCallback?.call(data);
      }
    } catch (e) {
      _onErrorCallback?.call('Error parsing message: $e');
    }
  }

  // Send command to ESP8266
  void sendCommand(Map<String, dynamic> command) {
    if (_isConnected && _channel != null) {
      try {
        _channel!.sink.add(json.encode(command));
      } catch (e) {
        _onErrorCallback?.call('Error sending command: $e');
      }
    }
  }

  // Set WiFi credentials
  void setWiFi(String ssid, String password) {
    sendCommand({
      'cmd': 'setwifi',
      'ssid': ssid,
      'pass': password,
    });
  }

  // Set callbacks
  void setOnMessageCallback(Function(Map<String, dynamic>) callback) {
    _onMessageCallback = callback;
  }

  void setOnErrorCallback(Function(String) callback) {
    _onErrorCallback = callback;
  }

  void setOnConnectedCallback(Function() callback) {
    _onConnectedCallback = callback;
  }

  void setOnDisconnectedCallback(Function() callback) {
    _onDisconnectedCallback = callback;
  }

  // Disconnect
  void disconnect() {
    _channel?.sink.close();
    _isConnected = false;
  }

  // Dispose
  void dispose() {
    disconnect();
  }
} 