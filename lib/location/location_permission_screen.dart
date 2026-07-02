import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tripiz_driver_mobile_app/common/constants/app_colors.dart';

class LocationPermissionScreen extends StatefulWidget {
  final VoidCallback onGranted;

  const LocationPermissionScreen({super.key, required this.onGranted});

  @override
  State<LocationPermissionScreen> createState() =>
      _LocationPermissionScreenState();
}

enum _PermissionStep { checking, serviceDisabled, denied, deniedForever }

class _LocationPermissionScreenState extends State<LocationPermissionScreen> {
  _PermissionStep _step = _PermissionStep.checking;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _requestPermission());
  }

  Future<void> _requestPermission() async {
    setState(() => _step = _PermissionStep.checking);

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _step = _PermissionStep.serviceDisabled);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      widget.onGranted();
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _step = _PermissionStep.deniedForever);
      return;
    }

    setState(() => _step = _PermissionStep.denied);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Center(child: _buildContent()),
      ),
    );
  }

  Widget _buildContent() {
    switch (_step) {
      case _PermissionStep.checking:
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Vérification de la localisation..."),
          ],
        );

      case _PermissionStep.serviceDisabled:
        return _buildMessage(
          icon: Icons.location_off,
          title: "GPS désactivé",
          message:
          "Active le GPS de ton téléphone pour pouvoir démarrer un trajet.",
          buttonLabel: "Ouvrir les paramètres GPS",
          onPressed: () async {
            await Geolocator.openLocationSettings();
            _requestPermission();
          },
        );

      case _PermissionStep.denied:
        return _buildMessage(
          icon: Icons.location_disabled,
          title: "Permission refusée",
          message:
          "Tripiz Driver a besoin d'accéder à ta position pour transmettre la localisation du bus en temps réel.",
          buttonLabel: "Réessayer",
          onPressed: _requestPermission,
        );

      case _PermissionStep.deniedForever:
        return _buildMessage(
          icon: Icons.location_disabled,
          title: "Permission bloquée",
          message:
          "Tu as refusé définitivement l'accès à la localisation. Active-la manuellement dans les réglages de l'application.",
          buttonLabel: "Ouvrir les réglages de l'app",
          onPressed: () async {
            await Geolocator.openAppSettings();
            _requestPermission();
          },
        );
    }
  }

  Widget _buildMessage({
    required IconData icon,
    required String title,
    required String message,
    required String buttonLabel,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 64, color: AppColors.primary),
        const SizedBox(height: 20),
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Text(buttonLabel, style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}