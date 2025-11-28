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
            icon: Icon(Icons.store_mall_directory_outlined),
            selectedIcon: Icon(Icons.store_mall_directory, color: AppTheme.primaryColor),
            label: 'My Venues',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today, color: AppTheme.primaryColor),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppTheme.primaryColor),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  String _getTitle(int index) {
    switch (index) {
      case 0:
        return 'Manager Dashboard';
      case 1:
        return 'Bookings';
      case 2:
        return 'Profile';
      default:
        return 'Manager Dashboard';
    }
  }
}
