import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerWidget extends StatefulWidget {
  final void Function(String code) onScanned;

  const QrScannerWidget({super.key, required this.onScanned});

  @override
  State<QrScannerWidget> createState() => _QrScannerWidgetState();
}

class _QrScannerWidgetState extends State<QrScannerWidget> {
  MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isScanning = true;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) {
    if (!_isScanning) return;

    final barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String code = barcodes.first.rawValue ?? '';
      if (code.isNotEmpty) {
        setState(() => _isScanning = false);
        widget.onScanned(code);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MobileScanner(controller: controller, onDetect: _handleBarcode),
        _buildOverlay(),
      ],
    );
  }

  Widget _buildOverlay() {
    const double cutOutSize = 250;

    return CustomPaint(
      painter: _ScannerOverlay(
        cutOutSize: cutOutSize,
        borderColor: Colors.deepPurple,
        borderRadius: 10,
        borderLength: 20,
        borderWidth: 8,
      ),
    );
  }
}

class _ScannerOverlay extends CustomPainter {
  final double cutOutSize;
  final Color borderColor;
  final double borderRadius;
  final double borderLength;
  final double borderWidth;

  _ScannerOverlay({
    required this.cutOutSize,
    required this.borderColor,
    required this.borderRadius,
    required this.borderLength,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw semi-transparent overlay
    final paint = Paint()..color = Colors.black54;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Calculate cutout position
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final cutoutRect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: cutOutSize,
      height: cutOutSize,
    );

    // Clear the cutout area
    final cutoutPaint =
        Paint()
          ..blendMode = BlendMode.clear
          ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(cutoutRect, Radius.circular(borderRadius)),
      cutoutPaint,
    );

    // Draw border
    final borderPaint =
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth;

    // Draw corners
    _drawCorner(canvas, borderPaint, cutoutRect.topLeft, 0);
    _drawCorner(canvas, borderPaint, cutoutRect.topRight, 90);
    _drawCorner(canvas, borderPaint, cutoutRect.bottomRight, 180);
    _drawCorner(canvas, borderPaint, cutoutRect.bottomLeft, 270);
  }

  void _drawCorner(Canvas canvas, Paint paint, Offset offset, double angle) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.rotate(angle * (3.1415927 / 180));

    canvas.drawLine(
      Offset(0, borderWidth / 2),
      Offset(borderLength, borderWidth / 2),
      paint,
    );

    canvas.drawLine(
      Offset(borderWidth / 2, 0),
      Offset(borderWidth / 2, borderLength),
      paint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
