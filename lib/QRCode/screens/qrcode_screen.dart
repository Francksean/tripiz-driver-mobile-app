import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tripiz_driver_mobile_app/QRCode/components/qrcode_scanner.dart';
import 'package:tripiz_driver_mobile_app/QRCode/cubits/payment_cubit.dart';
import 'package:tripiz_driver_mobile_app/QRCode/cubits/trip_gate_cubit.dart';
import 'package:tripiz_driver_mobile_app/QRCode/repositories/payment_repository.dart';
import 'package:tripiz_driver_mobile_app/common/constants/app_colors.dart';
import 'package:tripiz_driver_mobile_app/common/constants/font_sizes.dart';

class QrcodeScreen extends StatelessWidget {
  const QrcodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TripGateCubit()..checkActiveTrip(),
      child: BlocBuilder<TripGateCubit, TripGateState>(
        builder: (context, gateState) {
          if (gateState is TripGateLoading) {
            return _buildGateLoading();
          }
          if (gateState is TripGateBlocked) {
            return _buildGateBlocked(context);
          }
          if (gateState is TripGateError) {
            return _buildGateError(context, gateState.message);
          }
          // TripGateAllowed
          return BlocProvider(
            create: (_) => PaymentCubit(),
            child: const _QrcodeView(),
          );
        },
      ),
    );
  }

  Widget _buildGateLoading() {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildGateBlocked(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.qr_code_scanner_rounded,
                  size: 38,
                  color: AppColors.black.withOpacity(0.4),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Aucun trajet en cours",
                style: TextStyle(
                  fontSize: FontSizes.lowerBig,
                  fontWeight: FontWeight.bold,
                  color: AppColors.vantablack,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Démarrez un trajet depuis l'onglet Accueil pour pouvoir scanner les tickets des passagers.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: FontSizes.medium, color: AppColors.black),
              ),
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: () => context.read<TripGateCubit>().checkActiveTrip(),
                icon: Icon(Icons.refresh_rounded, color: AppColors.primary, size: 18),
                label: Text(
                  "Actualiser",
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGateError(BuildContext context, String message) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 40, color: AppColors.red),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: FontSizes.large, color: AppColors.black),
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: () => context.read<TripGateCubit>().checkActiveTrip(),
                icon: Icon(Icons.refresh_rounded, color: AppColors.primary, size: 18),
                label: Text(
                  "Réessayer",
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QrcodeView extends StatefulWidget {
  const _QrcodeView();

  @override
  State<_QrcodeView> createState() => _QrcodeViewState();
}

class _QrcodeViewState extends State<_QrcodeView> {
  int _scannerResetKey = 0;

  void _handleScan(String code) {
    context.read<PaymentCubit>().payFromQrContent(code);
  }

  void _scanNext() {
    context.read<PaymentCubit>().reset();
    setState(() => _scannerResetKey++);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.vantablack,
      body: BlocBuilder<PaymentCubit, PaymentState>(
        builder: (context, state) {
          return Stack(
            fit: StackFit.expand,
            children: [
              QrScannerWidget(
                key: ValueKey(_scannerResetKey),
                onScanned: _handleScan,
              ),
              if (state is PaymentInitial) _buildTopHint(),
              if (state is PaymentLoading) _buildProcessingOverlay(),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                left: 0,
                right: 0,
                bottom: (state is PaymentSuccess || state is PaymentFailure) ? 0 : -320,
                child: _buildResultCard(state),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopHint() {
    return Positioned(
      top: 60,
      left: 24,
      right: 24,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.vantablack.withOpacity(0.55),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.qr_code_scanner_rounded, color: AppColors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Placez le QR code du passager dans le cadre",
                style: TextStyle(color: AppColors.white, fontSize: FontSizes.medium),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      color: AppColors.vantablack.withOpacity(0.55),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.white),
            const SizedBox(height: 16),
            Text(
              "Traitement du paiement...",
              style: TextStyle(color: AppColors.white, fontSize: FontSizes.large),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(PaymentState state) {
    if (state is PaymentSuccess) return _buildSuccessCard(state.data);
    if (state is PaymentFailure) return _buildFailureCard(state.message);
    return const SizedBox.shrink();
  }

  Widget _buildSuccessCard(QrPaymentData data) {
    const successColor = Color.fromRGBO(46, 163, 105, 1);

    return _ResultCardShell(
      accentColor: successColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: successColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded, color: successColor, size: 32),
          ),
          const SizedBox(height: 12),
          Text(
            "Paiement accepté",
            style: TextStyle(
              fontSize: FontSizes.lowerBig,
              fontWeight: FontWeight.bold,
              color: AppColors.vantablack,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "${data.amount.toStringAsFixed(0)} FCFA",
            style: TextStyle(
              fontSize: FontSizes.extra,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Ticket ${data.ticketId.substring(0, 8)}...",
            style: TextStyle(fontSize: FontSizes.small, color: AppColors.black.withOpacity(0.6)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _scanNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Scanner un autre ticket"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailureCard(String message) {
    return _ResultCardShell(
      accentColor: AppColors.red,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.error_outline_rounded, color: AppColors.red, size: 32),
          ),
          const SizedBox(height: 12),
          Text(
            "Paiement refusé",
            style: TextStyle(
              fontSize: FontSizes.lowerBig,
              fontWeight: FontWeight.bold,
              color: AppColors.vantablack,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: FontSizes.medium, color: AppColors.black),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: _scanNext,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Réessayer"),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultCardShell extends StatelessWidget {
  final Color accentColor;
  final Widget child;

  const _ResultCardShell({required this.accentColor, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: AppColors.vantablack.withOpacity(0.25),
            blurRadius: 30,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}