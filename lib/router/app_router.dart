import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/presentation/get_started_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/bookings/presentation/booking_screen.dart';
import '../features/bookings/presentation/slot_selection_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/manager/presentation/create_venue_screen.dart';
import '../features/manager/presentation/manager_bookings_screen.dart';
import '../features/manager/presentation/manager_dashboard_screen.dart';

import '../features/manager/presentation/manager_home_screen.dart';
import '../features/manager/presentation/manager_scan_qr_screen.dart';
import '../features/notifications/presentation/notification_screen.dart';
import '../features/profile/presentation/edit_profile_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/venues/presentation/venue_detail_screen.dart';
import '../features/venues/presentation/venue_list_screen.dart';
import '../shared/widgets/manager_scaffold_with_navbar.dart';
import '../shared/widgets/scaffold_with_navbar.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorHomeKey =
    GlobalKey<NavigatorState>(debugLabel: 'shellHome');
final _shellNavigatorBookingKey =
    GlobalKey<NavigatorState>(debugLabel: 'shellBooking');
final _shellNavigatorProfileKey =
    GlobalKey<NavigatorState>(debugLabel: 'shellProfile');
final _shellNavigatorVenuesKey =
    GlobalKey<NavigatorState>(debugLabel: 'shellVenues');

final _shellNavigatorManagerDashboardKey =
    GlobalKey<NavigatorState>(debugLabel: 'shellManagerDashboard');
final _shellNavigatorManagerBookingKey =
    GlobalKey<NavigatorState>(debugLabel: 'shellManagerBooking');
final _shellNavigatorManagerPaymentsKey =
    GlobalKey<NavigatorState>(debugLabel: 'shellManagerPayments');
final _shellNavigatorManagerVenuesKey =
    GlobalKey<NavigatorState>(debugLabel: 'shellManagerVenues');
final _shellNavigatorManagerScanQRKey =
    GlobalKey<NavigatorState>(debugLabel: 'shellManagerScanQR');

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/get-started',
        builder: (context, state) => const GetStartedScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationScreen(),
      ),
      // Manager Shell Route
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ManagerScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          // 1. Dashboard
          StatefulShellBranch(
            navigatorKey: _shellNavigatorManagerDashboardKey,
            routes: [
              GoRoute(
                path: '/manager/dashboard',
                builder: (context, state) => const ManagerDashboardScreen(),
              ),
            ],
          ),
          // 2. Bookings
          StatefulShellBranch(
            navigatorKey: _shellNavigatorManagerBookingKey,
            routes: [
              GoRoute(
                path: '/manager/bookings',
                builder: (context, state) => const ManagerBookingsScreen(),
              ),
            ],
          ),
          // 3. Payments (Placeholder)
          StatefulShellBranch(
            navigatorKey: _shellNavigatorManagerPaymentsKey,
            routes: [
              GoRoute(
                path: '/manager/payments',
                builder: (context, state) => const Scaffold(
                  body: Center(child: Text('Payments - Coming Soon')),
                ),
              ),
            ],
          ),
          // 4. My Venues
          StatefulShellBranch(
            navigatorKey: _shellNavigatorManagerVenuesKey,
            routes: [
              GoRoute(
                path: '/manager/venues',
                builder: (context, state) =>
                    const ManagerHomeScreen(), // Reusing this as it lists venues
                routes: [
                  GoRoute(
                    path: 'create-venue',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const CreateVenueScreen(),
                  ),
                ],
              ),
            ],
          ),
          // 5. Scan QR (Placeholder)
          StatefulShellBranch(
            navigatorKey: _shellNavigatorManagerScanQRKey,
            routes: [
              GoRoute(
                path: '/manager/scan-qr',
                builder: (context, state) => const ManagerScanQRScreen(),
              ),
            ],
          ),
        ],
      ),
      // User Shell Route
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellNavigatorHomeKey,
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path:
                        'venue/:id', // Note: relative path, so it becomes /home/venue/:id
                    parentNavigatorKey: _rootNavigatorKey, // Hide bottom nav
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return VenueDetailScreen(venueId: id);
                    },
                    routes: [
                      GoRoute(
                        path: 'booking',
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) {
                          final id = state.pathParameters['id']!;
                          final extra = state.extra as Map<String, dynamic>;
                          return SlotSelectionScreen(
                            venueId: id,
                            venueName: extra['venueName'] as String,
                            pricePerHour: extra['pricePerHour'] as double,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorVenuesKey,
            routes: [
              GoRoute(
                path: '/venues',
                builder: (context, state) => const VenueListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorBookingKey,
            routes: [
              GoRoute(
                path: '/bookings',
                builder: (context, state) => const BookingScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorProfileKey,
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'edit',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const EditProfileScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final hasError = authState.hasError;
      final isLoggedIn = authState.valueOrNull != null;
      final isSplash = state.uri.toString() == '/';
      final isGetStarted = state.uri.toString() == '/get-started';
      final isLoggingIn = state.uri.toString() == '/login';

      if (isLoading || hasError) return null;

      if (isLoggedIn) {
        // If logged in and trying to access auth pages or splash, redirect to home
        if (isSplash || isGetStarted || isLoggingIn) {
          final role = authState.value?.role;
          if (role == 'manager') {
            return '/manager/dashboard';
          }
          return '/home';
        }
      } else {
        // If not logged in
        if (isSplash) {
          return '/get-started';
        }

        // If trying to access protected pages, redirect to get started
        if (!isGetStarted && !isLoggingIn) {
          return '/get-started';
        }
      }

      return null;
    },
  );
});
