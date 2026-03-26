import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/notification_provider.dart';

class NotificationAppBarAction extends StatelessWidget {
  const NotificationAppBarAction({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, np, _) {
        return IconButton(
          tooltip: 'Notifications',
          onPressed: () => Navigator.of(context).pushNamed('/notifications'),
          icon: Badge(
            isLabelVisible: np.unreadCount > 0,
            label: Text(
              np.unreadCount > 99 ? '99+' : '${np.unreadCount}',
              style: const TextStyle(fontSize: 10),
            ),
            child: const Icon(Icons.notifications_outlined),
          ),
        );
      },
    );
  }
}
