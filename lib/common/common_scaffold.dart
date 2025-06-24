import 'package:flutter/material.dart';
import 'package:tripiz_driver_mobile_app/common/constants/app_colors.dart';

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
    // liste des widgets d'appbar
  ];
  final List<Widget> pages = [
    // liste des widgets de page
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
            label: "Home",
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.person, color: AppColors.primary),
            icon: Icon(Icons.person_outline, color: AppColors.black),
            label: "compte",
          ),
        ],
      ),
    );
  }
}
