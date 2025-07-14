import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
    InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(initializationSettings);
  }

  Future<void> showNotification({
    required String title,
    required String body,
    int id = 0,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'weather_alerts_channel',
      'Weather Alerts',
      channelDescription: 'Channel for weather alerts and notifications',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  Future<void> scheduleDailyWeatherNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'daily_weather_channel',
      'Daily Weather',
      channelDescription: 'Channel for daily weather updates',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    // Schedule for 8 AM daily
    await _notificationsPlugin.periodicallyShow(
      1,
      'Daily Weather Update',
      'Check today\'s weather forecast',
      RepeatInterval.daily,
      platformChannelSpecifics,
    );
  }

  Future<void> showWeatherAlert(String condition) async {
    String title = 'Weather Alert!';
    String body = '';

    switch (condition.toLowerCase()) {
      case 'thunderstorm':
        body = 'Thunderstorm expected in your area. Stay safe!';
        break;
      case 'heavy rain':
        body = 'Heavy rain forecasted. Don\'t forget your umbrella!';
        break;
      case 'snow':
        body = 'Snow expected today. Dress warmly!';
        break;
      case 'extreme heat':
        body = 'Extreme heat warning. Stay hydrated!';
        break;
      default:
        return; // Don't show notification for normal conditions
    }

    await showNotification(title: title, body: body);
  }
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

}