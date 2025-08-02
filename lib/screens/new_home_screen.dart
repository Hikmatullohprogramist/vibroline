import 'dart:async';
import 'package:flutter/material.dart';
import '../core/connection_service.dart';
import '../core/websocket_service.dart';
import '../core/notification_service.dart';
import '../models/device_message.dart';

class NewHomeScreen extends StatefulWidget {
  const NewHomeScreen({super.key});

  @override
  State<NewHomeScreen> createState() => _NewHomeScreenState();
}

class _NewHomeScreenState extends State<NewHomeScreen> {
  final ConnectionService _connectionService = ConnectionService();
  final WebSocketService _webSocketService = WebSocketService();
  final NotificationService _notificationService = NotificationService();

  ConnectionStatus? _connectionStatus;
  bool _isConnecting = false;
  String _statusMessage = 'Определение режима подключения...';
  List<DeviceMessage> _messageHistory = [];
  String? _deviceIp;

  @override
  void initState() {
    super.initState();
    _notificationService.init();
    _setupWebSocketCallbacks();
    _determineConnectionMode();
  }

  void _setupWebSocketCallbacks() {
    _webSocketService.setOnMessageCallback(_handleWebSocketMessage);
    _webSocketService.setOnErrorCallback(_handleWebSocketError);
    _webSocketService.setOnConnectedCallback(_handleWebSocketConnected);
    _webSocketService.setOnDisconnectedCallback(_handleWebSocketDisconnected);
  }

  Future<void> _determineConnectionMode() async {
    setState(() {
      _isConnecting = true;
      _statusMessage = 'Определение режима подключения...';
    });

    try {
      _connectionStatus = await _connectionService.getConnectionStatus();
      _deviceIp = _connectionStatus!.localIp;

      setState(() {
        _statusMessage = _connectionStatus!.isConnectedViaRouter
            ? 'Подключено через роутер (${_connectionStatus!.localIp})'
            : 'Подключено через точку доступа (${_connectionStatus!.localIp})';
      });

      // Connect to WebSocket
      await _connectToWebSocket();
    } catch (e) {
      setState(() {
        _statusMessage = 'Ошибка подключения: $e';
        _isConnecting = false;
      });
    }
  }

  Future<void> _connectToWebSocket() async {
    if (_deviceIp == null) return;

    setState(() {
      _statusMessage = 'Подключение к WebSocket...';
    });

    final success = await _webSocketService.connect(_deviceIp!);

    if (!success) {
      setState(() {
        _statusMessage = 'Ошибка подключения к WebSocket';
        _isConnecting = false;
      });
    }
  }

  void _handleWebSocketMessage(Map<String, dynamic> data) {
    final message = DeviceMessage.fromJson(data);

    setState(() {
      _messageHistory.insert(0, message);
      if (_messageHistory.length > 50) {
        _messageHistory.removeLast();
      }
    });

    // Handle alarms
    if (message.hasAlarm) {
      for (final alarmType in message.alarmTypes) {
        final alarmText = DeviceMessage.alarmTypeToText(alarmType);
        _notificationService.show(alarmText);
      }
    }

    // Handle battery low warnings
    if (message.hasBatteryLow) {
      for (final batteryType in message.batteryLowTypes) {
        final batteryText = DeviceMessage.batteryLowTypeToText(batteryType);
        _notificationService.show(batteryText);
      }
    }
  }

  void _handleWebSocketError(String error) {
    setState(() {
      _statusMessage = 'Ошибка WebSocket: $error';
      _isConnecting = false;
    });
  }

  void _handleWebSocketConnected() {
    setState(() {
      _statusMessage = 'WebSocket подключен';
      _isConnecting = false;
    });
  }

  void _handleWebSocketDisconnected() {
    setState(() {
      _statusMessage = 'WebSocket отключен';
      _isConnecting = false;
    });
  }

  void _setWiFiCredentials() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Настройка Wi-Fi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'SSID',
                hintText: 'Имя Wi-Fi сети',
              ),
              onSubmitted: (ssid) {
                Navigator.pop(context);
                _showPasswordDialog(ssid);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );
  }

  void _showPasswordDialog(String ssid) {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Пароль Wi-Fi'),
        content: TextField(
          controller: passwordController,
          decoration: const InputDecoration(
            labelText: 'Пароль',
            hintText: 'Пароль Wi-Fi сети',
          ),
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _webSocketService.setWiFi(ssid, passwordController.text);
            },
            child: const Text('Отправить'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _webSocketService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vibroline'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.wifi),
            onPressed: _setWiFiCredentials,
            tooltip: 'Настройка Wi-Fi',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Connection status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _webSocketService.isConnected
                              ? Icons.check_circle
                              : Icons.error,
                          color: _webSocketService.isConnected
                              ? Colors.green
                              : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _statusMessage,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    if (_connectionStatus != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Режим: ${_connectionStatus!.isConnectedViaRouter ? "Роутер" : "Точка доступа"}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      if (_connectionStatus!.mac != null)
                        Text(
                          'MAC: ${_connectionStatus!.mac}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Message history
            Expanded(
              child: Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'История сообщений',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Expanded(
                      child: _messageHistory.isEmpty
                          ? const Center(child: Text('Сообщений пока нет'))
                          : ListView.builder(
                              itemCount: _messageHistory.length,
                              itemBuilder: (context, index) {
                                final message = _messageHistory[index];
                                return ListTile(
                                  title: Text(_formatMessageTitle(message)),
                                  subtitle: Text(
                                    _formatMessageDetails(message),
                                  ),
                                  leading: Icon(_getMessageIcon(message)),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMessageTitle(DeviceMessage message) {
    if (message.hasAlarm) {
      return 'Тревога: ${message.alarmTypes.map(DeviceMessage.alarmTypeToText).join(", ")}';
    }
    if (message.hasBatteryLow) {
      return 'Батарея: ${message.batteryLowTypes.map(DeviceMessage.batteryLowTypeToText).join(", ")}';
    }
    if (message.hasGpioChanges) {
      return 'GPIO изменения';
    }
    return 'Сообщение от устройства';
  }

  String _formatMessageDetails(DeviceMessage message) {
    final details = <String>[];

    if (message.mac != null) {
      details.add('MAC: ${message.mac}');
    }
    if (message.rssi != null) {
      details.add('RSSI: ${message.rssi}');
    }
    if (message.gpio != null) {
      details.add('GPIO: ${message.gpio}');
    }

    return details.join(', ');
  }

  IconData _getMessageIcon(DeviceMessage message) {
    if (message.hasAlarm) {
      return Icons.warning;
    }
    if (message.hasBatteryLow) {
      return Icons.battery_alert;
    }
    if (message.hasGpioChanges) {
      return Icons.settings_input_component;
    }
    return Icons.message;
  }
}
