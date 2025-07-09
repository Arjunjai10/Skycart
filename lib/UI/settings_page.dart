import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool isDarkMode = false;
  bool isCelsius = true;
  final UserService _userService = UserService();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final prefs = await _userService.getUserPreferences(user.uid);
      setState(() {
        isDarkMode = prefs['isDarkMode'] ?? false;
        isCelsius = prefs['isCelsius'] ?? true;
        isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _userService.updatePreferences(user.uid, isDarkMode, isCelsius);
    }
  }

  void resetToDefault() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _userService.updatePreferences(user.uid, false, true);
      setState(() {
        isDarkMode = false;
        isCelsius = true;
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Settings reset to default")),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            )),
        backgroundColor: Colors.black,
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text("Dark Mode"),
            value: isDarkMode,
            onChanged: (val) {
              setState(() => isDarkMode = val);
              _saveSettings();
            },
          ),
          SwitchListTile(
            title: const Text("Temperature in Celsius"),
            subtitle: const Text("Turn off for Fahrenheit"),
            value: isCelsius,
            onChanged: (val) {
              setState(() => isCelsius = val);
              _saveSettings();
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text("Reset to Default"),
            onTap: resetToDefault,
          ),
        ],
      ),
    );
  }
}