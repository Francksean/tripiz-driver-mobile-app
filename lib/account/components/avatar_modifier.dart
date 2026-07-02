import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tripiz_driver_mobile_app/common/constants/app_colors.dart';

class AvatarModifier extends StatelessWidget {
  final String? avatarPath;
  final void Function(String path) onImagePicked;

  const AvatarModifier({
    super.key,
    required this.onImagePicked,
    this.avatarPath,
  });

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      onImagePicked(picked.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          child: Container(
            height: 120,
            width: 120,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              image: avatarPath != null
                  ? DecorationImage(
                image: FileImage(File(avatarPath!)),
                fit: BoxFit.cover,
              )
                  : const DecorationImage(
                image: AssetImage("assets/images/profile_img.jpg"),
              ),
              shape: BoxShape.circle,
              color: AppColors.border,
            ),
          ),
        ),
        Positioned(
          bottom: 20,
          right: 0,
          child: GestureDetector(
            onTap: _pickImage,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.black,
                shape: BoxShape.circle,
                border: Border.all(width: 3, color: AppColors.black),
              ),
              child: const Icon(
                Icons.border_color_outlined,
                color: AppColors.white,
                size: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }
}