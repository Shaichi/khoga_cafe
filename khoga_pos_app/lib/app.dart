import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth/auth_controller.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'theme.dart';

/// Root app widget. Providers are wired above this (see main.dart / tests) so the
/// AuthController can be injected.
class KhogaPosApp extends StatelessWidget {
  const KhogaPosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Khoga POS',
      debugShowCheckedModeBanner: false,
      theme: khogaTheme,
      home: const AuthGate(),
    );
  }
}

/// Shows the login screen until authenticated, then the home screen.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return auth.isAuthenticated ? const HomeScreen() : const LoginScreen();
  }
}
