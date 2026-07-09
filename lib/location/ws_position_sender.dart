import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:stomp_dart_client/stomp_dart_client.dart';

/// ⚠️ SOLUTION TEMPORAIRE — à supprimer dès qu'un vrai écran de connexion existe.
/// Identifiants codés en dur pour avancer sans page de login.
const String _kTempEmail = 'mballa@tripiz.com';
const String _kTempPassword = 'admin123';

/// Adaptez cette URL à votre vrai endpoint de login Spring Security.
const String _kLoginUrl =
    'https://tripiz-api-production-d0f2.up.railway.app/auth/login';

/// Endpoint retournant les infos de l'utilisateur authentifié (dont son id).
const String _kMeUrl =
    'https://tripiz-api-production-d0f2.up.railway.app/auth/me';

/// Appelle l'endpoint de login et retourne le token JWT (accessToken).
Future<String> _fetchTempJwtToken() async {
  _Log.info('POST $_kLoginUrl avec username="$_kTempEmail"');

  final response = await http.post(
    Uri.parse(_kLoginUrl),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    body: jsonEncode({
      'username': _kTempEmail,
      'password': _kTempPassword,
    }),
  );

  _Log.info('Réponse login : ${response.statusCode} — body="${response.body}"');

  if (response.statusCode != 200) {
    throw Exception(
        'Échec du login temporaire (${response.statusCode}) : ${response.body.isEmpty ? "(réponse vide)" : response.body}');
  }

  final json = jsonDecode(response.body) as Map<String, dynamic>;
  final token = json['accessToken'] as String?;
  if (token == null) {
    throw Exception('accessToken introuvable dans la réponse de login : ${response.body}');
  }
  return token;
}

/// Récupère l'id du chauffeur connecté via GET /auth/me (champ "userId").
Future<String> _fetchDriverId(String token) async {
  _Log.info('GET $_kMeUrl');

  final response = await http.get(
    Uri.parse(_kMeUrl),
    headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  _Log.info('Réponse /auth/me : ${response.statusCode} — body="${response.body}"');

  if (response.statusCode != 200) {
    throw Exception(
        'Échec de récupération du profil (${response.statusCode}) : ${response.body.isEmpty ? "(réponse vide)" : response.body}');
  }

  final json = jsonDecode(response.body) as Map<String, dynamic>;
  final userId = json['userId'] as String?;
  if (userId == null) {
    throw Exception('userId introuvable dans la réponse de /auth/me : ${response.body}');
  }
  return userId;
}

/// Utilitaire de logs colorés (ANSI) pour repérer facilement
/// les erreurs et succès au milieu de logs nombreux.
class _Log {
  static const _reset = '\x1B[0m';
  static const _red = '\x1B[31m';
  static const _green = '\x1B[32m';
  static const _yellow = '\x1B[33m';
  static const _cyan = '\x1B[36m';

  static void error(String msg) => print('$_red🔴 ERREUR: $msg$_reset');
  static void success(String msg) => print('$_green✅ SUCCÈS: $msg$_reset');
  static void warning(String msg) => print('$_yellow⚠️  $msg$_reset');
  static void info(String msg) => print('$_cyan ℹ️  $msg$_reset');
}

class WsPositionSender {
  // busId n'est plus imposé au constructeur : il est résolu en interne
  // via /auth/me (champ "userId") juste après le login temporaire.
  String? _busId;
  StompClient? _client;
  bool _connected = false;
  StreamSubscription<Position>? _positionSub;
  Position? _lastPosition;
  Timer? _sendTimer;

  void Function(String message)? onError;

  WsPositionSender({this.onError});

  Future<void> init() async {
    try {
      // ⚠️ TEMPORAIRE : récupère un JWT via login codé en dur, en attendant
      // un véritable écran de connexion dans l'application.
      _Log.info('Récupération du token JWT temporaire...');
      final token = await _fetchTempJwtToken();
      _Log.success('Token JWT récupéré');

      // Récupère l'id du chauffeur connecté pour l'utiliser comme busId.
      _Log.info('Récupération de l\'id chauffeur via /auth/me...');
      _busId = await _fetchDriverId(token);
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
          reconnectDelay: const Duration(seconds: 5),
          // Le token est envoyé dans les headers STOMP CONNECT.
          stompConnectHeaders: {'Authorization': 'Bearer $token'},
          // Certains backends exigent aussi le header au niveau du handshake WS.
          webSocketConnectHeaders: {'Authorization': 'Bearer $token'},
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
    _Log.error(message);
    onError?.call(message);
  }

  void _onConnect(StompFrame frame) {
    _connected = true;
    _Log.success('Connecté au serveur STOMP');
    _startPeriodicSend();
  }

  /// Envoie la dernière position connue toutes les 5 secondes,
  /// indépendamment des déplacements réels (contrairement au flux GPS
  /// qui ne déclenche qu'après distanceFilter mètres parcourus).
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
          distanceFilter: 0, // on veut toutes les positions, l'envoi est cadencé par le Timer
        ),
      ).listen(
            (pos) => _lastPosition = pos,
        onError: (e) => _reportError('Erreur flux GPS : $e'),
      );

      _Log.info('Flux GPS démarré');
    } catch (e) {
      _reportError('Erreur démarrage localisation : $e');
    }
  }

  void _sendPosition(Position pos) {
    if (!_connected || _client == null || _busId == null) return;

    final data = {
      "busId": _busId,
      "latitude": pos.latitude,
      "longitude": pos.longitude,
      "type": "UPDATE",
      "heading": pos.heading
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
    _client?.deactivate();
    _Log.info('WsPositionSender arrêté');
  }
}