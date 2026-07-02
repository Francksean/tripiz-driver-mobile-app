import 'package:flutter/material.dart';
import 'package:tripiz_driver_mobile_app/common/constants/app_colors.dart';
import 'package:tripiz_driver_mobile_app/common/constants/font_sizes.dart';
import 'package:tripiz_driver_mobile_app/common/utils/custom_date_utils.dart';
import 'package:tripiz_driver_mobile_app/home/models/itinerary_model.dart';

class ItineraryCard extends StatelessWidget {
  final Itinerary itinerary;

  const ItineraryCard({super.key, required this.itinerary});

  Color _statusColor() {
    switch (itinerary.status) {
      case ItineraryStatus.enCours:
        return Colors.orange;
      case ItineraryStatus.termine:
        return Colors.green;
      case ItineraryStatus.aVenir:
        return AppColors.primary;
    }
  }

  String _statusLabel() {
    switch (itinerary.status) {
      case ItineraryStatus.enCours:
        return "En cours";
      case ItineraryStatus.termine:
        return "Terminé";
      case ItineraryStatus.aVenir:
        return "À venir";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.directions_bus, color: AppColors.primary),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${itinerary.startPoint} → ${itinerary.endPoint}",
                  style: TextStyle(
                    fontSize: FontSizes.medium,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${CustomDateUtils.formatTime(itinerary.departureTime)} · ${itinerary.passengerCount} passagers",
                  style: TextStyle(
                    fontSize: FontSizes.small,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _statusColor().withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _statusLabel(),
              style: TextStyle(
                fontSize: FontSizes.small,
                color: _statusColor(),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}