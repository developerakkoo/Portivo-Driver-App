import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../providers/notification_provider.dart';
import '../services/notification_service.dart';

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
      context.read<NotificationProvider>().loadNotifications(refresh: true);
    });
  }

  String? _tripIdFrom(DriverInboxNotification n) {
    final d = n.data;
    if (d == null) return null;
    final t = d['tripId'];
    if (t == null) return null;
    return t.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              if (provider.unreadCount == 0) {
                return const SizedBox.shrink();
              }
              return TextButton(
                onPressed: () async {
                  await provider.markAllRead();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('All marked as read')),
                    );
                  }
                },
                child: const Text('Mark all read'),
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null && provider.items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  provider.error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            );
          }
          if (provider.items.isEmpty) {
            return Center(
              child: Text(
                'No notifications yet',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => provider.loadNotifications(refresh: true),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              itemCount: provider.items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final n = provider.items[index];
                final tripId = _tripIdFrom(n);
                final timeStr = DateFormat.yMMMd().add_jm().format(n.createdAt.toLocal());
                return ListTile(
                  tileColor: n.read ? null : AppColors.offWhite.withOpacity(0.5),
                  title: Text(
                    n.title,
                    style: TextStyle(
                      fontWeight: n.read ? FontWeight.w500 : FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4.0),
                      Text(
                        n.message,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        timeStr,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                      ),
                    ],
                  ),
                  onTap: () async {
                    if (!n.read) {
                      await provider.markRead(n.id);
                    }
                    if (!context.mounted) return;
                    if (tripId != null && tripId.isNotEmpty) {
                      Navigator.of(context).pushNamed('/trip-detail', arguments: tripId);
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
