import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:tripiz_driver_mobile_app/QRCode/components/qrcode_scanner.dart';

class QrcodeScreen extends StatefulWidget {
  const QrcodeScreen({super.key});

  @override
  State<QrcodeScreen> createState() => _QrcodeScreenState();
}

class _QrcodeScreenState extends State<QrcodeScreen> {
  String? scannedCode;
  MobileScannerController? _scannerController;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController();
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  void _handleScan(String code) async {
    setState(() {
      scannedCode = code;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Code scanné : $code')));

    final data = {
      "tripId": code,
      "walletId": "94f94902-c724-47ca-85d7-529af32b4a64",
      "amount": 200,
    };

    const String endpointUrl =
        'https://tripiz-api-production-d0f2.up.railway.app/transactions/spending';

    try {
      final response = await http.post(
        Uri.parse(endpointUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction envoyée avec succès ✅')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : ${response.statusCode} - ${response.body}'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur réseau : $e')));
    } finally {
      // Restart scanner after processing
      _scannerController?.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scanner de QR Code")),
      body: Column(
        children: [
          Expanded(flex: 5, child: QrScannerWidget(onScanned: _handleScan)),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                scannedCode != null
                    ? 'Résultat : $scannedCode'
                    : 'Aucun code scanné',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
