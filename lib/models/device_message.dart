class DeviceMessage {
  final String? mac;
  final int? rssi;
  final Map<String, int>? gpio;
  final Map<String, int>? alarm;
  final Map<String, int>? batteryLow;

  DeviceMessage({this.mac, this.rssi, this.gpio, this.alarm, this.batteryLow});

  factory DeviceMessage.fromJson(Map<String, dynamic> json) {
    return DeviceMessage(
      mac: json['mac'] as String?,
      rssi: json['rssi'] as int?,
      gpio: json['gpio'] != null
          ? Map<String, int>.from(json['gpio'] as Map)
          : null,
      alarm: json['alarm'] != null
          ? Map<String, int>.from(json['alarm'] as Map)
          : null,
      batteryLow: json['batterylow'] != null
          ? Map<String, int>.from(json['batterylow'] as Map)
          : null,
    );
  }

  // Check if message contains alarm
  bool get hasAlarm => alarm != null && alarm!.isNotEmpty;

  // Check if message contains battery low warning
  bool get hasBatteryLow => batteryLow != null && batteryLow!.isNotEmpty;

  // Check if message contains GPIO changes
  bool get hasGpioChanges => gpio != null && gpio!.isNotEmpty;

  // Get alarm types
  List<String> get alarmTypes {
    if (alarm == null) return [];
    return alarm!.keys.where((key) => alarm![key] == 1).toList();
  }

  // Get battery low types
  List<String> get batteryLowTypes {
    if (batteryLow == null) return [];
    return batteryLow!.keys.where((key) => batteryLow![key] == 0).toList();
  }

  // Convert alarm type to Russian text according to technical specification
  static String alarmTypeToText(String type) {
    switch (type) {
      case 'doorbell':
        return 'Дверной звонок';
      case 'intercom':
        return 'Домофон';
      case 'phone':
        return 'Телефон';
      case 'babycry':
        return 'Плач ребёнка';
      case 'test':
        return 'Тестирование системы';
      case 'smoke':
        return 'Датчик дыма';
      case 'gas':
        return 'Датчик утечки бытового газа';
      default:
        return 'Неизвестно';
    }
  }

  // Convert battery low type to Russian text
  static String batteryLowTypeToText(String type) {
    return 'Батарея разряжена: ${alarmTypeToText(type)}';
  }

  // Get GPIO status text
  String get gpioStatusText {
    if (gpio == null || gpio!.isEmpty) return 'GPIO: Нет данных';

    final statusList = <String>[];
    gpio!.forEach((key, value) {
      statusList.add('$key: ${value == 1 ? "ВКЛ" : "ВЫКЛ"}');
    });

    return 'GPIO: ${statusList.join(", ")}';
  }

  // Get message summary for display
  String get messageSummary {
    if (hasAlarm) {
      return 'Тревога: ${alarmTypes.map(alarmTypeToText).join(", ")}';
    }
    if (hasBatteryLow) {
      return 'Батарея: ${batteryLowTypes.map(batteryLowTypeToText).join(", ")}';
    }
    if (hasGpioChanges) {
      return gpioStatusText;
    }
    if (mac != null) {
      return 'Устройство: $mac';
    }
    return 'Сообщение от устройства';
  }
}
