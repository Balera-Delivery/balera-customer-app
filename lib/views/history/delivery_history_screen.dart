import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/delivery_model.dart';
import '../../providers/delivery_provider.dart';
import '../delivery/delivery_details_screen.dart';

class DeliveryHistoryScreen extends StatefulWidget {
  const DeliveryHistoryScreen({super.key});

  @override
  State<DeliveryHistoryScreen> createState() => _DeliveryHistoryScreenState();
}

class _DeliveryHistoryScreenState extends State<DeliveryHistoryScreen> {
  String _selectedFilter = 'All'; // All, Completed, In Progress, Cancelled

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeliveryProvider>().fetchDeliveries();
    });
  }

  @override
  Widget build(BuildContext context) {
    final deliveryProvider = context.watch<DeliveryProvider>();

    List<DeliveryModel> getFilteredList() {
      if (_selectedFilter == 'Completed') {
        return deliveryProvider.completedDeliveries;
      } else if (_selectedFilter == 'In Progress') {
        return deliveryProvider.ongoingDeliveries;
      } else if (_selectedFilter == 'Cancelled') {
        return deliveryProvider.cancelledDeliveries;
      }
      return deliveryProvider.deliveries;
    }

    final list = getFilteredList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'My Deliveries',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Pills Row (Screen 17)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: ['All', 'Completed', 'In Progress', 'Cancelled'].map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(
                        filter,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: const Color(0xFFF1F5F9),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedFilter = filter;
                          });
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            const Divider(height: 1, color: Color(0xFFF1F5F9)),

            // Delivery List Items (Screen 17) with RefreshIndicator
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => deliveryProvider.fetchDeliveries(),
                child: list.isEmpty
                    ? ListView(
                        children: [
                          const SizedBox(height: 80),
                          EmptyStateView(
                            icon: Icons.inventory_2_outlined,
                            title: 'No Deliveries Found',
                            message: 'No delivery records match "$_selectedFilter" category.',
                          ),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const Divider(height: 20, color: Color(0xFFF1F5F9)),
                        itemBuilder: (context, index) {
                          final item = list[index];
                          final isCancelled = AppConstants.isCancelled(item.status);
                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DeliveryDetailsScreen(delivery: item),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      isCancelled
                                          ? Icons.cancel_outlined
                                          : Icons.local_shipping_outlined,
                                      color: isCancelled
                                          ? AppColors.error
                                          : AppColors.primary,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '#${item.trackingCode ?? item.id}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          Formatters.dateTime(item.createdAt),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  StatusBadge(status: item.status),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 14,
                                    color: AppColors.textMuted,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
