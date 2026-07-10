import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

const String _kBaseUrl = 'https://tripiz-api-production-d0f2.up.railway.app';
const String _kLoginUrl = '$_kBaseUrl/auth/login';
const String _kMeUrl = '$_kBaseUrl/auth/me';

const _kAccessTokenKey = 'auth_access_token';
const _kRefreshTokenKey = 'auth_refresh_token';
const _kExpiresAtKey = 'auth_expires_at';
const _kDriverIdKey = 'auth_driver_id';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

/// Service d'authentification centralisé.
/// - Gère le login réel (POST /auth/login).
/// - Persiste la session (accessToken, refreshToken, expiresIn, driverId)
///   dans flutter_secure_storage, chiffré, pour survivre aux redémarrages.
/// - Notifie ses listeners (ChangeNotifier) à chaque changement d'état,
///   ce qui permet à go_router de rediriger automatiquement vers /login
///   ou /app selon l'état de connexion (voir refreshListenable).
class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  final _storage = const FlutterSecureStorage();

  String? _accessToken;
  String? _refreshToken;
  DateTime? _expiresAt;
  String? _driverId;

  bool _initialized = false;
  Future<void>? _restoring;

  bool get isAuthenticated => _accessToken != null;

  /// À appeler une fois avant runApp() pour restaurer une session existante
  /// depuis le stockage sécurisé (évite de redemander le login à chaque
  /// ouverture de l'app).
  Future<void> restoreSession() async {
    if (_initialized) return;
    _restoring ??= _restore();
    await _restoring;
  }

  Future<void> _restore() async {
    _accessToken = await _storage.read(key: _kAccessTokenKey);
    _refreshToken = await _storage.read(key: _kRefreshTokenKey);
    _driverId = await _storage.read(key: _kDriverIdKey);

    final expiresAtRaw = await _storage.read(key: _kExpiresAtKey);
    if (expiresAtRaw != null) {
      _expiresAt = DateTime.fromMillisecondsSinceEpoch(int.parse(expiresAtRaw));
    }

    // Si le token stocké est expiré, on ne le considère pas valide.
    if (_expiresAt != null && _expiresAt!.isBefore(DateTime.now())) {
      _accessToken = null;
    }

    _initialized = true;
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    final response = await http.post(
      Uri.parse(_kLoginUrl),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode != 200) {
      throw AuthException(_extractErrorMessage(response));
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final accessToken = json['accessToken'] as String?;
    final refreshToken = json['refreshToken'] as String?;
    final expiresIn = json['expiresIn'] as int?;

    if (accessToken == null) {
      throw AuthException('Réponse de connexion invalide.');
    }

    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _expiresAt = expiresIn != null
        ? DateTime.now().add(Duration(seconds: expiresIn))
        : null;

    await _storage.write(key: _kAccessTokenKey, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: _kRefreshTokenKey, value: refreshToken);
    }
    if (_expiresAt != null) {
      await _storage.write(
        key: _kExpiresAtKey,
        value: _expiresAt!.millisecondsSinceEpoch.toString(),
      );
    }

    // Résout et met en cache l'id chauffeur tout de suite pour éviter
    // un aller-retour réseau supplémentaire juste après le login.
    _driverId = await _fetchDriverId(accessToken);
    await _storage.write(key: _kDriverIdKey, value: _driverId!);

    _initialized = true;
    notifyListeners(); // déclenche la redirection go_router vers /app
  }

  Future<String> getToken() async {
    await restoreSession();
    if (_accessToken == null) {
      throw AuthException('Non authentifié.');
    }
    return _accessToken!;
  }

  Future<String> getDriverId() async {
    await restoreSession();
    if (_driverId != null) return _driverId!;
    final token = await getToken();
    _driverId = await _fetchDriverId(token);
    await _storage.write(key: _kDriverIdKey, value: _driverId!);
    return _driverId!;
  }

  Future<String> _fetchDriverId(String token) async {
    final response = await http.get(
      Uri.parse(_kMeUrl),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw AuthException('Impossible de récupérer le profil chauffeur.');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final userId = json['userId'] as String?;
    if (userId == null) {
      throw AuthException('userId introuvable dans /auth/me.');
    }
    return userId;
  }

  /// Déconnexion complète : efface le token en mémoire ET le stockage
  /// sécurisé, puis notifie — go_router redirige alors vers /login.
  Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    _expiresAt = null;
    _driverId = null;
    await _storage.deleteAll();
    notifyListeners();
  }

  String _extractErrorMessage(http.Response response) {
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json['message'] as String? ?? 'Identifiants incorrects.';
    } catch (_) {
      return response.statusCode == 401
          ? 'Identifiants incorrects.'
          : 'Erreur de connexion (${response.statusCode}).';
    }
  }
}