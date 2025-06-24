import 'package:flutter/material.dart';
import 'package:tripiz_driver_mobile_app/common/constants/app_colors.dart';

class CustomInputField extends StatefulWidget {
  // Propriétés de base
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final bool obscureText;
  final TextInputType keyboardType;
  final int? maxLength;
  final int? maxLines;
  final int? minLines;
  final TextInputAction? textInputAction;
  final VoidCallback? onEditingComplete;
  final TextCapitalization textCapitalization;

  // Propriétés de style
  final InputDecoration? decoration;
  final TextStyle? textStyle;
  final TextStyle? labelStyle;
  final TextStyle? hintStyle;
  final TextStyle? errorStyle;
  final TextStyle? helperStyle;
  final Color? cursorColor;
  final double cursorWidth;
  final double? cursorHeight;
  final Radius? cursorRadius;
  final Color? fillColor;
  final Color? focusColor;
  final Color? hoverColor;
  final BorderRadius? borderRadius;
  final bool? isBordered;
  final EdgeInsetsGeometry? contentPadding;

  // Propriétés d'icône
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final VoidCallback? onSuffixIconTap;

  // Propriétés de validation
  final String? Function(String?)? validator;
  final AutovalidateMode autovalidateMode;

  // Propriétés d'accessibilité
  final String? semanticsLabel;
  final bool enabled;
  final FocusNode? focusNode;
  final TextEditingController? controller;

  const CustomInputField({
    super.key,
    this.initialValue,
    this.onChanged,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.maxLength,
    this.maxLines = 1,
    this.minLines,
    this.textInputAction,
    this.onEditingComplete,
    this.textCapitalization = TextCapitalization.none,
    this.decoration,
    this.textStyle,
    this.labelStyle,
    this.hintStyle,
    this.errorStyle,
    this.helperStyle,
    this.cursorColor,
    this.cursorWidth = 2.0,
    this.cursorHeight,
    this.cursorRadius,
    this.fillColor,
    this.focusColor,
    this.hoverColor,
    this.borderRadius,
    this.contentPadding,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconTap,
    this.validator,
    this.autovalidateMode = AutovalidateMode.disabled,
    this.semanticsLabel,
    this.enabled = true,
    this.focusNode,
    this.controller,
    this.isBordered,
  });

  @override
  _CustomInputFieldState createState() => _CustomInputFieldState();
}

class _CustomInputFieldState extends State<CustomInputField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ?? TextEditingController(text: widget.initialValue);
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    if (widget.focusNode == null) {
      _focusNode.removeListener(_onFocusChange);
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Construction du decoration par défaut
    final defaultDecoration = InputDecoration(
      labelText: widget.labelText,
      hintText: widget.hintText,
      helperText: widget.helperText,
      errorText: widget.errorText,
      labelStyle: widget.labelStyle,
      hintStyle: widget.hintStyle,
      errorStyle: widget.errorStyle,
      helperStyle: widget.helperStyle,
      prefixIcon: widget.prefixIcon,
      suffixIcon: _buildSuffixIcon(),
      filled: widget.fillColor != null,
      fillColor: widget.fillColor,
      focusColor: widget.focusColor,
      hoverColor: widget.hoverColor,
      contentPadding:
          widget.contentPadding ??
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      border: _buildInputBorder(),
      enabledBorder: _buildInputBorder(),
      focusedBorder: _buildInputBorder(color: theme.primaryColor),
      errorBorder: _buildInputBorder(color: theme.colorScheme.error),
      focusedErrorBorder: _buildInputBorder(color: theme.colorScheme.error),
    );

    return Semantics(
      label: widget.semanticsLabel,
      child: TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        decoration: widget.decoration ?? defaultDecoration,
        style: widget.textStyle,
        obscureText: widget.obscureText && !_isPasswordVisible,
        keyboardType: widget.keyboardType,
        maxLength: widget.maxLength,
        maxLines: widget.obscureText ? 1 : widget.maxLines,
        minLines: widget.minLines,
        textInputAction: widget.textInputAction,
        onEditingComplete: widget.onEditingComplete,
        textCapitalization: widget.textCapitalization,
        cursorColor: widget.cursorColor ?? theme.primaryColor,
        cursorWidth: widget.cursorWidth,
        cursorHeight: widget.cursorHeight,
        cursorRadius: widget.cursorRadius,
        enabled: widget.enabled,
        onChanged: widget.onChanged,
        validator: widget.validator,
        autovalidateMode: widget.autovalidateMode,
      ),
    );
  }

  InputBorder _buildInputBorder({Color? color}) {
    final borderRadius = widget.borderRadius ?? BorderRadius.circular(8.0);
    if (widget.isBordered == false) {
      return OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide.none,
      );
    }
    final borderColor = color ?? AppColors.border;
    return OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(color: borderColor, width: _isFocused ? 2.0 : 1.0),
    );
  }

  Widget? _buildSuffixIcon() {
    if (widget.obscureText) {
      return IconButton(
        icon: Icon(
          _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
          color: Colors.grey,
        ),
        onPressed: _togglePasswordVisibility,
      );
    } else if (widget.suffixIcon != null) {
      return GestureDetector(
        onTap: widget.onSuffixIconTap,
        child: widget.suffixIcon,
      );
    }
    return widget.suffixIcon;
  }
}
