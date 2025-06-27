import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tripiz_driver_mobile_app/QRCode/screens/qrcode_screen.dart';
import 'package:tripiz_driver_mobile_app/common/common_scaffold.dart';
import 'package:tripiz_driver_mobile_app/common/constants/app_colors.dart';
import 'package:tripiz_driver_mobile_app/home/screens/home_screen.dart';
import 'package:tripiz_driver_mobile_app/account/screens/account_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _wsSender = WsPositionSender(
      busId: "a5db4bd4-204a-4564-8487-1fc27d0c4444",
    ); // ← passe le bon UUID
    _wsSender.init();
  }

  @override
  void dispose() {
    _wsSender.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final GoRouter router = GoRouter(
      initialLocation: '/app',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
        GoRoute(path: '/', builder: (context, state) => const QrcodeScreen()),
        GoRoute(path: '/', builder: (context, state) => const AccountScreen()),
        GoRoute(
          path: '/app',
          builder: (context, state) => const CommonScaffold(),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'Tripiz Driver',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
      ),
      routerConfig: router,
    );
  }
}
