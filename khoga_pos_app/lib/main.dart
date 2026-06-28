import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'api/api_client.dart';
import 'api/auth_api.dart';
import 'app.dart';
import 'auth/auth_controller.dart';

void main() {
  final apiClient = ApiClient();
  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        ChangeNotifierProvider<AuthController>(
          create: (_) => AuthController(apiClient, AuthApi(apiClient)),
        ),
      ],
      child: const KhogaPosApp(),
    ),
  );
}
