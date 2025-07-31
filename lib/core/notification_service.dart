import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    await _requestPermission();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await notificationsPlugin.initialize(
      const InitializationSettings(android: android),
    );
  }

  Future<void> _requestPermission() async {
    final status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }
  }

  Future<void> show(String source) async {
    const android = AndroidNotificationDetails(
      'vibroline_channel',
      'Vibroline',
      importance: Importance.max,
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(android: android);
    await notificationsPlugin.show(
      0,
      'Vibroline',
      'Сработал: $source',
      notificationDetails,
    );
  }
}
