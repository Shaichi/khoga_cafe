import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:khoga_pos_app/api/api_client.dart';
import 'package:khoga_pos_app/api/auth_api.dart';
import 'package:khoga_pos_app/api/shift_api.dart';
import 'package:khoga_pos_app/app.dart';
import 'package:khoga_pos_app/auth/auth_controller.dart';
import 'package:khoga_pos_app/pos/shift_controller.dart';

/// Builds the full app with both controllers sharing one ApiClient (so the token
/// set at login is used by later shift calls), for widget-flow tests.
Widget buildApp(ApiClient client) => MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController(client, AuthApi(client))),
        ChangeNotifierProvider(create: (_) => ShiftController(ShiftApi(client))),
      ],
      child: const KhogaPosApp(),
    );
