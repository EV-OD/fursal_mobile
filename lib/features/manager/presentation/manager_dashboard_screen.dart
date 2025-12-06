import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ManagerDashboardScreen extends ConsumerWidget {
  const ManagerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            // Statistics Cards
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.4,
              children: [
                _buildStatCard(
                  context,
                  title: 'Total Revenue',
                  value: 'Rs. 0',
                  icon: Icons.account_balance_wallet_outlined,
                  color: Colors.blue.shade50,
                  iconColor: Colors.blue,
                ),
                _buildStatCard(
                  context,
                  title: 'Active Bookings',
                  value: '0',
                  icon: Icons.calendar_today_outlined,
                  color: Colors.green.shade50,
                  iconColor: Colors.green,
                ),
                _buildStatCard(
                  context,
                  title: 'Physical Bookings',
                  value: '0',
                  icon: Icons.storefront_outlined,
                  color: Colors.orange.shade50,
                  iconColor: Colors.orange,
                ),
                _buildStatCard(
                  context,
                  title: 'Online Bookings',
                  value: '0',
                  icon: Icons.language_outlined,
                  color: Colors.purple.shade50,
                  iconColor: Colors.purple,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Recent Bookings Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Bookings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Center(
                child: Text(
                  'No bookings found.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildQuickActionTile(
              context,
              title: 'Venue Settings',
              subtitle: 'Update price, description, and amenities',
              icon: Icons.settings_outlined,
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _buildQuickActionTile(
              context,
              title: 'All Bookings',
              subtitle: 'View and manage all booking history',
              icon: Icons.history_outlined,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context,
      {required String title,
      required String value,
      required IconData icon,
      required Color color,
      required Color iconColor}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.05),
              offset: Offset(0, 2),
              blurRadius: 4,
            )
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Icon(icon, size: 18, color: iconColor),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionTile(BuildContext context,
      {required String title,
      required String subtitle,
      required IconData icon,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.black87),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
