import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tripiz_driver_mobile_app/QRCode/repositories/payment_repository.dart';

part 'payment_state.dart';

class PaymentCubit extends Cubit<PaymentState> {
  final PaymentRepository _repository;

  PaymentCubit({PaymentRepository? repository})
      : _repository = repository ?? PaymentRepository(),
        super(PaymentInitial());

  Future<void> payFromQrContent(String rawContent) async {
    emit(PaymentLoading());
    try {
      final data = _repository.parseQrContent(rawContent);
      await _repository.processQrPayment(data);
      emit(PaymentSuccess(data));
    } on PaymentException catch (e) {
      emit(PaymentFailure(e.message));
    } catch (e) {
      emit(PaymentFailure('Erreur inattendue. Réessayez.'));
    }
  }

  /// Repasse en état initial pour permettre un nouveau scan.
  void reset() => emit(PaymentInitial());
}