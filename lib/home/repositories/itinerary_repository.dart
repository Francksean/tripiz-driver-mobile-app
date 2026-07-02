import 'package:tripiz_driver_mobile_app/home/models/itinerary_model.dart';

class ItineraryRepository {
  /// TODO: remplacer par un vrai appel API une fois l'endpoint backend prêt
  /// ex: GET /api/drivers/{driverId}/itineraries/today
  Future<List<Itinerary>> getTodayItineraries() async {
    await Future.delayed(const Duration(seconds: 1)); // simule un chargement réseau

    return [
      Itinerary(
        id: "1",
        startPoint: "Bonanjo",
        endPoint: "Akwa",
        departureTime: DateTime.now().add(const Duration(hours: 1)),
        passengerCount: 12,
        status: ItineraryStatus.aVenir,
      ),
      Itinerary(
        id: "2",
        startPoint: "Bépanda",
        endPoint: "Bonabéri",
        departureTime: DateTime.now().add(const Duration(hours: 3)),
        passengerCount: 8,
        status: ItineraryStatus.aVenir,
      ),
    ];
  }
}