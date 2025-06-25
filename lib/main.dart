import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tripiz_driver_mobile_app/QRCode/screens/qrcode_screen.dart';
import 'package:tripiz_driver_mobile_app/common/common_scaffold.dart';
import 'package:tripiz_driver_mobile_app/common/constants/app_colors.dart';
import 'package:tripiz_driver_mobile_app/home/screens/home_screen.dart';
import 'package:tripiz_driver_mobile_app/account/components/account_app_bar.dart';
import 'package:tripiz_driver_mobile_app/account/screens/account_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final GoRouter router = GoRouter(
      initialLocation: '/app',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
        GoRoute(path: '/', builder: (context, state) => const QrcodeScreen()),
        GoRoute(path: '/', builder: (context, state) => const AccountScreen()),
        GoRoute(path: '/app', builder: (context, state) => const CommonScaffold()),
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
