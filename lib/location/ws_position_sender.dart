import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

class WsPositionSender {
  final String busId;
  StompClient? _client;
  bool _connected = false;
  StreamSubscription<Position>? _positionSub;

  void Function(String message)? onError;

  WsPositionSender({required this.busId, this.onError});

  Future<void> init() async {
    try {
      _client = StompClient(
        config: StompConfig(
          url: 'wss://tripiz-api-production.up.railway.app/ws',
          onConnect: _onConnect,
          onWebSocketError: (error) {
            _connected = false;
            _reportError('Erreur WebSocket : $error');
          },
          onStompError: (frame) {
            _reportError('Erreur STOMP : ${frame.body}');
          },
          onDisconnect: (_) => _connected = false,
          reconnectDelay: const Duration(seconds: 5),
        ),
      );
      _client!.activate();

      // On démarre le flux GPS tout de suite, sans attendre la connexion WS.
      // _sendPosition n'enverra rien tant que _connected == false.
      await _startLocationStream();
    } catch (e) {
      _reportError('Impossible d\'initialiser le client STOMP : $e');
    }
  }

  void _reportError(String message) {
    print(message);
    onError?.call(message);
  }

  void _onConnect(StompFrame frame) {
    _connected = true;
    // Le flux GPS tourne déjà : dès la prochaine position, elle sera envoyée.
  }

  Future<void> _startLocationStream() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _reportError("GPS non activé !");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _reportError("Permission de localisation non accordée");
        return;
      }

      await _positionSub?.cancel();
      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen(
        _sendPosition,
        onError: (e) => _reportError('Erreur flux GPS : $e'),
      );
    } catch (e) {
      _reportError('Erreur démarrage localisation : $e');
    }
  }

  void _sendPosition(Position pos) {
    if (!_connected || _client == null) return;

    final data = {
      "busId": busId,
      "latitude": pos.latitude,
      "longitude": pos.longitude,
    };

    try {
      _client!.send(
        destination: '/app/bus/update',
        body: jsonEncode(data),
        headers: {'content-type': 'application/json'},
      );
      print("🛰 Position envoyée : $data");
    } catch (e) {
      _reportError("Erreur d'envoi de position : $e");
    }
  }

  Future<void> dispose() async {
    await _positionSub?.cancel();
    _client?.deactivate();
  }
}