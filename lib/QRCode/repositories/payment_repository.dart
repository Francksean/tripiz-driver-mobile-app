import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:tripiz_driver_mobile_app/common/dio/dio_client.dart';
import 'package:tripiz_driver_mobile_app/common/log/log.dart';

class PaymentException implements Exception {
  final String message;
  PaymentException(this.message);
  @override
  String toString() => message;
}

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

  @override
  String toString() =>
      'QrPaymentData(ticketId: $ticketId, tripId: $tripId, walletId: $walletId, '
          'amount: $amount, timestamp: $timestamp, signature: ${signature.substring(0, signature.length > 8 ? 8 : signature.length)}...)';
}

class PaymentRepository {
  final Dio _dio = DioClient.instance.dio;

  QrPaymentData parseQrContent(String rawContent) {
    Log.info('Contenu brut scanné : $rawContent');
    try {
      final decoded = jsonDecode(rawContent);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('QR non structuré');
      }
      final data = QrPaymentData.fromJson(decoded);
      Log.success('QR décodé : $data');
      return data;
    } catch (e) {
      Log.error('Échec du décodage du QR : $e');
      throw PaymentException(
        "Ce QR code n'est pas un ticket de paiement valide.",
      );
    }
  }

  Future<void> processQrPayment(QrPaymentData data) async {
    Log.info('Envoi du paiement pour ticket ${data.ticketId} (${data.amount} FCFA)...');
    try {
      await _dio.post('/payments/process-qr-payment', data: data.toJson());
      Log.success('Paiement accepté pour ticket ${data.ticketId} — ${data.amount} FCFA débités du wallet ${data.walletId}');
    } on DioException catch (e) {
      final message = _mapError(e);
      Log.error('Paiement refusé pour ticket ${data.ticketId} : $message (status: ${e.response?.statusCode})');
      throw PaymentException(message);
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