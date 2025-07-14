import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shimmer/shimmer.dart';

import '../services/user_service.dart';
import '../services/notification_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool isCelsius = true;
  bool isDailyNotificationEnabled = false;
  bool isLoading = true;
  String? errorMessage;

  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _loadAllSettings();
  }

  Future<void> _loadAllSettings() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final prefs = await SharedPreferences.getInstance();

      if (user != null) {
        final userPrefs = await _userService.getUserPreferences(user.uid);

        setState(() {
          isCelsius = userPrefs['isCelsius'] ?? true;
          isDailyNotificationEnabled = prefs.getBool('dailyNotification') ?? false;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'User not logged in';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load settings: ${e.toString()}';
      });
    }
  }

  Future<void> _saveTemperatureSetting(bool value) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _userService.updatePreferences(uid: user.uid, isCelsius: value);
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to save temperature setting: ${e.toString()}';
      });
    }
  }

  Future<void> _toggleDailyNotification(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => isDailyNotificationEnabled = value);
    prefs.setBool('dailyNotification', value);

    if (value) {
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }

      await NotificationService().scheduleDailyWeatherNotification();
      _showSnack('Daily weather notification enabled');
    } else {
      await NotificationService().cancelAllNotifications();
      _showSnack('Daily weather notification disabled');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void resetToDefault() async {
    try {
      setState(() => isLoading = true);
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _userService.updatePreferences(uid: user.uid, isCelsius: true);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('dailyNotification', false);

        await NotificationService().cancelAllNotifications();

        setState(() {
          isCelsius = true;
          isDailyNotificationEnabled = false;
        });

        _showSnack("Settings reset to default");
      }
    } catch (e) {
      _showSnack('Failed to reset settings: ${e.toString()}');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget _buildShimmerSettingItem() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(height: 20, width: 120, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(height: 16, width: 200, color: Colors.grey),
              ),
            ],
          ),
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: 48,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          _buildShimmerSettingItem(),
          const Divider(),
          _buildShimmerSettingItem(),
          const Divider(),
          _buildShimmerSettingItem(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return _buildShimmerLoading();

    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Settings"), backgroundColor: Colors.black),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(errorMessage!),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _loadAllSettings, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text("Temperature Unit"),
            subtitle: const Text("Celsius / Fahrenheit"),
            value: isCelsius,
            onChanged: (val) {
              setState(() => isCelsius = val);
              _saveTemperatureSetting(val);
            },
          ),
          const Divider(),
          SwitchListTile(
            title: const Text("Daily Weather Notifications"),
            value: isDailyNotificationEnabled,
            onChanged: _toggleDailyNotification,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text("Reset to Default"),
            onTap: resetToDefault,
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                "SkyCast Weather App v1.0",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
