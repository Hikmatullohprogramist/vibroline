import 'package:flutter/material.dart';
import '../core/auto_connection_service.dart';
import '../core/connection_service.dart';
import '../models/device_message.dart';

class AutoHomeScreen extends StatefulWidget {
  const AutoHomeScreen({super.key});

  @override
  State<AutoHomeScreen> createState() => _AutoHomeScreenState();
}

class _AutoHomeScreenState extends State<AutoHomeScreen> {
  final AutoConnectionService _autoConnectionService = AutoConnectionService();

  List<DeviceMessage> _messageHistory = [];
  String _statusMessage = 'Инициализация...';
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _setupCallbacks();
    _initializeConnection();
  }

  void _setupCallbacks() {
    _autoConnectionService.setOnMessageCallback(_handleMessage);
    _autoConnectionService.setOnErrorCallback(_handleError);
    _autoConnectionService.setOnConnectedCallback(_handleConnected);
    _autoConnectionService.setOnDisconnectedCallback(_handleDisconnected);
    _autoConnectionService.setOnConnectionStatusChanged(
      _handleConnectionStatusChanged,
    );
  }

  Future<void> _initializeConnection() async {
    try {
      await _autoConnectionService.initialize();
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Ошибка инициализации: $e';
      });
    }
  }

  void _handleMessage(DeviceMessage message) {
    setState(() {
      _messageHistory.insert(0, message);
      if (_messageHistory.length > 100) {
        _messageHistory.removeLast();
      }
    });
  }

  void _handleError(String error) {
    setState(() {
      _statusMessage = error;
    });
  }

  void _handleConnected() {
    setState(() {
      _statusMessage = 'Подключено к устройству';
    });
  }

  void _handleDisconnected() {
    setState(() {
      _statusMessage = 'Отключено от устройства';
    });
  }

  void _handleConnectionStatusChanged(ConnectionStatus status) {
    setState(() {
      if (status.isConnectedViaRouter) {
        _statusMessage = 'Подключено через роутер (${status.localIp})';
      } else {
        _statusMessage = 'Подключено через точку доступа (${status.localIp})';
      }
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
              _autoConnectionService.setWiFi(ssid, passwordController.text);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Wi-Fi настройки отправлены')),
              );
            },
            child: const Text('Отправить'),
          ),
        ],
      ),
    );
  }

  void _reconnect() {
    _autoConnectionService.reconnect();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Переподключение...')));
  }

  @override
  void dispose() {
    _autoConnectionService.dispose();
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reconnect,
            tooltip: 'Переподключиться',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Connection status card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _autoConnectionService.isConnected
                              ? Icons.check_circle
                              : _autoConnectionService.isConnecting
                              ? Icons.sync
                              : Icons.error,
                          color: _autoConnectionService.isConnected
                              ? Colors.green
                              : _autoConnectionService.isConnecting
                              ? Colors.orange
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
                    if (_autoConnectionService.connectionStatus != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Режим: ${_autoConnectionService.connectionStatus!.isConnectedViaRouter ? "Роутер" : "Точка доступа"}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      if (_autoConnectionService.connectionStatus!.mac != null)
                        Text(
                          'MAC: ${_autoConnectionService.connectionStatus!.mac}',
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'История сообщений',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            '${_messageHistory.length}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _messageHistory.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.message,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Сообщений пока нет',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            )
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
                                  trailing: Text(
                                    _formatTime(DateTime.now()),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
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

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
