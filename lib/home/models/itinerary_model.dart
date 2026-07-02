enum ItineraryStatus { aVenir, enCours, termine }

class Itinerary {
  final String id;
  final String startPoint;
  final String endPoint;
  final DateTime departureTime;
  final int passengerCount;
  final ItineraryStatus status;

  Itinerary({
    required this.id,
    required this.startPoint,
    required this.endPoint,
    required this.departureTime,
    required this.passengerCount,
    required this.status,
  });

  factory Itinerary.fromJson(Map<String, dynamic> json) {
    return Itinerary(
      id: json['id'] as String,
      startPoint: json['startPoint'] as String,
      endPoint: json['endPoint'] as String,
      departureTime: DateTime.parse(json['departureTime'] as String),
      passengerCount: json['passengerCount'] as int? ?? 0,
      status: ItineraryStatus.values.firstWhere(
            (e) => e.name == json['status'],
        orElse: () => ItineraryStatus.aVenir,
      ),
    );
  }
}