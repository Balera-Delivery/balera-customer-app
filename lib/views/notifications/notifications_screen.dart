import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../models/notification_model.dart';
import '../../providers/notification_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedFilter = 'All'; // All, Unread, Orders, System

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

    // Filter notification items
    final filteredList = notifications.where((n) {
      if (_selectedFilter == 'Unread') {
        return !n.isRead;
      } else if (_selectedFilter == 'Orders') {
        final t = n.title.toLowerCase();
        return t.contains('order') ||
            t.contains('rider') ||
            t.contains('delivery') ||
            t.contains('picked') ||
            t.contains('arrived') ||
            t.contains('otp');
      } else if (_selectedFilter == 'System') {
        final t = n.title.toLowerCase();
        return !t.contains('order') &&
            !t.contains('rider') &&
            !t.contains('delivery') &&
            !t.contains('picked') &&
            !t.contains('arrived') &&
            !t.contains('otp');
      }
      return true; // All
    }).toList();

    final unreadCount = notifications.where((n) => !n.isRead).length;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            // Top Royal Blue Curved Header
            _buildCurvedHeader(context, notifications, unreadCount, notificationProvider),

            // Notification Cards List
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF0052EA),
                onRefresh: () => notificationProvider.fetchNotifications(),
                child: filteredList.isEmpty
                    ? ListView(
                        children: [
                          const SizedBox(height: 80),
                          EmptyStateView(
                            icon: Icons.notifications_none_rounded,
                            title: 'No Alerts Found',
                            message: _selectedFilter == 'Unread'
                                ? 'You have read all your alerts!'
                                : 'No notifications match "$_selectedFilter" category.',
                          ),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: filteredList.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final notif = filteredList[index];
                          return _buildNotificationCard(context, notif, notificationProvider);
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Top Royal Blue Curved Header
  // ---------------------------------------------------------------------------
  Widget _buildCurvedHeader(
    BuildContext context,
    List<NotificationModel> allNotifications,
    int unreadCount,
    NotificationProvider notificationProvider,
  ) {
    final topPadding = MediaQuery.of(context).padding.top;
    final filters = ['All', 'Unread', 'Orders', 'System'];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: topPadding + 14,
        left: 18,
        right: 18,
        bottom: 18,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF004BE4),
            Color(0xFF005BF6),
            Color(0xFF1E67FF),
          ],
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x33005BF6),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Alerts & Notices',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    unreadCount > 0
                        ? '$unreadCount unread ${unreadCount == 1 ? 'alert' : 'alerts'}'
                        : '${allNotifications.length} total alerts',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (unreadCount > 0)
                    InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        notificationProvider.markAllAsRead();
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.done_all_rounded, size: 14, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'Read all',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (allNotifications.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.delete_sweep_outlined, color: Colors.white, size: 20),
                      tooltip: 'Clear All',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _confirmClearAll(context, notificationProvider),
                    ),
                  ],
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 4 Compact Filter Buttons Fixed in One Row
          Row(
            children: filters.map((filter) {
              final isSelected = _selectedFilter == filter;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.5),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 6.5),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.35),
                            width: 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.12),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : [],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected) ...[
                              const Icon(
                                Icons.check_rounded,
                                size: 12,
                                color: Color(0xFF0052EA),
                              ),
                              const SizedBox(width: 2.5),
                            ],
                            Flexible(
                              child: Text(
                                filter,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  color: isSelected ? const Color(0xFF0052EA) : Colors.white,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Alert / Notification Card
  // ---------------------------------------------------------------------------
  Widget _buildNotificationCard(
    BuildContext context,
    NotificationModel notif,
    NotificationProvider notificationProvider,
  ) {
    final styleInfo = _getAlertStyle(notif.title);

    final timeString = notif.createdAt != null
        ? Formatters.dateTime(notif.createdAt)
        : 'Just now';

    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
      ),
      onDismissed: (_) {
        notificationProvider.deleteNotification(notif.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification removed'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: notif.isRead ? const Color(0xFFE2E8F0) : const Color(0xFF0052EA).withValues(alpha: 0.35),
            width: notif.isRead ? 1.2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: notif.isRead
                  ? const Color(0xFF0F172A).withValues(alpha: 0.03)
                  : const Color(0xFF0052EA).withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (!notif.isRead) {
                notificationProvider.markAsRead(notif.id);
              }
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pastel Rounded Square Icon
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: styleInfo.bgColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Icon(styleInfo.icon, color: styleInfo.iconColor, size: 22),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title, Message, Date
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
                                  fontWeight: notif.isRead ? FontWeight.w700 : FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            if (!notif.isRead) ...[
                              const SizedBox(width: 6),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF0052EA),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          notif.message,
                          style: TextStyle(
                            fontSize: 12,
                            color: notif.isRead ? const Color(0xFF64748B) : const Color(0xFF334155),
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              timeString,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                            InkWell(
                              onTap: () => notificationProvider.deleteNotification(notif.id),
                              child: const Padding(
                                padding: EdgeInsets.all(4.0),
                                child: Icon(Icons.close_rounded, size: 15, color: Color(0xFF94A3B8)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Clear all confirmation dialog
  void _confirmClearAll(BuildContext context, NotificationProvider notificationProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Clear All Notifications?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        content: const Text('Are you sure you want to delete all alert messages?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              notificationProvider.clearAllNotifications();
            },
            child: const Text('Clear All', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  _AlertStyleInfo _getAlertStyle(String title) {
    final t = title.toLowerCase();
    if (t.contains('rider') || t.contains('assigned') || t.contains('way')) {
      return const _AlertStyleInfo(
        icon: Icons.two_wheeler_rounded,
        iconColor: Color(0xFF0052EA),
        bgColor: Color(0xFFEFF6FF),
      );
    }
    if (t.contains('picked up') || t.contains('package')) {
      return const _AlertStyleInfo(
        icon: Icons.inventory_2_outlined,
        iconColor: Color(0xFFD97706),
        bgColor: Color(0xFFFEF3C7),
      );
    }
    if (t.contains('completed') || t.contains('delivered')) {
      return const _AlertStyleInfo(
        icon: Icons.check_circle_outline_rounded,
        iconColor: Color(0xFF16A34A),
        bgColor: Color(0xFFDCFCE7),
      );
    }
    if (t.contains('cancel')) {
      return const _AlertStyleInfo(
        icon: Icons.cancel_outlined,
        iconColor: Color(0xFFDC2626),
        bgColor: Color(0xFFFEE2E2),
      );
    }
    if (t.contains('otp') || t.contains('code') || t.contains('security')) {
      return const _AlertStyleInfo(
        icon: Icons.vpn_key_outlined,
        iconColor: Color(0xFF7C3AED),
        bgColor: Color(0xFFEDE9FE),
      );
    }
    return const _AlertStyleInfo(
      icon: Icons.notifications_active_outlined,
      iconColor: Color(0xFF0284C7),
      bgColor: Color(0xFFE0F2FE),
    );
  }
}

class _AlertStyleInfo {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  const _AlertStyleInfo({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });
}

