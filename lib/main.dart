import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tripiz_driver_mobile_app/common/common_scaffold.dart';
import 'package:tripiz_driver_mobile_app/common/constants/app_colors.dart';
import 'package:tripiz_driver_mobile_app/location/location_permission_screen.dart';
import 'package:tripiz_driver_mobile_app/location/ws_position_sender.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final WsPositionSender _wsSender;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();

    _wsSender = WsPositionSender(
       onError: (msg) => debugPrint("WsPositionSender: $msg"),
    );

    _router = GoRouter(
      initialLocation: '/permission',
      routes: [
        GoRoute(
          path: '/permission',
          builder: (context, state) => LocationPermissionScreen(
            onGranted: () {
              _wsSender.init(); // démarre GPS + tentative de connexion/envoi
              _router.go('/app');
            },
          ),
        ),
        GoRoute(
          path: '/app',
          builder: (context, state) => const CommonScaffold(),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _wsSender.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Tripiz Driver',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
      ),
      routerConfig: _router,
    );
  }
}