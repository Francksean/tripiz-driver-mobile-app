import 'dart:async';
import 'dart:convert';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../common/dio/auth_service.dart';
import '../common/log/log.dart';

typedef _Log = Log;

/// Utilitaire de logs colorés (ANSI) pour repérer facilement
/// les erreurs et succès au milieu de logs nombreux.

class WsPositionSender {
  StompClient? _client;
  bool _connected = false;
  String? _busId;

  final Location _location = Location();
  StreamSubscription<LocationData>? _positionSub;
  LocationData? _lastPosition;
  Timer? _sendTimer;

  void Function(String message)? onError;

  WsPositionSender({this.onError});

  Future<void> init() async {
    try {
      _Log.info('Récupération du token via AuthService...');
      final token = await AuthService.instance.getToken();
      _Log.success('Token récupéré');

      _Log.info('Récupération de l\'id chauffeur via AuthService...');
      _busId = await AuthService.instance.getDriverId();
      _Log.success('Id chauffeur récupéré : $_busId');

      _client = StompClient(
        config: StompConfig(
          url: 'wss://tripiz-api-production-d0f2.up.railway.app:443/ws',
          onConnect: _onConnect,
          onWebSocketError: (error) {
            _connected = false;
            _reportError('Erreur WebSocket : $error');
          },
          onStompError: (frame) {
            _reportError('Erreur STOMP : ${frame.body}');
          },
          onDisconnect: (_) {
            _connected = false;
            _Log.warning('Déconnecté du serveur STOMP');
          },
          reconnectDelay: const Duration(seconds: 1),
          stompConnectHeaders: {'Authorization': 'Bearer $token'},
          webSocketConnectHeaders: {'Authorization': 'Bearer $token'},
        ),
      );
      _client!.activate();

      // On démarre le flux GPS tout de suite, sans attendre la connexion WS.
      await _startLocationStream();
    } catch (e) {
      _reportError('Impossible d\'initialiser le client STOMP : $e');
    }
  }

  void _reportError(String message) {
    _Log.error(message);
    onError?.call(message);
  }

  void _onConnect(StompFrame frame) {
    _connected = true;
    _Log.success('Connecté au serveur STOMP');
    _startPeriodicSend();
  }

  void _startPeriodicSend() {
    _sendTimer?.cancel();
    _sendTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_lastPosition != null) {
        _sendPosition(_lastPosition!);
      } else {
        _Log.warning('Aucune position GPS disponible pour le moment');
      }
    });
  }

  Future<void> _startLocationStream() async {
    try {
      _Log.info('Démarrage du flux de localisation...');

      // --- Étapes strictement identiques au repository qui fonctionne ---
      // On garde ça minimal et on récupère une position AVANT de faire
      // quoi que ce soit d'autre (notification, foreground service...).
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          _reportError('Le service de localisation est désactivé');
          return;
        }
      }

      PermissionStatus permissionStatus = await _location.hasPermission();
      if (permissionStatus == PermissionStatus.denied) {
        permissionStatus = await _location.requestPermission();
      }
      if (permissionStatus == PermissionStatus.denied ||
          permissionStatus == PermissionStatus.deniedForever) {
        _reportError('Les permissions de localisation sont refusées');
        return;
      }

      // Précision + pas de filtre de distance (envoi cadencé par le Timer).
      await _location.changeSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      );

      // Position initiale récupérée tout de suite, comme dans le repository.
      _Log.info('Récupération de la position initiale...');
      final LocationData initialData = await _location.getLocation();
      _Log.success(
        'Position initiale obtenue : ${initialData.latitude}, ${initialData.longitude}',
      );
      _lastPosition = initialData;

      await _positionSub?.cancel();
      _positionSub = _location.onLocationChanged.listen(
            (pos) => _lastPosition = pos,
        onError: (e) => _reportError('Erreur flux GPS : $e'),
      );

      _Log.success('Flux GPS démarré');

      // --- Configuration "arrière-plan" séparée, non bloquante ---
      // On la lance après coup, dans son propre try/catch, pour qu'une
      // erreur ici (notification, foreground service...) ne puisse plus
      // empêcher l'obtention de la position.
      unawaited(_setupBackgroundMode(permissionStatus));
    } catch (e) {
      _reportError('Erreur démarrage localisation : $e');
    }
  }

  Future<void> _setupBackgroundMode(PermissionStatus permissionStatus) async {
    try {
      if (permissionStatus == PermissionStatus.grantedLimited) {
        _Log.warning(
          'Permission "en cours d\'utilisation" uniquement : le suivi '
              's\'arrêtera écran éteint / app en arrière-plan. L\'utilisateur '
              'doit activer "Toujours autoriser" dans les réglages système.',
        );
      }

      // Android 13+ (API 33) : nécessaire pour afficher la notification
      // persistante du foreground service.
      final notifStatus = await ph.Permission.notification.request();
      _Log.info('Permission notification : $notifStatus');

      await _location.changeNotificationOptions(
        title: 'Suivi de position actif',
        subtitle: 'Envoi de votre position en cours',
        onTapBringToFront: true,
      );

      if (permissionStatus == PermissionStatus.granted) {
        final bgEnabled = await _location.enableBackgroundMode(enable: true);
        _Log.info('Mode arrière-plan activé : $bgEnabled');
      }
    } catch (e) {
      // On log seulement : le flux de position principal continue même
      // si le mode arrière-plan / la notification échoue.
      _Log.warning('Configuration arrière-plan échouée (non bloquant) : $e');
    }
  }

  void _sendPosition(LocationData pos) {
    if (!_connected || _client == null || _busId == null) return;

    final data = {
      'driverId': _busId,
      'latitude': pos.latitude,
      'longitude': pos.longitude,
      'type': 'UPDATE',
      'heading': pos.heading,
    };

    try {
      _client!.send(
        destination: '/app/bus/update',
        body: jsonEncode(data),
        headers: {'content-type': 'application/json'},
      );
      _Log.success('Position envoyée : $data');
    } catch (e) {
      _reportError("Erreur d'envoi de position : $e");
    }
  }

  Future<void> dispose() async {
    await _positionSub?.cancel();
    _sendTimer?.cancel();
    await _location.enableBackgroundMode(enable: false);
    _client?.deactivate();
    _Log.info('WsPositionSender arrêté');
  }
}