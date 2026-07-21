import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'api/api_client.dart';
import 'api/auth_api.dart';
import 'api/shift_api.dart';
import 'app.dart';
import 'auth/auth_controller.dart';
import 'pos/cart_controller.dart';
import 'pos/shift_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  final apiClient = ApiClient();
  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        Provider<AuthApi>(create: (_) => AuthApi(apiClient)),
        ChangeNotifierProvider<AuthController>(
          create: (_) => AuthController(apiClient, AuthApi(apiClient)),
        ),
        ChangeNotifierProvider<ShiftController>(
          create: (_) => ShiftController(ShiftApi(apiClient)),
        ),
        ChangeNotifierProvider<CartController>(
          create: (_) => CartController(),
        ),
      ],
      child: const KhogaPosApp(),
    ),
  );
}
