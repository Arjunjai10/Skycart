import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'home.dart';
import 'city_screen.dart';
import 'profile_page.dart';
import 'settings_page.dart';
import 'dart:ui';

// class MainNavigation extends StatefulWidget {
//   const MainNavigation({super.key});
//
//   @override
//   State<MainNavigation> createState() => _MainNavigationState();
// }
//
// class _MainNavigationState extends State<MainNavigation>
//     with TickerProviderStateMixin {
//   int _selectedIndex = 0;
//   final AuthService _authService = AuthService();
//   User? _currentUser;
//
//   late final List<Widget> _pages;
//   late final List<AnimationController> _controllers;
//   late final List<CurvedAnimation> _animations;
//
//   @override
//   void initState() {
//     super.initState();
//
//     // ✅ Initialize pages first
//     _pages = const [
//       Home(),
//       CityScreen(),
//       ProfilePage(),
//       SettingsPage(),
//     ];
//
//     // ✅ Then controllers and animations
//     _controllers = List.generate(
//       _pages.length,
//           (index) => AnimationController(
//         duration: const Duration(milliseconds: 300),
//         vsync: this,
//       ),
//     );
//
//     _animations = List.generate(
//       _pages.length,
//           (index) => CurvedAnimation(
//         parent: _controllers[index],
//         curve: Curves.easeInOut,
//       ),
//     );
//
//     _controllers[_selectedIndex].value = 1.0;
//
//     // ✅ Auth listener
//     _authService.authStateChanges.listen((User? user) {
//       setState(() {
//         _currentUser = user;
//       });
//     });
//   }
//
//   @override
//   void dispose() {
//     for (var controller in _controllers) {
//       controller.dispose();
//     }
//     super.dispose();
//   }
//
//   void _onItemTapped(int index) {
//     if (_selectedIndex == index) return;
//     setState(() {
//       _controllers[_selectedIndex].reverse();
//       _selectedIndex = index;
//       _controllers[_selectedIndex].forward();
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (_currentUser == null) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }
//
//     return Scaffold(
//       body: Stack(
//         children: List.generate(
//           _pages.length,
//               (index) => AnimatedBuilder(
//             animation: _animations[index],
//             builder: (context, child) {
//               return IgnorePointer(
//                 ignoring: _selectedIndex != index,
//                 child: Opacity(
//                   opacity: _animations[index].value,
//                   child: Transform.scale(
//                     scale: 0.9 + 0.1 * _animations[index].value,
//                     child: _pages[index],
//                   ),
//                 ),
//               );
//             },
//             child: _pages[index],
//           ),
//         ),
//       ),
//       bottomNavigationBar: _buildAnimatedBottomNavBar(),
//     );
//   }
//
//   Widget _buildAnimatedBottomNavBar() {
//     return ClipRRect(
//       borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
//         child: Container(
//           decoration: BoxDecoration(
//             color: Colors.white.withOpacity(0.9),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.1),
//                 blurRadius: 10,
//                 spreadRadius: 2,
//               ),
//             ],
//           ),
//           child: BottomNavigationBar(
//             currentIndex: _selectedIndex,
//             onTap: _onItemTapped,
//             backgroundColor: Colors.transparent,
//             type: BottomNavigationBarType.fixed,
//             showSelectedLabels: false,
//             showUnselectedLabels: false,
//             selectedItemColor: Theme.of(context).primaryColor,
//             unselectedItemColor: Colors.grey[600],
//             elevation: 0,
//             items: [
//               _buildNavItem(Icons.home, 'Home', 0),
//               _buildNavItem(Icons.location_city, 'City', 1),
//               _buildNavItem(Icons.person, 'Profile', 2),
//               _buildNavItem(Icons.settings, 'Settings', 3),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   BottomNavigationBarItem _buildNavItem(
//       IconData icon, String label, int index) {
//     final bool isSelected = _selectedIndex == index;
//
//     return BottomNavigationBarItem(
//       icon: AnimatedContainer(
//         duration: const Duration(milliseconds: 250),
//         padding: const EdgeInsets.symmetric(vertical: 6),
//         child: Column(
//           children: [
//             AnimatedSwitcher(
//               duration: const Duration(milliseconds: 200),
//               transitionBuilder: (child, animation) => ScaleTransition(
//                 scale: animation,
//                 child: FadeTransition(opacity: animation, child: child),
//               ),
//               child: Icon(
//                 icon,
//                 key: ValueKey('$label-$index'),
//                 size: isSelected ? 28 : 24,
//                 color: isSelected
//                     ? Theme.of(context).primaryColor
//                     : Colors.grey[600],
//               ),
//             ),
//             const SizedBox(height: 2),
//             AnimatedDefaultTextStyle(
//               duration: const Duration(milliseconds: 200),
//               style: TextStyle(
//                 color: isSelected
//                     ? Theme.of(context).primaryColor
//                     : Colors.grey[600],
//                 fontSize: isSelected ? 13 : 12,
//                 fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
//               ),
//               child: Text(label),
//             ),
//           ],
//         ),
//       ),
//       label: '',
//     );
//   }
// }












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