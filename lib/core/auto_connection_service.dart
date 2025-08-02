import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'connection_service.dart';
import 'notification_service.dart';
import '../models/device_message.dart';

class AutoConnectionService {
  final ConnectionService _connectionService = ConnectionService();
  final NotificationService _notificationService = NotificationService();

  WebSocketChannel? _channel;
  bool _isConnected = false;
  bool _isConnecting = false;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;

  String? _currentIp;
  ConnectionStatus? _connectionStatus;

  // Callbacks
  Function(DeviceMessage)? _onMessageCallback;
  Function(String)? _onErrorCallback;
  Function()? _onConnectedCallback;
  Function()? _onDisconnectedCallback;
  Function(ConnectionStatus)? _onConnectionStatusChanged;

  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  ConnectionStatus? get connectionStatus => _connectionStatus;

  // Initialize auto connection
  Future<void> initialize() async {
    await _notificationService.init();
    _startAutoConnection();
  }

  // Start automatic connection process
  Future<void> _startAutoConnection() async {
    if (_isConnecting) return;

    _isConnecting = true;

    try {
      // Determine connection mode
      _connectionStatus = await _connectionService.getConnectionStatus();
      _currentIp = _connectionStatus!.localIp;

      // Notify status change
      _onConnectionStatusChanged?.call(_connectionStatus!);

      // Connect to WebSocket
      await _connectToWebSocket();
    } catch (e) {
      _handleError('Ошибка определения режима подключения: $e');
      _scheduleReconnect();
    }
  }

  // Connect to WebSocket
  Future<void> _connectToWebSocket() async {
    if (_currentIp == null) {
      _handleError('IP адрес не определен');
      return;
    }

    try {
      final uri = Uri.parse('ws://$_currentIp/ws');
      _channel = WebSocketChannel.connect(uri);

      _channel!.stream.listen(
        (message) => _handleMessage(message),
        onError: (error) => _handleError('WebSocket ошибка: $error'),
        onDone: () => _handleDisconnection(),
      );

      _isConnected = true;
      _isConnecting = false;
      _onConnectedCallback?.call();

      // Start heartbeat
      _startHeartbeat();

      print('WebSocket подключен к $_currentIp');
    } catch (e) {
      _handleError('Ошибка подключения к WebSocket: $e');
      _scheduleReconnect();
    }
  }

  // Handle incoming messages
  void _handleMessage(dynamic message) {
    try {
      if (message is String) {
        final data = json.decode(message) as Map<String, dynamic>;
        final deviceMessage = DeviceMessage.fromJson(data);

        _onMessageCallback?.call(deviceMessage);

        // Handle alarms
        if (deviceMessage.hasAlarm) {
          for (final alarmType in deviceMessage.alarmTypes) {
            final alarmText = DeviceMessage.alarmTypeToText(alarmType);
            _notificationService.show(alarmText);
          }
        }

        // Handle battery low warnings
        if (deviceMessage.hasBatteryLow) {
          for (final batteryType in deviceMessage.batteryLowTypes) {
            final batteryText = DeviceMessage.batteryLowTypeToText(batteryType);
            _notificationService.show(batteryText);
          }
        }
      }
    } catch (e) {
      _handleError('Ошибка обработки сообщения: $e');
    }
  }

  // Handle errors
  void _handleError(String error) {
    print('AutoConnection Error: $error');
    _isConnected = false;
    _isConnecting = false;
    _onErrorCallback?.call(error);
  }

  // Handle disconnection
  void _handleDisconnection() {
    print('WebSocket отключен');
    _isConnected = false;
    _stopHeartbeat();
    _onDisconnectedCallback?.call();
    _scheduleReconnect();
  }

  // Schedule reconnection
  void _scheduleReconnect() {
    if (_reconnectTimer != null) return;

    print('Планирование переподключения через 5 секунд...');
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      _reconnectTimer = null;
      if (!_isConnected && !_isConnecting) {
        _startAutoConnection();
      }
    });
  }

  // Start heartbeat to keep connection alive
  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isConnected && _channel != null) {
        try {
          _channel!.sink.add(json.encode({'type': 'ping'}));
        } catch (e) {
          print('Heartbeat error: $e');
          _handleDisconnection();
        }
      }
    });
  }

  // Stop heartbeat
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  // Send command to ESP8266
  void sendCommand(Map<String, dynamic> command) {
    if (_isConnected && _channel != null) {
      try {
        _channel!.sink.add(json.encode(command));
      } catch (e) {
        _handleError('Ошибка отправки команды: $e');
      }
    } else {
      _handleError('Нет подключения к устройству');
    }
  }

  // Set WiFi credentials
  void setWiFi(String ssid, String password) {
    sendCommand({'cmd': 'setwifi', 'ssid': ssid, 'pass': password});
  }

  // Manual reconnect
  Future<void> reconnect() async {
    disconnect();
    await Future.delayed(const Duration(seconds: 1));
    _startAutoConnection();
  }

  // Disconnect
  void disconnect() {
    _stopHeartbeat();
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _channel?.sink.close();
    _isConnected = false;
    _isConnecting = false;
  }

  // Set callbacks
  void setOnMessageCallback(Function(DeviceMessage) callback) {
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

  void setOnConnectionStatusChanged(Function(ConnectionStatus) callback) {
    _onConnectionStatusChanged = callback;
  }

  // Dispose
  void dispose() {
    disconnect();
  }
}
