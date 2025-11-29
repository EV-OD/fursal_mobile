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
import '../features/manager/presentation/manager_bookings_screen.dart';
import '../features/manager/presentation/manager_home_screen.dart';
import '../features/manager/presentation/manager_profile_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/venues/presentation/venue_detail_screen.dart';
import '../shared/widgets/manager_scaffold_with_navbar.dart';
import '../shared/widgets/scaffold_with_navbar.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorHomeKey = GlobalKey<NavigatorState>(debugLabel: 'shellHome');
final _shellNavigatorBookingKey = GlobalKey<NavigatorState>(debugLabel: 'shellBooking');
final _shellNavigatorProfileKey = GlobalKey<NavigatorState>(debugLabel: 'shellProfile');

final _shellNavigatorManagerHomeKey = GlobalKey<NavigatorState>(debugLabel: 'shellManagerHome');
final _shellNavigatorManagerBookingKey = GlobalKey<NavigatorState>(debugLabel: 'shellManagerBooking');
final _shellNavigatorManagerProfileKey = GlobalKey<NavigatorState>(debugLabel: 'shellManagerProfile');

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
      // Manager Shell Route
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ManagerScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellNavigatorManagerHomeKey,
            routes: [
              GoRoute(
                path: '/manager/home',
                builder: (context, state) => const ManagerHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorManagerBookingKey,
            routes: [
              GoRoute(
                path: '/manager/bookings',
                builder: (context, state) => const ManagerBookingsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorManagerProfileKey,
            routes: [
              GoRoute(
                path: '/manager/profile',
                builder: (context, state) => const ManagerProfileScreen(),
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
                    path: 'venue/:id', // Note: relative path, so it becomes /home/venue/:id
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
            return '/manager/home';
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
