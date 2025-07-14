import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import 'home.dart';
import 'city_screen.dart';
import 'profile_page.dart';
import 'settings_page.dart';
import 'dart:ui';


class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  final AuthService _authService = AuthService();
  User? _currentUser;


  late final List<AnimationController> _controllers;
  late final List<CurvedAnimation> _animations;

  final List<Widget> _pages = const [
    Home(),
    CityScreen(),
    ProfilePage(),
    SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _pages.length,
          (index) => AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      ),
    );
    _animations = List.generate(
      _pages.length,
          (index) => CurvedAnimation(
        parent: _controllers[index],
        curve: Curves.easeInOut,
      ),
    );
    _controllers[_selectedIndex].value = 1.0;

    NotificationService().scheduleDailyWeatherNotification();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    setState(() {
      _controllers[_selectedIndex].reverse();
      _selectedIndex = index;
      _controllers[_selectedIndex].forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: List.generate(
          _pages.length,
              (index) => AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) {
              return IgnorePointer(
                ignoring: index != _selectedIndex,
                child: Opacity(
                  opacity: _animations[index].value,
                  child: Transform.scale(
                    scale: 0.9 + 0.1 * _animations[index].value,
                    child: _pages[index],
                  ),
                ),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: _buildAnimatedNavBar(),
    );
  }

  Widget _buildAnimatedNavBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 70,
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            backgroundColor: Colors.white,
            selectedItemColor: Colors.black,
            unselectedItemColor: Colors.grey[600],
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            type: BottomNavigationBarType.fixed,
            items: [
              _buildNavItem(Icons.home, 'Home', 0),
              _buildNavItem(Icons.location_city, 'City', 1),
              _buildNavItem(Icons.person, 'Profile', 2),
              _buildNavItem(Icons.settings, 'Settings', 3),
            ],
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, String label, int index) {
    return BottomNavigationBarItem(
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: animation,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        ),
        child: Icon(
          icon,
          key: ValueKey('$label-$index'),
          size: _selectedIndex == index ? 26 : 22,
        ),
      ),
      label: label,
    );
  }
}