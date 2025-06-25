import 'package:flutter/material.dart';

class QrcodeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const QrcodeAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
    );
  }
}