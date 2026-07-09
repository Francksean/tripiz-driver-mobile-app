import 'dart:convert';
import 'package:http/http.dart' as http;

/// ⚠️ TEMPORAIRE — identifiants codés en dur en attendant un vrai écran de login.
const String _kTempEmail = 'mballa@tripiz.com';
const String _kTempPassword = 'admin123';
const String _kLoginUrl =
    'https://tripiz-api-production-d0f2.up.railway.app/auth/login';
const String _kMeUrl =
    'https://tripiz-api-production-d0f2.up.railway.app/auth/me';

/// Service d'authentification centralisé : récupère et met en cache
/// le JWT et l'id du chauffeur connecté, pour être réutilisé partout
/// (DioClient, WsPositionSender, etc.) au lieu de logins répétés.
class AuthService {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  String? _token;
  String? _driverId;
  Future<String>? _loginInFlight; // évite les logins concurrents

  Future<String> getToken() async {
    if (_token != null) return _token!;
    // Si un login est déjà en cours, on attend son résultat au lieu
    // d'en démarrer un deuxième en parallèle.
    _loginInFlight ??= _login();
    final token = await _loginInFlight!;
    _loginInFlight = null;
    return token;
  }

  Future<String> getDriverId() async {
    if (_driverId != null) return _driverId!;
    final token = await getToken();
    _driverId = await _fetchDriverId(token);
    return _driverId!;
  }

  Future<String> _login() async {
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

    if (response.statusCode != 200) {
      throw Exception(
          'Échec du login (${response.statusCode}) : ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final token = json['accessToken'] as String?;
    if (token == null) {
      throw Exception('accessToken introuvable : ${response.body}');
    }
    _token = token;
    return token;
  }

  Future<String> _fetchDriverId(String token) async {
    final response = await http.get(
      Uri.parse(_kMeUrl),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Échec /auth/me (${response.statusCode}) : ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final userId = json['userId'] as String?;
    if (userId == null) {
      throw Exception('userId introuvable : ${response.body}');
    }
    return userId;
  }

  /// À appeler en cas de 401 pour forcer un nouveau login.
  void invalidate() {
    _token = null;
    _driverId = null;
  }
}