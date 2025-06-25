import 'package:flutter/material.dart';
import 'package:tripiz_driver_mobile_app/QRCode/components/qrcode_scanner.dart';

class QrcodeScreen extends StatefulWidget {
  const QrcodeScreen({super.key});

  @override
  State<QrcodeScreen> createState() => _QrcodeScreenState();
}

class _QrcodeScreenState extends State<QrcodeScreen> {
  String? scannedCode;

  void _handleScan(String code) {
    setState(() {
      scannedCode = code;
    });

    // 👉 Exemple : Fermer le scanner après scan
    // Navigator.pop(context, code);

    // 👉 Ou afficher un message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Code scanné : $code')),
    );
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
