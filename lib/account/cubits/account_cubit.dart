import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tripiz_driver_mobile_app/account/models/driver_profile_model.dart';
import 'package:tripiz_driver_mobile_app/account/repositories/driver_profile_repository.dart';

part 'account_state.dart';

class AccountCubit extends Cubit<AccountState> {
  final DriverProfileRepository _repository;

  AccountCubit({DriverProfileRepository? repository})
      : _repository = repository ?? DriverProfileRepository(),
        super(AccountInitial());

  Future<void> loadProfile() async {
    emit(AccountLoading());
    try {
      final profile = await _repository.getProfile();
      emit(AccountLoaded(profile));
    } catch (e) {
      emit(AccountError("Erreur lors du chargement du profil"));
    }
  }

  Future<void> updateField({String? name, String? email, String? phone}) async {
    final current = state;
    if (current is! AccountLoaded) return;

    final updated = current.profile.copyWith(
      name: name,
      email: email,
      phone: phone,
    );

    emit(AccountLoading());
    try {
      final saved = await _repository.updateProfile(updated);
      emit(AccountLoaded(saved));
    } catch (e) {
      emit(AccountError("Erreur lors de la mise à jour"));
      emit(AccountLoaded(current.profile)); // on revient à l'état précédent
    }
  }

  Future<void> updateAvatar(String path) async {
    final current = state;
    if (current is! AccountLoaded) return;

    final updated = current.profile.copyWith(avatarPath: path);
    emit(AccountLoaded(updated));
    // TODO: uploader l'image vers le backend une fois prêt
  }
}