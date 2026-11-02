import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

enum ButtonType { primary, secondary, outlined, danger }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ButtonType type;
  final IconData? icon;
  final double? height;
  final double? width;
  final BorderRadius? borderRadius;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.type = ButtonType.primary,
    this.icon,
    this.height = 50,
    this.width,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(12);

    Color getBackgroundColor() {
      switch (type) {
        case ButtonType.primary:
          return AppColors.primary;
        case ButtonType.secondary:
          return AppColors.accent;
        case ButtonType.danger:
          return AppColors.error;
        case ButtonType.outlined:
          return Colors.transparent;
      }
    }

    Color getForegroundColor() {
      switch (type) {
        case ButtonType.primary:
        case ButtonType.secondary:
        case ButtonType.danger:
          return Colors.white;
        case ButtonType.outlined:
          return AppColors.primary;
      }
    }

    BorderSide? getBorder() {
      if (type == ButtonType.outlined) {
        return const BorderSide(color: Color(0xFFCBD5E1), width: 1.5);
      }
      return null;
    }

    final isPrimary = type == ButtonType.primary;

    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: isPrimary && !isLoading && onPressed != null
            ? AppColors.primaryGradient
            : null,
        boxShadow: isPrimary && !isLoading && onPressed != null
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.30),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? Colors.transparent : getBackgroundColor(),
          shadowColor: Colors.transparent,
          foregroundColor: getForegroundColor(),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: getBorder() ?? BorderSide.none,
          ),
          disabledBackgroundColor: isPrimary
              ? AppColors.primary.withValues(alpha: 0.5)
              : getBackgroundColor().withValues(alpha: 0.6),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(getForegroundColor()),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: getForegroundColor()),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: getForegroundColor(),
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
