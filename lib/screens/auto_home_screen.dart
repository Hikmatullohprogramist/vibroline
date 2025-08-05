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
  String _wifiSSID = '';
  String _wifiPassword = '';

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

  void _showWiFiDialog() {
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
              onChanged: (value) => _wifiSSID = value,
              onSubmitted: (ssid) {
                _wifiSSID = ssid;
                _showPasswordDialog();
              },
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Пароль',
                hintText: 'Пароль Wi-Fi сети',
              ),
              obscureText: true,
              onChanged: (value) => _wifiPassword = value,
              onSubmitted: (password) {
                _wifiPassword = password;
                _setWiFiCredentials();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: _setWiFiCredentials,
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _showPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Пароль Wi-Fi'),
        content: TextField(
          decoration: InputDecoration(
            labelText: 'Пароль',
            hintText: 'Введите пароль для $_wifiSSID',
          ),
          obscureText: true,
          onChanged: (value) => _wifiPassword = value,
          onSubmitted: (password) {
            _wifiPassword = password;
            Navigator.of(context).pop();
            _setWiFiCredentials();
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _setWiFiCredentials();
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _setWiFiCredentials() {
    if (_wifiSSID.isNotEmpty && _wifiPassword.isNotEmpty) {
      _autoConnectionService.setWiFi(_wifiSSID, _wifiPassword);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Wi-Fi настройки отправлены: $_wifiSSID'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пожалуйста, введите SSID и пароль'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _switchToAPMode() {
    _autoConnectionService.switchToAPMode();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Переключение в режим точки доступа...'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _switchToSTAMode() {
    _showWiFiConfigForSTAMode();
  }

  void _showWiFiConfigForSTAMode() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Настройка Wi-Fi для STA режима'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Для переключения в режим роутера необходимо указать параметры Wi-Fi сети.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'SSID',
                hintText: 'Имя Wi-Fi сети',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _wifiSSID = value,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Пароль',
                hintText: 'Пароль Wi-Fi сети',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              onChanged: (value) => _wifiPassword = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_wifiSSID.isNotEmpty && _wifiPassword.isNotEmpty) {
                Navigator.of(context).pop();
                _performSTAModeSwitch();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Пожалуйста, введите SSID и пароль'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Переключиться'),
          ),
        ],
      ),
    );
  }

  void _performSTAModeSwitch() {
    // Use the new method that handles WiFi configuration and mode switching
    _autoConnectionService.switchToSTAModeWithWiFi(_wifiSSID, _wifiPassword);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'WiFi настройки отправлены: $_wifiSSID\nПереключение в режим роутера...',
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _reconnect() {
    _autoConnectionService.reconnect();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Переподключение...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vibroline'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reconnect,
            tooltip: 'Переподключиться',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'wifi':
                  _showWiFiDialog();
                  break;
                case 'ap_mode':
                  _switchToAPMode();
                  break;
                case 'sta_mode':
                  _switchToSTAMode();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'wifi',
                child: Row(
                  children: [
                    Icon(Icons.wifi),
                    SizedBox(width: 8),
                    Text('Настройка Wi-Fi'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'ap_mode',
                child: Row(
                  children: [
                    Icon(Icons.wifi_tethering),
                    SizedBox(width: 8),
                    Text('Режим точки доступа'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'sta_mode',
                child: Row(
                  children: [
                    Icon(Icons.router),
                    SizedBox(width: 8),
                    Text('Режим роутера (STA)'),
                  ],
                ),
              ),
            ],
            child: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
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
                      Row(
                        children: [
                          Icon(
                            _autoConnectionService
                                    .connectionStatus!
                                    .isConnectedViaRouter
                                ? Icons.router
                                : Icons.wifi_tethering,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _autoConnectionService
                                .connectionStatus!
                                .statusDescription,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      // WiFi information
                      if (_autoConnectionService.connectionStatus!.wifiInfo !=
                          null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              _autoConnectionService
                                      .connectionStatus!
                                      .isConnectedViaRouter
                                  ? Icons.wifi
                                  : Icons.wifi_tethering,
                              size: 16,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _autoConnectionService
                                    .connectionStatus!
                                    .wifiDisplayInfo,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (_autoConnectionService.connectionStatus!.mac != null)
                        Text(
                          'MAC: ${_autoConnectionService.connectionStatus!.mac}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      if (_autoConnectionService.connectionStatus!.globalIp !=
                          null)
                        Text(
                          'Внешний IP: ${_autoConnectionService.connectionStatus!.globalIp}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _autoConnectionService.isConnected
                                ? null
                                : _reconnect,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Переподключиться'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _showWiFiDialog,
                            icon: const Icon(Icons.wifi),
                            label: const Text('Wi-Fi'),
                          ),
                        ),
                      ],
                    ),
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
