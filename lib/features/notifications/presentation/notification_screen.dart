import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy notifications
    final notifications = [
      {
        'title': 'Booking Confirmed',
        'body':
            'Your booking at Futsal Arena has been confirmed for tomorrow at 6 PM.',
        'time': '2 hours ago',
        'isRead': false,
      },
      {
        'title': 'Payment Successful',
        'body': 'Payment of \$20.00 was successful.',
        'time': '1 day ago',
        'isRead': true,
      },
      {
        'title': 'New Venue Added',
        'body': 'Check out the new "City Sports Complex" near you!',
        'time': '2 days ago',
        'isRead': true,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
      ),
      body: ListView.separated(
        itemCount: notifications.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final notification = notifications[index];
          final isRead = notification['isRead'] as bool;

          return ListTile(
            tileColor: isRead ? null : AppTheme.primaryColor.withOpacity(0.05),
            leading: CircleAvatar(
              backgroundColor: isRead
                  ? Colors.grey[200]
                  : AppTheme.primaryColor.withOpacity(0.1),
              child: Icon(
                Icons.notifications,
                color: isRead ? Colors.grey : AppTheme.primaryColor,
              ),
            ),
            title: Text(
              notification['title'] as String,
              style: TextStyle(
                fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(notification['body'] as String),
                const SizedBox(height: 4),
                Text(
                  notification['time'] as String,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ],
            ),
            onTap: () {
              // TODO: Mark as read
            },
          );
        },
      ),
    );
  }
}
