import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tripiz_driver_mobile_app/account/components/avatar_modifier.dart';
import 'package:tripiz_driver_mobile_app/account/cubits/account_cubit.dart';
import 'package:tripiz_driver_mobile_app/common/constants/app_colors.dart';
import 'package:tripiz_driver_mobile_app/common/constants/font_sizes.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late final AccountCubit _accountCubit;

  @override
  void initState() {
    super.initState();
    _accountCubit = AccountCubit();
    _accountCubit.loadProfile();
  }

  @override
  void dispose() {
    _accountCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _accountCubit,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                _buildHeaderBackground(),
                Container(
                  margin: const EdgeInsets.only(bottom: 20, top: 15),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  height: 300,
                  child: Center(
                    child: BlocBuilder<AccountCubit, AccountState>(
                      builder: (context, state) {
                        if (state is AccountLoaded) {
                          final profile = state.profile;
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              AvatarModifier(
                                avatarPath: profile.avatarPath,
                                onImagePicked: (path) =>
                                    _accountCubit.updateAvatar(path),
                              ),
                              Text(
                                profile.fullName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: FontSizes.lowerLarge,
                                ),
                              ),
                              Text(profile.email),
                              Text(profile.phone),
                            ],
                          );
                        }
                        if (state is AccountError) {
                          return Text(
                            state.message,
                            style: TextStyle(color: AppColors.red),
                          );
                        }
                        return _buildShimmerHeader();
                      },
                    ),
                  ),
                ),
              ],
            ),
            Container(
              margin: const EdgeInsets.only(top: 50),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: [
                  ProfileItemTile(
                    label: "Modifier les informations du profil",
                    icon: Icons.newspaper_outlined,
                    subLabel:
                    "Changer de numéro, de mot de passe, d'e-mail, d'avatar",
                    onTap: () => context.push('/app/account/edit'),
                  ),
                  ProfileItemTile(
                    label: "Notifications",
                    icon: Icons.notifications_outlined,
                    subLabel: "Activer ou non les notifications",
                    onTap: () => context.push('/app/account/notifications'),
                  ),
                  ProfileItemTile(
                    label: "Reporting",
                    icon: Icons.flag_outlined,
                    subLabel: "Faites-nous part de vos difficultés",
                    onTap: () => context.push('/app/account/reporting'),
                  ),
                  const SizedBox(height: 10),
                  _buildLogoutButton(context),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Affiche le fond décoratif SVG, ou un simple Container coloré si
  /// l'asset est absent — évite le crash "Unable to load asset" vu en
  /// dev tant que le fichier assets/images/profil_head_fig.svg n'est
  /// pas ajouté au projet et déclaré dans pubspec.yaml.
  Widget _buildHeaderBackground() {
    return SvgPicture.asset(
      "assets/images/profil_head_fig.svg",
      placeholderBuilder: (context) => Container(
        height: 220,
        color: AppColors.background,
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: () => _confirmLogout(context),
        icon: Icon(Icons.logout_rounded, color: AppColors.red, size: 20),
        label: Text(
          "Se déconnecter",
          style: TextStyle(
            fontSize: FontSizes.lowerBig,
            fontWeight: FontWeight.w600,
            color: AppColors.red,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.red.withOpacity(0.4)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Se déconnecter ?"),
        content: const Text("Vous devrez vous reconnecter pour accéder à vos trajets."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text("Annuler", style: TextStyle(color: AppColors.black)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text("Déconnexion", style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await _accountCubit.logout();
      // Pas besoin de navigation manuelle : AuthService.notifyListeners()
      // déclenche automatiquement la redirection go_router vers /login.
    }
  }

  Widget _buildShimmerHeader() {
    return Shimmer.fromColors(
      baseColor: AppColors.background,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: [
          Container(
            height: 120,
            width: 120,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          Container(width: 150, height: 18, color: Colors.white),
          const SizedBox(height: 6),
          Container(width: 180, height: 14, color: Colors.white),
        ],
      ),
    );
  }
}

class ProfileItemTile extends StatelessWidget {
  const ProfileItemTile({
    required this.label,
    required this.icon,
    required this.subLabel,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final String subLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(width: 25),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: FontSizes.lowerLarge,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    overflow: TextOverflow.clip,
                    softWrap: true,
                    subLabel,
                    style: TextStyle(color: AppColors.black, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}