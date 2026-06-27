import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'screens/role_selection_screen.dart';
import 'screens/admin_login_screen.dart';
import 'screens/admin_home_screen.dart';
import 'screens/kiosk_screen.dart';
import 'firebase_options.dart'; // if using flutterfire configure

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // You can log background message if you want
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const AttendanceApp());
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Teacher Attendance',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      initialRoute: '/role',
      routes: {
        '/role': (_) => const RoleSelectionScreen(),
        '/adminLogin': (_) => const AdminLoginScreen(),
        '/adminHome': (_) => const AdminHomeScreen(),
        '/kiosk': (_) => const KioskScreen(),
      },
    );
  }
}
