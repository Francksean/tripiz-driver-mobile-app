import 'package:dio/dio.dart';
import '../log/log.dart'; // adapte le chemin selon l'emplacement réel de log.dart
import 'auth_service.dart';

class DioClient {
  // Instance privée de Dio
  static final DioClient _instance = DioClient._internal();
  late Dio dio;

  // Constructeur privé
  DioClient._internal() {
    dio = Dio(BaseOptions(
      baseUrl: 'https://tripiz-api-production-d0f2.up.railway.app',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Ajoute automatiquement le Bearer token à chaque requête,
        // sauf sur l'endpoint de login lui-même.
        if (!options.path.contains('/auth/login')) {
          try {
            final token = await AuthService.instance.getToken();
            options.headers['Authorization'] = 'Bearer $token';
          } catch (e) {
            Log.error('Impossible de récupérer le token pour la requête : $e');
          }
        }
        Log.info('Requête envoyée : ${options.uri}');
        Log.info('Payload envoyé : ${options.data}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        Log.success('Réponse reçue : ${response.data}');
        return handler.next(response);
      },
        onError: (DioException e, handler) {
          Log.error('Erreur : ${e.message}');
          Log.error('   → URL: ${e.requestOptions.method} ${e.requestOptions.uri}');
          Log.error('   → Réponse serveur: ${e.response?.data}');

          if (e.response?.statusCode == 401) {
            // Session invalide/expirée → déconnexion complète, ce qui déclenche
            // la redirection automatique vers /login via go_router.
            AuthService.instance.logout();
          }

          return handler.next(e);
        },
    ));
  }

  // Getter pour accéder à l'instance unique
  static DioClient get instance => _instance;
}