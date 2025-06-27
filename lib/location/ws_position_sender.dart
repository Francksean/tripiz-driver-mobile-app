import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';


class WsPositionSender {
  final String busId;
  late final StompClient _client;
  bool _connected = false;

  WsPositionSender({required this.busId});

  void init() async {
    _client = StompClient(
      config: StompConfig(
        url: 'ws://tripiz-api-production.up.railway.app/ws',
        onConnect: _onConnect,
        onWebSocketError: (error) => print('WebSocket error: $error'),
        onDisconnect: (_) => _connected = false,
        reconnectDelay: const Duration(seconds: 5),
      ),
    );
    _client.activate();
  }

  void _onConnect(StompFrame frame) {
    _connected = true;
    _startLocationStream();
  }

  void _startLocationStream() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("GPS non activé !");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        print("Permission refusée");
        return;
      }
    }

    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // en mètres
      ),
    ).listen((Position position) {
      _sendPosition(position);
    });
  }

  void _sendPosition(Position pos) {
    if (!_connected) return;

    final data = {
      "busId": busId,
      "latitude": pos.latitude,
      "longitude": pos.longitude,
    };

    _client.send(
      destination: '/app/bus/update',
      body: jsonEncode(data),
      headers: {'content-type': 'application/json'},
    );

    print("🛰 Position envoyée : $data");
  }

  void dispose() {
    _client.deactivate();
  }
}