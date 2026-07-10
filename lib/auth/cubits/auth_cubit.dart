import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tripiz_driver_mobile_app/common/dio/auth_service.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthService _authService;

  AuthCubit({AuthService? authService})
      : _authService = authService ?? AuthService.instance,
        super(AuthInitial());

  Future<void> login(String username, String password) async {
    emit(AuthLoading());
    try {
      await _authService.login(username.trim(), password);
      emit(AuthSuccess());
    } on AuthException catch (e) {
      emit(AuthFailure(e.message));
    } catch (e) {
      emit(AuthFailure('Une erreur est survenue. Réessayez.'));
    }
  }
}