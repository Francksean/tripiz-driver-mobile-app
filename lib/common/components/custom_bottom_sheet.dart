import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tripiz_driver_mobile_app/common/constants/app_colors.dart';

class CustomBottomSheet extends StatelessWidget {
  final Widget child;
  final VoidCallback? onCancel;
  const CustomBottomSheet({super.key, required this.child, this.onCancel});

  @override
  Widget build(BuildContext context) {
    // Calculate the available height
    final availableHeight =
        MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.top -
        MediaQuery.of(context).padding.bottom;

    return Container(
      width: double.infinity,
      height: availableHeight * 0.4,
      constraints: BoxConstraints(maxHeight: availableHeight * 0.7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Close button
          GestureDetector(
            onTap: () {
              if (onCancel != null) {
                onCancel!();
              } else {
                context.pop();
              }
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16, bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: const BorderRadius.all(Radius.circular(99)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.close, size: 24, color: AppColors.border),
            ),
          ),
          // Main content with rounded top corners
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Column(
                children: [
                  // Handle bar to indicate draggable
                  Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 8),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Child content
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: child,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
