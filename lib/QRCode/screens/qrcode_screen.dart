import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tripiz_driver_mobile_app/QRCode/components/qrcode_scanner.dart';

class QrcodeScreen extends StatefulWidget {
  const QrcodeScreen({super.key});

  @override
  State<QrcodeScreen> createState() => _QrcodeScreenState();
}

class _QrcodeScreenState extends State<QrcodeScreen> {
  String? scannedCode;

  void _handleScan(String code) async {
    setState(() {
      scannedCode = code;
    });

    // Affichage temporaire pour confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Code scanné : $code')),
    );

    // 👇 Exemple de données à envoyer (ajuste selon ce que contient ton code)
    final data = {
      "tripId": code, // ou extrait depuis le code QR si ce n’est qu’un ID
      "walletId": "94f94902-c724-47ca-85d7-529af32b4a64",
      "amount": 200
    };

    const String endpointUrl = 'https://tripiz-api-production.up.railway.app/transactions/spending'; // Remplace avec l'URL réelle

    try {
      final response = await http.post(
        endpointUrl as Uri,
        headers: {
          'Content-Type': 'application/json',
          // Ajoute un token si nécessaire :
          // 'Authorization': 'Bearer ton_token',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction envoyée avec succès ✅')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : ${response.statusCode} - ${response.body}')),
        );
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur réseau : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scanner de QR Code")),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: QrScannerWidget(onScanned: _handleScan),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                scannedCode != null ? 'Résultat : $scannedCode' : 'Aucun code scanné',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}