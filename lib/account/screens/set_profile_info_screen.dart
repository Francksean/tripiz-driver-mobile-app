import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tripiz_driver_mobile_app/account/components/avatar_modifier.dart';
import 'package:tripiz_driver_mobile_app/account/cubits/account_cubit.dart';
import 'package:tripiz_driver_mobile_app/common/constants/app_colors.dart';
import 'package:tripiz_driver_mobile_app/common/constants/font_weights.dart';

class SetProfileInfosScreen extends StatelessWidget {
  const SetProfileInfosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Modifier le profil"),
        backgroundColor: Colors.transparent,
      ),
      backgroundColor: AppColors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            stops: [0, 1],
            begin: Alignment.topCenter,
            end: Alignment.center,
            colors: [AppColors.primary, AppColors.white],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 110),
                child: Center(
                  child: BlocBuilder<AccountCubit, AccountState>(
                    builder: (context, state) {
                      final avatarPath = state is AccountLoaded
                          ? state.profile.avatarPath
                          : null;
                      return AvatarModifier(
                        avatarPath: avatarPath,
                        onImagePicked: (path) =>
                            context.read<AccountCubit>().updateAvatar(path),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50),
                child: BlocBuilder<AccountCubit, AccountState>(
                  builder: (context, state) {
                    if (state is! AccountLoaded) {
                      return const SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final profile = state.profile;
                    return Column(
                      children: [
                        InfosTile(
                          type: TextInputType.name,
                          icon: Icons.person_outline,
                          label: "Nom",
                          value: profile.fullName,
                          explanation:
                          "Le nom qui apparaîtra sur votre profil chauffeur",
                          onSave: (newValue) => context
                              .read<AccountCubit>()
                              .updateField(firstName: newValue),
                        ),
                        InfosTile(
                          type: TextInputType.emailAddress,
                          icon: Icons.mail_outline,
                          label: "Adresse e-mail",
                          value: profile.email,
                          explanation:
                          "L'adresse email via laquelle vous serez potentiellement contacté",
                          onSave: (newValue) => context
                              .read<AccountCubit>()
                              .updateField(email: newValue),
                        ),
                        InfosTile(
                          type: TextInputType.phone,
                          icon: Icons.phone_outlined,
                          label: "Numéro de téléphone",
                          value: profile.phone,
                          explanation:
                          "Numéro de téléphone via lequel vous serez potentiellement contacté",
                          onSave: (newValue) => context
                              .read<AccountCubit>()
                              .updateField(phone: newValue),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InfosTile extends StatelessWidget {
  const InfosTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.explanation,
    required this.type,
    required this.onSave,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final String explanation;
  final TextInputType type;
  final void Function(String newValue) onSave;

  void _showEditSheet(BuildContext context) {
    final controller = TextEditingController(text: value);
    showModalBottomSheet(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 16,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                keyboardType: type,
                decoration: InputDecoration(labelText: label),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  onSave(controller.text);
                  Navigator.of(sheetContext).pop();
                },
                child: const Text("Valider"),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      width: double.infinity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.black),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(fontWeight: FontWeights.bold),
                        ),
                        Text(
                          value,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.black,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => _showEditSheet(context),
                      icon: const Icon(
                        Icons.border_color_outlined,
                        color: AppColors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  explanation,
                  softWrap: true,
                  style: const TextStyle(fontSize: 12, color: AppColors.black),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}