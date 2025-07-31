import 'dart:async';
import 'package:flutter/material.dart';
import '../core/network_service.dart';
import '../core/notification_service.dart';
import '../models/event_model.dart';
import '../widgets/event_history_list.dart';
import '../widgets/status_panel.dart';
import 'dart:math';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ipController = TextEditingController();
  String status = 'Ожидание...';
  Timer? timer;
  bool connected = false;
  final List<EventModel> eventHistory = [];
  final networkService = NetworkService();
  final notificationService = NotificationService();
  String lastEvent = '';

  @override
  void initState() {
    super.initState();
    notificationService.init();
  }

  void startPolling(String ip) {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 3), (_) => checkEvent(ip));
    setState(() {
      status = 'Ожидание событий...';
      connected = true;
    });
  }

  Future<void> checkEvent(String ip) async {
    final body = await networkService.fetchEvent(ip);
    if (body != null && body != lastEvent) {
      lastEvent = body;
      final source = body.contains('doorbell')
          ? 'Дверной звонок'
          : body.contains('phone')
          ? 'Телефон'
          : body.contains('intercom')
          ? 'Домофон'
          : body.contains('baby')
          ? 'Детский плач'
          : 'Неизвестно';
      notificationService.show(source);
      setState(() {
        status = 'Получено событие: $source';
        eventHistory.insert(
          0,
          EventModel(source: source, time: DateTime.now()),
        );
      });
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    ipController.dispose();
    super.dispose();
  }

  void showTestNotification() {
    // Test signal turlari
    final testSources = [
      'Дверной звонок',
      'Телефон',
      'Домофон',
      'Детский плач',
      'Неизвестно',
    ];
    // Tasodifiy birini tanlash
    final randomSource = testSources[Random().nextInt(testSources.length)];
    notificationService.show(randomSource);
    setState(() {
      eventHistory.insert(
        0,
        EventModel(source: randomSource, time: DateTime.now()),
      );
      status = 'Тест: $randomSource';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vibroline'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: showTestNotification,
            icon: Icon(Icons.notifications),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Введите IP-адрес устройства:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: ipController,
                    enabled: !connected,
                    decoration: const InputDecoration(
                      hintText: 'например, 192.168.4.1',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: connected
                      ? null
                      : () {
                          if (ipController.text.isNotEmpty) {
                            startPolling(ipController.text);
                          }
                        },
                  icon: const Icon(Icons.wifi),
                  label: const Text('Подключиться'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            StatusPanel(connected: connected, status: status),
            const SizedBox(height: 24),
            const Text(
              'История событий:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Expanded(child: EventHistoryList(events: eventHistory)),
          ],
        ),
      ),
    );
  }
}
