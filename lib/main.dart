import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tripiz_driver_mobile_app/auth/screens/login_screen.dart';
import 'package:tripiz_driver_mobile_app/common/common_scaffold.dart';
import 'package:tripiz_driver_mobile_app/common/constants/app_colors.dart';
import 'package:tripiz_driver_mobile_app/common/dio/auth_service.dart';
import 'package:tripiz_driver_mobile_app/location/location_permission_screen.dart';
import 'package:tripiz_driver_mobile_app/location/ws_position_sender.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Restaure une éventuelle session existante (token en stockage sécurisé)
  // avant de construire l'app, pour que le tout premier écran affiché
  // (login ou permission) soit le bon dès le lancement.
  await AuthService.instance.restoreSession();
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
      initialLocation: '/login',
      // Réévalue `redirect` à chaque changement d'état d'auth
      // (login réussi ou logout déclenché par un 401 dans DioClient).
      refreshListenable: AuthService.instance,
      redirect: (context, state) {
        final isAuthenticated = AuthService.instance.isAuthenticated;
        final isLoggingIn = state.matchedLocation == '/login';

        if (!isAuthenticated && !isLoggingIn) return '/login';
        if (isAuthenticated && isLoggingIn) return '/permission';
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
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
      debugShowCheckedModeBanner: false,
      title: 'Tripiz Driver',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
      ),
      routerConfig: _router,
    );
  }
}