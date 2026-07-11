import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tripiz_driver_mobile_app/account/models/driver_profile_model.dart';
import 'package:tripiz_driver_mobile_app/account/repositories/driver_profile_repository.dart';
import 'package:tripiz_driver_mobile_app/common/dio/auth_service.dart';

part 'account_state.dart';

class AccountCubit extends Cubit<AccountState> {
  final DriverProfileRepository _repository;
  final AuthService _authService;

  AccountCubit({
    DriverProfileRepository? repository,
    AuthService? authService,
  })  : _repository = repository ?? DriverProfileRepository(),
        _authService = authService ?? AuthService.instance,
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

  Future<void> updateField({String? firstName, String? lastName, String? email, String? phone}) async {
    final current = state;
    if (current is! AccountLoaded) return;

    final updated = current.profile.copyWith(
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
    );

    emit(AccountLoading());
    try {
      final saved = await _repository.updateProfile(updated);
      emit(AccountLoaded(saved));
    } catch (e) {
      emit(AccountError("Erreur lors de la mise à jour"));
      emit(AccountLoaded(current.profile));
    }
  }

  /// Met à jour l'avatar localement (mise à jour optimiste). Pas d'appel
  /// réseau pour l'instant : aucun endpoint d'upload n'est documenté
  /// côté backend. À brancher dès qu'il existe (voir TODO repository).
  Future<void> updateAvatar(String path) async {
    final current = state;
    if (current is! AccountLoaded) return;

    final updated = current.profile.copyWith(avatarPath: path);
    emit(AccountLoaded(updated));
  }

  /// Déconnecte le chauffeur. Purement local : efface le token/session
  /// stockés. AuthService.notifyListeners() déclenche automatiquement
  /// la redirection go_router vers /login (voir main.dart : redirect).
  Future<void> logout() async {
    await _authService.logout();
  }
}