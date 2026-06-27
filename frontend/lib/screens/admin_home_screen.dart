// lib/screens/admin_home_screen.dart
import 'dart:ui'; // Required for BackdropFilter
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Your imports
import 'analytics_screen.dart';
import 'register_teacher_screen.dart';
import 'teacher_directory_screen.dart';
import 'live_status_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _setupNotificationsForAdmin();
  }

  Future<void> _setupNotificationsForAdmin() async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      await messaging.subscribeToTopic('admins');
    } catch (e) {
      debugPrint('FCM error: $e');
    }
  }

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. REORDERED PAGES
    final pages = <Widget>[
      const RegisterTeacherScreen(),
      const TeachersDirectoryScreen(),
      const LiveStatusScreen(),
      const AnalyticsScreen(),
    ];

    // 2. REORDERED TITLES
    final titles = [
      'Register Teacher',
      'Directory',
      'Live Status',
      'Analytics',
    ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade900, Colors.black],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,

        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          title: Text(
            titles[_selectedIndex],
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              fontSize: 22,
            ),
          ),
        ),

        // Body with State Preservation
        body: IndexedStack(
          index: _selectedIndex,
          children: pages,
        ),

        // Themed Bottom Navigation
        bottomNavigationBar: NavigationBarTheme(
          data: NavigationBarThemeData(
            indicatorColor: Colors.orangeAccent.withOpacity(0.2),
            labelTextStyle: WidgetStateProperty.all(
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white70),
            ),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const IconThemeData(color: Colors.orangeAccent);
              }
              return const IconThemeData(color: Colors.white54);
            }),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: NavigationBar(
                height: 70,
                backgroundColor: Colors.black.withOpacity(0.4),
                selectedIndex: _selectedIndex,
                onDestinationSelected: _onDestinationSelected,
                // 3. REORDERED ICONS
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.person_add_outlined),
                    selectedIcon: Icon(Icons.person_add),
                    label: 'Register',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.list_alt),
                    selectedIcon: Icon(Icons.list_alt),
                    label: 'Teachers',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.sensors_outlined),
                    selectedIcon: Icon(Icons.sensors),
                    label: 'Live',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.analytics_outlined),
                    selectedIcon: Icon(Icons.analytics),
                    label: 'Analytics',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}