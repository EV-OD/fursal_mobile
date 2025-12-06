import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';

class ManagerScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ManagerScaffoldWithNavBar({
    required this.navigationShell,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _getTitle(navigationShell.currentIndex),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        indicatorColor: AppTheme.primaryColor.withOpacity(0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: AppTheme.primaryColor),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon:
                Icon(Icons.calendar_today, color: AppTheme.primaryColor),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: Icon(Icons.payment_outlined),
            selectedIcon: Icon(Icons.payment, color: AppTheme.primaryColor),
            label: 'Payments',
          ),
          NavigationDestination(
            icon: Icon(Icons.store_mall_directory_outlined),
            selectedIcon:
                Icon(Icons.store_mall_directory, color: AppTheme.primaryColor),
            label: 'My Venue',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_outlined),
            selectedIcon:
                Icon(Icons.qr_code_scanner, color: AppTheme.primaryColor),
            label: 'Scan QR',
          ),
        ],
      ),
    );
  }

  String _getTitle(int index) {
    switch (index) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Bookings';
      case 2:
        return 'Payments';
      case 3:
        return 'My Venues';
      case 4:
        return 'Scan QR';
      default:
        return 'Dashboard';
    }
  }
}
