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
    Log.info('══════ SCAN QR ══════');
    Log.info('Longueur du contenu brut : ${rawContent.length} caractères');
    Log.info('Contenu brut scanné : $rawContent');

    // Le backend encode le QR sous forme compacte pipe-separated :
    // ticketId|tripId|walletId|amount|timestamp|signature
    // (pas en JSON, malgré l'exemple JSON documenté pour la réponse de
    // POST /payments/generate-qr-data — ce format compact est ce qui est
    // réellement encodé dans l'image du QR pour réduire sa densité).
    if (rawContent.contains('|')) {
      return _parsePipeSeparated(rawContent);
    }

    // Repli sur JSON au cas où le format change côté backend.
    return _parseJson(rawContent);
  }

  QrPaymentData _parsePipeSeparated(String rawContent) {
    final parts = rawContent.split('|');
    Log.info('Format détecté : pipe-separated (${parts.length} segments)');

    if (parts.length != 6) {
      Log.error('Nombre de segments inattendu : ${parts.length} (6 attendus)');
      throw PaymentException(
        "Ce QR code n'est pas un ticket de paiement valide.",
      );
    }

    try {
      final data = QrPaymentData(
        ticketId: parts[0],
        tripId: parts[1],
        walletId: parts[2],
        amount: double.parse(parts[3]),
        timestamp: int.parse(parts[4]),
        signature: parts[5],
      );
      Log.success('QR décodé avec succès :');
      Log.success('  ticketId  : ${data.ticketId}');
      Log.success('  tripId    : ${data.tripId}');
      Log.success('  walletId  : ${data.walletId}');
      Log.success('  amount    : ${data.amount} FCFA');
      Log.success('  timestamp : ${data.timestamp}');
      Log.success('  signature : ${data.signature}');
      return data;
    } catch (e) {
      Log.error('Échec du parsing pipe-separated : $e');
      throw PaymentException(
        "Ce QR code n'est pas un ticket de paiement valide.",
      );
    }
  }

  QrPaymentData _parseJson(String rawContent) {
    dynamic decoded;
    try {
      decoded = jsonDecode(rawContent);
    } catch (e) {
      Log.error('Le contenu scanné n\'est ni pipe-separated, ni du JSON valide : $e');
      throw PaymentException(
        "Ce QR code n'est pas un ticket de paiement valide.",
      );
    }

    if (decoded is! Map<String, dynamic>) {
      Log.error('Le JSON décodé n\'est pas un objet (type reçu : ${decoded.runtimeType})');
      throw PaymentException(
        "Ce QR code n'est pas un ticket de paiement valide.",
      );
    }

    Log.info('Clés présentes dans le JSON : ${decoded.keys.toList()}');
    decoded.forEach((key, value) {
      Log.info('  • $key = $value (${value.runtimeType})');
    });

    try {
      final data = QrPaymentData.fromJson(decoded);
      Log.success('QR décodé avec succès : $data');
      return data;
    } catch (e) {
      Log.error('Échec du mapping vers QrPaymentData : $e');
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