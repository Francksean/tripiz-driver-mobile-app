import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:tripiz_driver_mobile_app/common/dio/dio_client.dart';

class PaymentException implements Exception {
  final String message;
  PaymentException(this.message);
  @override
  String toString() => message;
}

/// Données extraites du QR code généré côté passager.
/// Les champs correspondent exactement au corps attendu par
/// POST /payments/process-qr-payment.
class QrPaymentData {
  final String ticketId;
  final String tripId;
  final String walletId;
  final double amount;
  final int timestamp;
  final String signature;

  QrPaymentData({
    required this.ticketId,
    required this.tripId,
    required this.walletId,
    required this.amount,
    required this.timestamp,
    required this.signature,
  });

  factory QrPaymentData.fromJson(Map<String, dynamic> json) {
    return QrPaymentData(
      ticketId: json['ticketId'] as String,
      tripId: json['tripId'] as String,
      walletId: json['walletId'] as String,
      amount: (json['amount'] as num).toDouble(),
      timestamp: json['timestamp'] as int,
      signature: json['signature'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'ticketId': ticketId,
    'tripId': tripId,
    'walletId': walletId,
    'amount': amount,
    'timestamp': timestamp,
    'signature': signature,
  };
}

class PaymentRepository {
  final Dio _dio = DioClient.instance.dio;

  /// Parse le contenu brut scanné (chaîne JSON encodée dans le QR) en
  /// [QrPaymentData]. Lève une [PaymentException] si le QR n'a pas le
  /// bon format (code cassé, QR d'un autre type, etc.).
  QrPaymentData parseQrContent(String rawContent) {
    try {
      final decoded = jsonDecode(rawContent);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('QR non structuré');
      }
      return QrPaymentData.fromJson(decoded);
    } catch (_) {
      throw PaymentException(
        "Ce QR code n'est pas un ticket de paiement valide.",
      );
    }
  }

  Future<void> processQrPayment(QrPaymentData data) async {
    try {
      await _dio.post('/payments/process-qr-payment', data: data.toJson());
    } on DioException catch (e) {
      throw PaymentException(_mapError(e));
    }
  }

  String _mapError(DioException e) {
    final statusCode = e.response?.statusCode;
    final serverMessage = _extractServerMessage(e.response?.data);

    switch (statusCode) {
      case 400:
        return _mapBadRequest(serverMessage);
      case 401:
        return 'Session expirée. Reconnectez-vous.';
      case 404:
        return 'Ticket ou wallet introuvable.';
      default:
        return serverMessage ??
            'Erreur de paiement (${statusCode ?? "réseau"}).';
    }
  }

  /// Traduit les messages 400 documentés par le backend en messages
  /// utilisateur clairs, plutôt que d'afficher le texte technique brut.
  String _mapBadRequest(String? serverMessage) {
    if (serverMessage == null) return 'Paiement refusé.';
    final lower = serverMessage.toLowerCase();

    if (lower.contains('signature')) {
      return 'QR code invalide (signature incorrecte). Demandez au passager de le régénérer.';
    }
    if (lower.contains('qr code expired')) {
      return 'QR code expiré (validité 5 minutes). Demandez au passager d\'en générer un nouveau.';
    }
    if (lower.contains('used') || lower.contains('ticket already') || lower.contains('expired')) {
      return 'Ce ticket a déjà été utilisé ou n\'est plus valable.';
    }
    if (lower.contains('insufficient')) {
      return 'Solde insuffisant sur le wallet du passager.';
    }
    return serverMessage;
  }

  String? _extractServerMessage(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) {
      return data['message'] as String? ?? data['error'] as String?;
    }
    if (data is String) return data;
    return null;
  }
}