import 'package:tripiz_driver_mobile_app/account/models/driver_profile_model.dart';

class DriverProfileRepository {
  /// TODO: remplacer par un vrai appel API (GET /api/drivers/me)
  Future<DriverProfile> getProfile() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return DriverProfile(
      name: "Franck DJISSOU",
      email: "seandjissou@gmail.com",
      phone: "+237 675 32 18 36",
    );
  }

  /// TODO: remplacer par un vrai appel API (PATCH /api/drivers/me)
  Future<DriverProfile> updateProfile(DriverProfile profile) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return profile;
  }
}