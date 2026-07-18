import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth/auth_controller.dart';
import 'orders/barista_portal_screen.dart';
import 'pos/open_shift_screen.dart';
import 'pos/shift_controller.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/manager_dashboard_screen.dart';
import 'theme.dart';

/// Root app widget. Providers are wired above this (see main.dart / tests) so the
/// controllers can be injected.
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

/// Shows the login screen until authenticated, then routes by role: a BARISTA
/// goes straight to the landscape portal (no cash-register shift), everyone else
/// passes through the shift gate to the staff/manager home.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    if (!auth.isAuthenticated) return const LoginScreen();
    if (auth.profile?.role == 'BARISTA') return const BaristaPortalScreen();
    if (auth.profile?.role == 'STORE_MANAGER') {
      return const ManagerDashboardScreen();
    }
    return const ShiftGate();
  }
}

/// Once authenticated, loads the active shift: no open shift -> open-shift screen
/// (34); otherwise the POS home.
class ShiftGate extends StatefulWidget {
  const ShiftGate({super.key});

  @override
  State<ShiftGate> createState() => _ShiftGateState();
}

class _ShiftGateState extends State<ShiftGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ShiftController>().loadActive();
    });
  }

  @override
  Widget build(BuildContext context) {
    final shift = context.watch<ShiftController>();
    if (!shift.loaded) {
      return const Scaffold(body: Center(child: Text('Đang tải…')));
    }
    return shift.hasOpenShift ? const HomeScreen() : const OpenShiftScreen();
  }
}
