import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tripiz_driver_mobile_app/home/models/itinerary_model.dart';
import 'package:tripiz_driver_mobile_app/home/repositories/itinerary_repository.dart';
import 'package:tripiz_driver_mobile_app/common/log/log.dart';

part 'trip_gate_state.dart';

/// Vérifie si un trajet "en cours" existe avant d'autoriser l'accès
/// au scanner de paiement — un chauffeur ne doit pouvoir encaisser
/// des paiements que pendant un trajet actif.
class TripGateCubit extends Cubit<TripGateState> {
  final ItineraryRepository _repository;

  TripGateCubit({ItineraryRepository? repository})
      : _repository = repository ?? ItineraryRepository(),
        super(TripGateLoading());

  Future<void> checkActiveTrip() async {
    emit(TripGateLoading());
    try {
      final itineraries = await _repository.getTodayItineraries();
      final activeTrips = itineraries.where((it) => it.status == ItineraryStatus.enCours);


      if (activeTrips.isEmpty) {
        Log.warning('Aucun trajet en cours — scanner QR bloqué');
        emit(TripGateBlocked());
      } else {
        Log.success('Trajet en cours détecté (${activeTrips.first.startPoint} → ${activeTrips.first.endPoint}) — scanner QR autorisé');
        emit(TripGateAllowed());
      }
    } catch (e) {
      Log.error('Impossible de vérifier les trajets du jour : $e');
      emit(TripGateError("Impossible de vérifier vos trajets. Réessayez."));
    }
  }
}