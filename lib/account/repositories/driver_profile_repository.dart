import 'package:dio/dio.dart';
import 'package:tripiz_driver_mobile_app/account/models/driver_profile_model.dart';
import 'package:tripiz_driver_mobile_app/common/dio/dio_client.dart';

class DriverProfileRepository {
  final Dio _dio = DioClient.instance.dio;

  Future<DriverProfile> getProfile() async {
    try {
      final response = await _dio.get('/auth/me');
      return DriverProfile.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(
          'Échec du chargement du profil (${e.response?.statusCode}) : ${e.response?.data}');
    }
  }

  /// ⚠️ Aucun endpoint de mise à jour du profil n'est documenté côté
  /// backend pour l'instant (pas de PATCH /auth/me ou équivalent).
  /// En attendant, on renvoie simplement le profil modifié tel quel,
  /// sans persistance réelle — les changements seront perdus au
  /// prochain getProfile(). À remplacer dès que l'endpoint existe.
  Future<DriverProfile> updateProfile(DriverProfile profile) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return profile;
  }
}