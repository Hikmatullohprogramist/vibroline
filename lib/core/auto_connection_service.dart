import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
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
  Timer? _statusCheckTimer;

  String? _currentIp;
  ConnectionStatus? _connectionStatus;
  ConnectionMode _preferredMode = ConnectionMode.ap;

  // Callbacks
  Function(DeviceMessage)? _onMessageCallback;
  Function(String)? _onErrorCallback;
  Function()? _onConnectedCallback;
  Function()? _onDisconnectedCallback;
  Function(ConnectionStatus)? _onConnectionStatusChanged;

  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  ConnectionStatus? get connectionStatus => _connectionStatus;
  ConnectionMode get preferredMode => _preferredMode;

  // Initialize auto connection
  Future<void> initialize() async {
    await _notificationService.init();
    _startAutoConnection();
  }

  // Set preferred connection mode
  void setPreferredMode(ConnectionMode mode) {
    _preferredMode = mode;
    debugPrint('Preferred mode set to: ${mode.name}');
  }

  // Start automatic connection process with enhanced logic
  Future<void> _startAutoConnection() async {
    if (_isConnecting) return;

    _isConnecting = true;
    debugPrint(
      'Starting auto connection with preferred mode: ${_preferredMode.name}',
    );

    try {
      // Get available modes
      final availableModes = await _connectionService.getAvailableModes();
      debugPrint(
        'Available modes: ${availableModes.map((m) => m.name).join(', ')}',
      );

      // Determine connection mode based on preference and availability
      ConnectionMode targetMode;
      if (_preferredMode == ConnectionMode.router &&
          availableModes.contains(ConnectionMode.router)) {
        targetMode = ConnectionMode.router;
        debugPrint('Using STA mode (router)');
      } else {
        targetMode = ConnectionMode.ap;
        debugPrint('Using AP mode (access point)');
      }

      // Get connection status for the target mode
      _connectionStatus = await _connectionService.getConnectionStatus();

      // If we want STA but got AP, try to force STA mode
      if (targetMode == ConnectionMode.router &&
          _connectionStatus!.isConnectedViaAP) {
        debugPrint('Forcing STA mode detection...');
        // Try to get device info again
        final deviceInfo = await _connectionService.getDeviceInfo();
        if (deviceInfo != null && deviceInfo.containsKey('local_ip')) {
          _connectionStatus = ConnectionStatus(
            mode: ConnectionMode.router,
            localIp: deviceInfo['local_ip'] as String,
            globalIp: deviceInfo['global_ip'] as String?,
            mac: deviceInfo['mac'] as String?,
            isReachable: true,
          );
        }
      }

      _currentIp = _connectionStatus!.localIp;

      // Notify status change
      _onConnectionStatusChanged?.call(_connectionStatus!);

      // Connect to WebSocket
      await _connectToWebSocket();

      // Start periodic status check
      _startStatusCheck();
    } catch (e) {
      _handleError('Ошибка определения режима подключения: $e');
      _scheduleReconnect();
    }
  }

  // Connect to WebSocket with enhanced error handling
  Future<void> _connectToWebSocket() async {
    if (_currentIp == null) {
      _handleError('IP адрес не определен');
      return;
    }

    try {
      final uri = Uri.parse('ws://$_currentIp/ws');
      debugPrint('Attempting WebSocket connection to: $uri');

      _channel = WebSocketChannel.connect(uri);

      _channel!.stream.listen(
        (message) => _handleMessage(message),
        onError: (error) {
          debugPrint('WebSocket error: $error');
          _handleError('WebSocket ошибка: $error');
        },
        onDone: () {
          debugPrint('WebSocket connection closed');
          _handleDisconnection();
        },
      );

      _isConnected = true;
      _isConnecting = false;
      _onConnectedCallback?.call();

      // Start heartbeat
      _startHeartbeat();

      debugPrint('WebSocket успешно подключен к $_currentIp');
    } catch (e) {
      debugPrint('WebSocket connection failed: $e');
      _handleError('Ошибка подключения к WebSocket: $e');
      _scheduleReconnect();
    }
  }

  // Start periodic status check
  void _startStatusCheck() {
    _stopStatusCheck();
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 30), (
      timer,
    ) async {
      if (!_isConnected) return;

      try {
        final newStatus = await _connectionService.getConnectionStatus();
        bool shouldReconnect = false;

        // Check if IP changed
        if (newStatus.localIp != _currentIp) {
          debugPrint(
            'IP address changed from $_currentIp to ${newStatus.localIp}',
          );
          _currentIp = newStatus.localIp;
          shouldReconnect = true;
        }

        // Check if WiFi info changed
        if (_connectionStatus?.wifiInfo?.ssid != newStatus.wifiInfo?.ssid) {
          debugPrint(
            'WiFi network changed: ${_connectionStatus?.wifiInfo?.ssid} -> ${newStatus.wifiInfo?.ssid}',
          );
        }

        _connectionStatus = newStatus;
        _onConnectionStatusChanged?.call(newStatus);

        // Reconnect if IP changed
        if (shouldReconnect) {
          await _reconnectWithNewIp();
        }
      } catch (e) {
        debugPrint('Status check error: $e');
      }
    });
  }

  // Stop status check
  void _stopStatusCheck() {
    _statusCheckTimer?.cancel();
    _statusCheckTimer = null;
  }

  // Reconnect with new IP
  Future<void> _reconnectWithNewIp() async {
    debugPrint('Reconnecting with new IP: $_currentIp');
    disconnect();
    await Future.delayed(const Duration(seconds: 2));
    _startAutoConnection();
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

  // Handle errors with enhanced logging
  void _handleError(String error) {
    debugPrint('AutoConnection Error: $error');
    _isConnected = false;
    _isConnecting = false;
    _onErrorCallback?.call(error);
  }

  // Handle disconnection
  void _handleDisconnection() {
    debugPrint('WebSocket отключен');
    _isConnected = false;
    _stopHeartbeat();
    _onDisconnectedCallback?.call();
    _scheduleReconnect();
  }

  // Schedule reconnection with exponential backoff
  void _scheduleReconnect() {
    if (_reconnectTimer != null) return;

    debugPrint('Планирование переподключения через 5 секунд...');
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
          debugPrint('Heartbeat error: $e');
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

  // Set WiFi credentials for STA mode
  void setWiFi(String ssid, String password) {
    debugPrint('Setting WiFi credentials for STA mode: $ssid');
    sendCommand({'cmd': 'setwifi', 'ssid': ssid, 'pass': password});
  }

  // Switch to AP mode
  void switchToAPMode() {
    debugPrint('Switching to AP mode');
    sendCommand({'cmd': 'switch_to_ap'});
    setPreferredMode(ConnectionMode.ap);

    // Reconnect after mode switch
    Future.delayed(const Duration(seconds: 2), () {
      reconnect();
    });
  }

  // Switch to STA mode with WiFi configuration
  void switchToSTAMode() {
    debugPrint('Switching to STA mode');
    sendCommand({'cmd': 'switch_to_sta'});
    setPreferredMode(ConnectionMode.router);

    // Reconnect after mode switch with delay
    Future.delayed(const Duration(seconds: 5), () {
      reconnect();
    });
  }

  // Switch to STA mode with WiFi credentials
  void switchToSTAModeWithWiFi(String ssid, String password) {
    debugPrint('Switching to STA mode with WiFi: $ssid');

    // First set WiFi credentials
    setWiFi(ssid, password);

    // Then switch to STA mode
    Future.delayed(const Duration(seconds: 1), () {
      switchToSTAMode();
    });
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
    _stopStatusCheck();
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
    }

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
}
