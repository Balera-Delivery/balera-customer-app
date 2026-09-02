import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/notification_provider.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/empty_state_view.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notificationProvider = context.watch<NotificationProvider>();
    final notifications = notificationProvider.notifications;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => notificationProvider.fetchNotifications(),
                child: notifications.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 80),
                          EmptyStateView(
                            icon: Icons.notifications_none_outlined,
                            title: 'No Notifications',
                            message: 'You have no notifications at this time.',
                          ),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        itemCount: notifications.length,
                        separatorBuilder: (_, __) => const Divider(height: 18, color: Color(0xFFF1F5F9)),
                        itemBuilder: (context, index) {
                          final notif = notifications[index];
                          return InkWell(
                            onTap: () {
                              if (!notif.isRead) {
                                notificationProvider.markAsRead(notif.id);
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: notif.isRead ? const Color(0xFFF8FAFC) : const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      _getNotificationIcon(notif.title),
                                      size: 20,
                                      color: notif.isRead ? AppColors.textMuted : AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                notif.title,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.w800,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                            ),
                                            if (!notif.isRead)
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: const BoxDecoration(
                                                  color: AppColors.primary,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          notif.message,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: notif.isRead ? AppColors.textMuted : AppColors.textSecondary,
                                            height: 1.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    notif.createdAt != null
                                        ? Formatters.time(notif.createdAt)
                                        : _getMockTime(index),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),

            // Mark All as Read Link (Screen 19)
            if (notifications.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: TextButton(
                  onPressed: () {
                    notificationProvider.markAllAsRead();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All notifications marked as read'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  child: const Text(
                    'Mark all as read',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String title) {
    if (title.contains('Rider Assigned')) return Icons.two_wheeler_rounded;
    if (title.contains('Picked Up')) return Icons.inventory_2_rounded;
    if (title.contains('Arrived')) return Icons.location_on_rounded;
    if (title.contains('Completed')) return Icons.check_circle_rounded;
    if (title.contains('OTP')) return Icons.key_rounded;
    return Icons.notifications_active_rounded;
  }

  String _getMockTime(int index) {
    final times = ['10:48 AM', '10:45 AM', '10:35 AM', '10:35 AM', '10:30 AM'];
    return times[index % times.length];
  }
}
