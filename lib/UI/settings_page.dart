import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool isCelsius = true;
  final UserService _userService = UserService();
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final prefs = await _userService.getUserPreferences(user.uid);
        setState(() {
          isCelsius = prefs['isCelsius'] ?? true;
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

  Future<void> _saveSettings() async {
    try {
      setState(() => isLoading = true);
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _userService.updatePreferences(uid: user.uid, isCelsius: isCelsius);
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to save settings: ${e.toString()}';
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  void resetToDefault() async {
    try {
      setState(() => isLoading = true);
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _userService.updatePreferences(uid: user.uid, isCelsius: true);
        setState(() {
          isCelsius = true;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Settings reset to default")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reset settings: ${e.toString()}')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget _buildShimmerLoading() {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Settings",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.black,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          _buildShimmerSettingItem(),
          const Divider(),
          _buildShimmerSettingItem(),
          const SizedBox(height: 16),
          _buildShimmerSettingItem(),
          const Spacer(),
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              margin: const EdgeInsets.all(16),
              height: 20,
              width: 200,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
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
                child: Container(
                  height: 20,
                  width: 120,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  height: 16,
                  width: 200,
                  color: Colors.grey,
                ),
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildShimmerLoading();
    }

    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Settings"),
          backgroundColor: Colors.black,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(errorMessage!),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadSettings,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Settings",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          SwitchListTile(
            title: const Text("Temperature Unit"),
            subtitle: const Text("Celsius / Fahrenheit"),
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
          const Spacer(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "SkyCast Weather App v1.0",
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}