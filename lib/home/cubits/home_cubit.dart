import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tripiz_driver_mobile_app/home/models/itinerary_model.dart';
import 'package:tripiz_driver_mobile_app/home/repositories/itinerary_repository.dart';

part 'home_state.dart';

/// Résultat d'une tentative de changement de statut, avec un message
/// explicite en cas d'échec (règle métier ou erreur réseau).
class UpdateStatusResult {
  final bool success;
  final String? errorMessage;

  const UpdateStatusResult.success() : success = true, errorMessage = null;
  const UpdateStatusResult.failure(this.errorMessage) : success = false;
}

class HomeCubit extends Cubit<HomeState> {
  final ItineraryRepository _repository;

  HomeCubit({ItineraryRepository? repository})
      : _repository = repository ?? ItineraryRepository(),
        super(HomeInitial());

  Future<void> loadTodayItineraries() async {
    emit(HomeLoading());
    try {
      final itineraries = await _repository.getTodayItineraries();
      emit(HomeLoaded(itineraries));
    } catch (e) {
      emit(HomeError("Erreur lors du chargement des itinéraires"));
    }
  }

  Future<UpdateStatusResult> updateTripStatus(
      String tripId,
      ItineraryStatus newStatus,
      ) async {
    final currentState = state;
    if (currentState is! HomeLoaded) {
      return const UpdateStatusResult.failure("Liste non chargée.");
    }

    final previousItineraries = currentState.itineraries;
    final previousItinerary = previousItineraries.firstWhere((it) => it.id == tripId);

    // Règle métier : un seul trajet "En cours" à la fois. Si on tente de
    // démarrer un trajet alors qu'un autre est déjà en cours, on bloque
    // avant même d'appeler le backend.
    if (newStatus == ItineraryStatus.enCours) {
      final activeTrip = previousItineraries.where(
            (it) => it.id != tripId && it.status == ItineraryStatus.enCours,
      );
      if (activeTrip.isNotEmpty) {
        final active = activeTrip.first;
        return UpdateStatusResult.failure(
          "Terminez d'abord le trajet ${active.startPoint} → ${active.endPoint} avant d'en démarrer un autre.",
        );
      }
    }

    final updatedItineraries = previousItineraries.map((it) {
      if (it.id != tripId) return it;
      return Itinerary(
        id: it.id,
        startPoint: it.startPoint,
        endPoint: it.endPoint,
        departureTime: it.departureTime,
        passengerCount: it.passengerCount,
        status: newStatus,
      );
    }).toList();

    // Mise à jour optimiste : l'UI change immédiatement.
    emit(HomeLoaded(updatedItineraries));

    try {
      await _repository.updateTripStatus(tripId, newStatus);
      return const UpdateStatusResult.success();
    } catch (e) {
      // Échec : on restaure l'ancien statut.
      final rolledBack = updatedItineraries.map((it) {
        return it.id == tripId ? previousItinerary : it;
      }).toList();
      emit(HomeLoaded(rolledBack));
      return const UpdateStatusResult.failure(
        "Échec de la mise à jour du statut. Réessayez.",
      );
    }
  }
}