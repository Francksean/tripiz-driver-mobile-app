import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tripiz_driver_mobile_app/common/constants/app_colors.dart';
import 'package:tripiz_driver_mobile_app/common/constants/font_sizes.dart';
import 'package:tripiz_driver_mobile_app/common/utils/custom_date_utils.dart';
import 'package:tripiz_driver_mobile_app/home/cubits/home_cubit.dart';
import 'package:tripiz_driver_mobile_app/home/models/itinerary_model.dart';

class ItineraryCard extends StatefulWidget {
  final Itinerary itinerary;

  const ItineraryCard({super.key, required this.itinerary});

  @override
  State<ItineraryCard> createState() => _ItineraryCardState();
}

class _ItineraryCardState extends State<ItineraryCard> {
  bool _isUpdating = false;

  Color _statusColor(ItineraryStatus status) {
    switch (status) {
      case ItineraryStatus.enCours:
        return AppColors.secondary;
      case ItineraryStatus.termine:
        return const Color.fromRGBO(46, 163, 105, 1);
      case ItineraryStatus.aVenir:
        return AppColors.primary;
    }
  }

  String _statusLabel(ItineraryStatus status) {
    switch (status) {
      case ItineraryStatus.enCours:
        return "En cours";
      case ItineraryStatus.termine:
        return "Terminé";
      case ItineraryStatus.aVenir:
        return "À venir";
    }
  }

  IconData _statusIcon(ItineraryStatus status) {
    switch (status) {
      case ItineraryStatus.enCours:
        return Icons.directions_bus_filled_rounded;
      case ItineraryStatus.termine:
        return Icons.check_circle_rounded;
      case ItineraryStatus.aVenir:
        return Icons.schedule_rounded;
    }
  }

  (ItineraryStatus, String)? _nextAction(ItineraryStatus current) {
    switch (current) {
      case ItineraryStatus.aVenir:
        return (ItineraryStatus.enCours, "Démarrer le trajet");
      case ItineraryStatus.enCours:
        return (ItineraryStatus.termine, "Terminer le trajet");
      case ItineraryStatus.termine:
        return null;
    }
  }

  Future<void> _handleStatusChange(ItineraryStatus newStatus) async {
    setState(() => _isUpdating = true);

    final result = await context.read<HomeCubit>().updateTripStatus(
      widget.itinerary.id,
      newStatus,
    );

    if (!mounted) return;
    setState(() => _isUpdating = false);

    if (!result.success && result.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.red,
          content: Text(result.errorMessage!),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.itinerary.status;
    final color = _statusColor(status);
    final action = _nextAction(status);

    // Vérifie si un AUTRE trajet est déjà "en cours" pour désactiver
    // visuellement le bouton "Démarrer" de celui-ci.
    final homeState = context.watch<HomeCubit>().state;
    final anotherTripActive = homeState is HomeLoaded &&
        homeState.itineraries.any(
              (it) => it.id != widget.itinerary.id && it.status == ItineraryStatus.enCours,
        );
    final isBlocked = action != null &&
        action.$1 == ItineraryStatus.enCours &&
        anotherTripActive;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: AppColors.vantablack.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(_statusIcon(status), color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.itinerary.startPoint,
                            style: TextStyle(
                              fontSize: FontSizes.lowerBig,
                              fontWeight: FontWeight.bold,
                              color: AppColors.vantablack,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.border),
                        Expanded(
                          child: Text(
                            widget.itinerary.endPoint,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: FontSizes.lowerBig,
                              fontWeight: FontWeight.bold,
                              color: AppColors.vantablack,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 14, color: AppColors.black),
                        const SizedBox(width: 4),
                        Text(
                          CustomDateUtils.formatTime(widget.itinerary.departureTime),
                          style: TextStyle(fontSize: FontSizes.medium, color: AppColors.black),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.people_alt_rounded, size: 14, color: AppColors.black),
                        const SizedBox(width: 4),
                        Text(
                          "${widget.itinerary.passengerCount} passagers",
                          style: TextStyle(fontSize: FontSizes.medium, color: AppColors.black),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _statusLabel(status),
                      style: TextStyle(
                        fontSize: FontSizes.small,
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (action != null)
                SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: _isUpdating || isBlocked
                        ? null
                        : () => _handleStatusChange(action.$1),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isBlocked
                          ? AppColors.border
                          : _statusColor(action.$1),
                      foregroundColor: AppColors.white,
                      disabledBackgroundColor: AppColors.border,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isUpdating
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                        : Text(
                      action.$2,
                      style: TextStyle(
                        fontSize: FontSizes.medium,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}