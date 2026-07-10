import 'package:dio/dio.dart';
import 'package:tripiz_driver_mobile_app/common/dio/dio_client.dart';
import 'package:tripiz_driver_mobile_app/home/models/itinerary_model.dart';

class ItineraryRepository {
  final Dio _dio = DioClient.instance.dio;

  Future<List<Itinerary>> getTodayItineraries() async {
    try {
      final response = await _dio.get('/trip/driver/today');

      final List<dynamic> data = response.data as List<dynamic>;

      return data
          .map((json) => _mapTripToItinerary(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Non authentifié : jeton manquant ou invalide.');
      }
      rethrow;
    }
  }

  /// Change le statut d'un trajet côté backend.
  /// [tripId] : l'id du trajet (Itinerary.id)
  /// [status] : le nouveau statut, au format enum app (ItineraryStatus)
  Future<void> updateTripStatus(String tripId, ItineraryStatus status) async {
    try {
      await _dio.patch(
        '/trip/driver/$tripId/status',
        data: {'tripStatus': _statusToBackend(status)},
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Non authentifié : jeton manquant ou invalide.');
      }
      throw Exception(
          'Échec de mise à jour du statut (${e.response?.statusCode}) : ${e.response?.data}');
    }
  }

  Itinerary _mapTripToItinerary(Map<String, dynamic> json) {
    final tripId = json['trip_id'] as String;
    final itinerary = json['itinerary'] as Map<String, dynamic>?;

    final itineraryName = itinerary?['itinerary_name'] as String?;
    final points = _splitItineraryName(itineraryName);

    return Itinerary(
      id: tripId,
      startPoint: points.$1,
      endPoint: points.$2,
      departureTime: _parseDepartureTime(
        json['schedule_departure'] as String?,
        json['trip_date'] as String?,
      ),
      passengerCount: json['passenger_count'] as int? ?? 0,
      status: _mapStatus(json['trip_status'] as String?),
    );
  }

  /// "Bonanjo - Yassa" → ("Bonanjo", "Yassa").
  /// Si le format ne correspond pas (pas de " - "), on retombe sur le nom
  /// complet pour startPoint et '—' pour endPoint.
  (String, String) _splitItineraryName(String? name) {
    if (name == null || name.isEmpty) return ('—', '—');
    final parts = name.split(' - ');
    if (parts.length == 2) {
      return (parts[0].trim(), parts[1].trim());
    }
    return (name, '—');
  }

  DateTime _parseDepartureTime(String? scheduleDeparture, String? tripDate) {
    // schedule_departure semble être une heure seule ("14:08:00"), pas une
    // date complète — on la combine avec trip_date si possible.
    if (scheduleDeparture != null && tripDate != null) {
      final combined = DateTime.tryParse('${tripDate}T$scheduleDeparture');
      if (combined != null) return combined;
    }
    if (tripDate != null) {
      final parsed = DateTime.tryParse(tripDate);
      if (parsed != null) return parsed;
    }
    return DateTime.now();
  }

  ItineraryStatus _mapStatus(String? tripStatus) {
    switch (tripStatus) {
      case 'PROGRAMME':
        return ItineraryStatus.aVenir;
      case 'EN_COURS':
        return ItineraryStatus.enCours;
      case 'TERMINE':
        return ItineraryStatus.termine;
      default:
        return ItineraryStatus.aVenir;
    }
  }

  String _statusToBackend(ItineraryStatus status) {
    switch (status) {
      case ItineraryStatus.aVenir:
        return 'PROGRAMME';
      case ItineraryStatus.enCours:
        return 'EN_COURS';
      case ItineraryStatus.termine:
        return 'TERMINE';
    }
  }
}