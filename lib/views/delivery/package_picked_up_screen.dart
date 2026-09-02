import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_button.dart';
import 'rider_arrived_screen.dart';

class PackagePickedUpScreen extends StatelessWidget {
  final String deliveryId;

  const PackagePickedUpScreen({super.key, this.deliveryId = 'DLV-00126'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          '#$deliveryId',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),

              // Yellow Package Box Icon (Screen 13)
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
                  size: 46,
                  color: Color(0xFFD97706),
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Package Picked Up',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your item has been collected\nand is on the way.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // 5-Stage Timeline (Screen 13)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: Column(
                  children: [
                    _buildTimelineRow('Request Received', isDone: true, isCurrent: false),
                    _buildTimelineLine(isPassed: true),
                    _buildTimelineRow('Rider Assigned', isDone: true, isCurrent: false),
                    _buildTimelineLine(isPassed: true),
                    _buildTimelineRow('Picked Up', isDone: true, isCurrent: true),
                    _buildTimelineLine(isPassed: false),
                    _buildTimelineRow('On The Way', isDone: false, isCurrent: false),
                    _buildTimelineLine(isPassed: false),
                    _buildTimelineRow('Delivered', isDone: false, isCurrent: false),
                  ],
                ),
              ),

              const Spacer(),

              // Next: Rider Arrived Button
              CustomButton(
                text: 'Next: Rider Arrived',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RiderArrivedScreen(deliveryId: deliveryId),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineRow(String title, {required bool isDone, required bool isCurrent}) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone ? (isCurrent ? AppColors.primary : AppColors.success) : Colors.white,
            border: Border.all(
              color: isDone ? (isCurrent ? AppColors.primary : AppColors.success) : const Color(0xFFCBD5E1),
              width: 2,
            ),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 12, color: Colors.white)
                : null,
          ),
        ),
        const SizedBox(width: 14),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isCurrent ? FontWeight.w700 : (isDone ? FontWeight.w600 : FontWeight.w400),
            color: isDone ? AppColors.textPrimary : AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineLine({required bool isPassed}) {
    return Container(
      margin: const EdgeInsets.only(left: 9),
      alignment: Alignment.centerLeft,
      height: 22,
      width: 2,
      color: isPassed ? AppColors.success : const Color(0xFFE2E8F0),
    );
  }
}
