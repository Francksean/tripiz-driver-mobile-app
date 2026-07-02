import 'package:flutter/material.dart';
import 'package:tripiz_driver_mobile_app/account/components/account_app_bar.dart';
import 'package:tripiz_driver_mobile_app/account/screens/account_screen.dart';
import 'package:tripiz_driver_mobile_app/common/constants/app_colors.dart';
import 'package:tripiz_driver_mobile_app/home/screens/home_screen.dart';
import 'package:tripiz_driver_mobile_app/home/components/home_app_bar.dart';
import 'package:tripiz_driver_mobile_app/QRCode/components/qrcode_app_bar.dart';
import 'package:tripiz_driver_mobile_app/QRCode/screens/qrcode_screen.dart';

class CommonScaffold extends StatefulWidget {
  const CommonScaffold({super.key});

  @override
  State<CommonScaffold> createState() => _CommonScaffoldState();
}

class _CommonScaffoldState extends State<CommonScaffold> {
  var _selectedIndex = 0;

  void _updateSelectedIndex(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<PreferredSizeWidget> appBars = [
    const HomeAppBar(),
    const QrcodeAppBar(),
    const AccountAppBar(),
  ];

  final List<Widget> pages = [
    const HomeScreen(),
    const QrcodeScreen(),
    const AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      resizeToAvoidBottomInset: true,
      extendBodyBehindAppBar: true,
      appBar: appBars[_selectedIndex],
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        elevation: 2,
        onDestinationSelected: _updateSelectedIndex,
        destinations: const [
          NavigationDestination(
            selectedIcon: Icon(Icons.home_filled, color: AppColors.primary),
            icon: Icon(Icons.home_outlined, color: AppColors.black),
            label: "Accueil",
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.qr_code, color: AppColors.primary),
            icon: Icon(Icons.qr_code_outlined, color: AppColors.black),
            label: "Code QR",
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.person, color: AppColors.primary),
            icon: Icon(Icons.person_outline, color: AppColors.black),
            label: "Compte",
          ),
        ],
      ),
    );
  }
}