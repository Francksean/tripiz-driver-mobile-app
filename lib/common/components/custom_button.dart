import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  // Propriétés essentielles
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  // Propriétés de style simplifiées
  final Color? backgroundColor;
  final Gradient? gradient;
  final Color? textColor;
  final double height;
  final double? width;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  // Propriétés d'icône
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final double iconSpacing;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.gradient,
    this.textColor,
    this.height = 36.0,
    this.width,
    this.borderRadius = 8.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    this.prefixIcon,
    this.suffixIcon,
    this.iconSpacing = 8.0,
  });

  final bool _isEnabled = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Déterminer l'apparence en fonction de l'état
    final effectiveTextColor = textColor ?? Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isEnabled ? onPressed : null,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Ink(
          width: width,
          height: height,
          decoration: BoxDecoration(
            gradient: _isEnabled ? gradient : null,
            borderRadius: BorderRadius.circular(borderRadius),
            color: !_isEnabled ? Colors.grey : backgroundColor,
          ),
          child: Padding(
            padding: padding,
            child: Row(
              mainAxisSize: width == null ? MainAxisSize.min : MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (prefixIcon != null && !isLoading) ...[
                  prefixIcon!,
                  SizedBox(width: iconSpacing),
                ],
                if (isLoading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        effectiveTextColor,
                      ),
                    ),
                  )
                else
                  Text(
                    text,
                    style: TextStyle(
                      color:
                          _isEnabled
                              ? effectiveTextColor
                              : Colors.white.withOpacity(0.7),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (suffixIcon != null && !isLoading) ...[
                  SizedBox(width: iconSpacing),
                  suffixIcon!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
