import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tripiz_driver_mobile_app/common/constants/app_colors.dart';
import 'package:tripiz_driver_mobile_app/common/constants/font_sizes.dart';

class ReportingScreen extends StatefulWidget {
  const ReportingScreen({super.key});

  @override
  State<ReportingScreen> createState() => _ReportingScreenState();
}

class _ReportingScreenState extends State<ReportingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  final List<String> _categories = [
    "Problème technique",
    "Problème de paiement",
    "Comportement d'un passager",
    "Problème avec un trajet",
    "Autre",
  ];
  String? _selectedCategory;
  bool _isSubmitting = false;
  bool _submitted = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedCategory == null) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.red,
            content: const Text("Sélectionnez une catégorie."),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() => _isSubmitting = true);
    // TODO: remplacer par un vrai appel API une fois l'endpoint de
    // reporting disponible côté backend (ex: POST /reports).
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
      _submitted = true;
    });
  }

  void _reset() {
    setState(() {
      _submitted = false;
      _selectedCategory = null;
      _descriptionController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.vantablack, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          "Reporting",
          style: TextStyle(
            color: AppColors.vantablack,
            fontSize: FontSizes.lowerBig,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _submitted ? _buildSuccessState() : _buildForm(),
    );
  }

  Widget _buildSuccessState() {
    const successColor = Color.fromRGBO(46, 163, 105, 1);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(color: successColor.withOpacity(0.12), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded, color: successColor, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              "Signalement envoyé",
              style: TextStyle(fontSize: FontSizes.lowerBig, fontWeight: FontWeight.bold, color: AppColors.vantablack),
            ),
            const SizedBox(height: 8),
            Text(
              "Notre équipe va examiner votre signalement et reviendra vers vous si nécessaire.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: FontSizes.medium, color: AppColors.black),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: _reset,
              child: Text(
                "Envoyer un autre signalement",
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Catégorie",
              style: TextStyle(fontSize: FontSizes.medium, fontWeight: FontWeight.w600, color: AppColors.black),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category;
                return ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedCategory = category),
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.background,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.white : AppColors.black,
                    fontSize: FontSizes.medium,
                    fontWeight: FontWeight.w500,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide.none,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text(
              "Description",
              style: TextStyle(fontSize: FontSizes.medium, fontWeight: FontWeight.w600, color: AppColors.black),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _descriptionController,
              maxLines: 6,
              validator: (value) {
                if (value == null || value.trim().length < 10) {
                  return "Décrivez le problème (10 caractères minimum)";
                }
                return null;
              },
              decoration: InputDecoration(
                hintText: "Décrivez le problème rencontré...",
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.white),
                )
                    : Text("Envoyer", style: TextStyle(fontSize: FontSizes.lowerBig, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}