import 'package:dio/dio.dart';
import 'package:tripiz_driver_mobile_app/common/dio/dio_client.dart';
import 'package:tripiz_driver_mobile_app/home/models/itinerary_model.dart';

class ItineraryRepository {
  final Dio _dio = DioClient.instance.dio;

  Future<List<Itinerary>> getTodayItineraries() async {
    try {
      final response = await _dio.get('/trip/admin/driver/today');

      final List<dynamic> data = response.data as List<dynamic>;

      return data
          .map((json) => _mapTripToItinerary(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        // Endpoint protégé par Bearer token (voir doc §5 : auth non
        // encore intégrée côté app). L'appel échouera tant que ce n'est
        // pas branché.
        throw Exception('Non authentifié : jeton manquant ou invalide.');
      }
      rethrow;
    }
  }

  Itinerary _mapTripToItinerary(Map<String, dynamic> json) {
    final tripId = json['trip_id'] as String;
    final itineraryId = json['itinerary_id'] as String?;

    return Itinerary(
      id: tripId,
      // itinerary_id seul ne donne pas les noms de stations
      // (GET /itinerary/{id} pas encore branché, voir doc §5).
      // On affiche l'itinerary_id tronqué en attendant.
      startPoint: _shortId(itineraryId),
      endPoint: '—',
      departureTime: _parseDepartureTime(
        json['schedule_departure'] as String?,
        json['trip_date'] as String?,
      ),
      passengerCount: json['passenger_count'] as int? ?? 0,
      status: _mapStatus(json['trip_status'] as String?),
    );
  }

  String _shortId(String? id) {
    if (id == null || id.isEmpty) return '—';
    return id.length > 8 ? id.substring(0, 8) : id;
  }

  DateTime _parseDepartureTime(String? scheduleDeparture, String? tripDate) {
    // schedule_departure est typé "string" côté swagger, sans format
    // garanti. On tente un parse ISO, sinon fallback sur trip_date,
    // sinon "maintenant".
    if (scheduleDeparture != null) {
      final parsed = DateTime.tryParse(scheduleDeparture);
      if (parsed != null) return parsed;
    }
    if (tripDate != null) {
      final parsed = DateTime.tryParse(tripDate);
      if (parsed != null) return parsed;
    }
    return DateTime.now();
  }

  ItineraryStatus _mapStatus(String? tripStatus) {
    // ⚠️ Seul "PROGRAMME" est confirmé par le swagger. Les valeurs pour
    // enCours/termine sont des suppositions (EN_COURS / TERMINE) —
    // à corriger dès que tu as la liste exacte de l'enum trip_status
    // côté backend (endpoint PATCH /trip/admin/driver/{tripId}/status
    // laisse deviner qu'il y en a au moins 2-3 autres).
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
}