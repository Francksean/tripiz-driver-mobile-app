import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tripiz_driver_mobile_app/common/constants/app_colors.dart';
import 'package:tripiz_driver_mobile_app/common/constants/font_sizes.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final Map<String, bool> _preferences = {
    "Nouveaux trajets assignés": true,
    "Paiements reçus": true,
    "Rappels de départ": true,
    "Messages de l'équipe Tripiz": false,
    "Offres et actualités": false,
  };

  final Map<String, IconData> _icons = {
    "Nouveaux trajets assignés": Icons.route_rounded,
    "Paiements reçus": Icons.payments_rounded,
    "Rappels de départ": Icons.alarm_rounded,
    "Messages de l'équipe Tripiz": Icons.chat_bubble_rounded,
    "Offres et actualités": Icons.campaign_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.vantablack, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          "Notifications",
          style: TextStyle(
            color: AppColors.vantablack,
            fontSize: FontSizes.lowerBig,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          Text(
            "Choisissez les notifications que vous souhaitez recevoir.",
            style: TextStyle(fontSize: FontSizes.medium, color: AppColors.black),
          ),
          const SizedBox(height: 20),
          ..._preferences.keys.map((key) => _buildToggleTile(key)),
        ],
      ),
    );
  }

  Widget _buildToggleTile(String label) {
    final isEnabled = _preferences[label]!;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isEnabled ? AppColors.primary.withOpacity(0.12) : AppColors.border.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _icons[label],
              size: 18,
              color: isEnabled ? AppColors.primary : AppColors.black.withOpacity(0.4),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: FontSizes.medium, color: AppColors.vantablack),
            ),
          ),
          Switch(
            value: isEnabled,
            activeColor: AppColors.primary,
            onChanged: (value) => setState(() => _preferences[label] = value),
          ),
        ],
      ),
    );
  }
}