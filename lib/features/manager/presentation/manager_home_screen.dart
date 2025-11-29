import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_repository.dart';
import '../../venues/data/venue_repository.dart';
import '../../../shared/widgets/venue_list_card.dart';
import '../../../core/theme.dart';

class ManagerHomeScreen extends ConsumerWidget {
  const ManagerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venuesAsync = ref.watch(venuesProvider);
    final authState = ref.watch(authStateProvider);
    final userId = authState.value?.uid;

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // AppBar is handled by ManagerScaffoldWithNavBar
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Navigate to add venue screen
        },
        label: const Text('Add Venue'),
        icon: const Icon(Icons.add),
        backgroundColor: theme.primaryColor,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: venuesAsync.when(
        data: (venues) {
          // Filter venues managed by current user
          final myVenues = venues.where((v) => v.managedBy == userId).toList();

          if (myVenues.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.store_mall_directory_outlined, size: 64, color: AppTheme.textSecondary),
                  const SizedBox(height: 16),
                  Text(
                    'No venues managed yet',
                    style: theme.textTheme.titleLarge?.copyWith(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your first venue to get started',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: myVenues.length,
            itemBuilder: (context, index) {
              final venue = myVenues[index];
              return VenueListCard(
                venue: venue,
                onTap: () {
                  // TODO: Navigate to manager venue detail/edit
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
