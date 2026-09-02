import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;
  final EdgeInsets padding;

  const StatusBadge({
    super.key,
    required this.status,
    this.fontSize = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    Color getStatusColor() {
      final upper = status.toUpperCase().replaceAll('-', '_');
      switch (upper) {
        case 'PENDING':
          return AppColors.statusPending;
        case 'ASSIGNED':
          return AppColors.statusAssigned;
        case 'ACCEPTED':
          return AppColors.statusAccepted;
        case 'ARRIVED_AT_PICKUP':
        case 'PICKED_UP':
          return AppColors.statusPickedUp;
        case 'ON_THE_WAY':
          return const Color(0xFF16A34A);
        case 'DELIVERED':
        case 'COMPLETED':
          return const Color(0xFF16A34A);
        case 'CANCELLED':
        case 'CANCELED':
          return AppColors.statusCancelled;
        default:
          return AppColors.textMuted;
      }
    }

    final color = getStatusColor();
    final displayLabel = AppConstants.formatStatus(status);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            displayLabel,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }
}
