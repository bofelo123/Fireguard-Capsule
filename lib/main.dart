import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'fireguard_dashboard_complete.dart';
import 'fireguard_alerts_notifications_screen.dart';
import 'map_screen.dart';
import 'map_data_controller.dart';

import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const FireGuardApp());
}

class FireGuardApp extends StatelessWidget {
  const FireGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Provider<MapDataController>(
      create: (_) => MapDataController(),
      dispose: (_, controller) => controller.dispose(),

      child: MaterialApp(
        title: 'FireGuard',
        debugShowCheckedModeBanner: false,

        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF07111F),

          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4DA3FF),
            brightness: Brightness.dark,
          ),

          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF07111F),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
        ),

        home: const SplashScreen(),

        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/dashboard': (context) => const FireGuardDashboard(),
          '/alerts': (context) => const FireGuardAlertsScreen(),
          '/map': (context) => const MapScreen(),
        },
      ),
    );
  }
}