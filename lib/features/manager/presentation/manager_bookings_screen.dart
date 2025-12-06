import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../bookings/data/booking_repository.dart';
import '../../bookings/domain/booking.dart';
import '../../auth/data/auth_repository.dart';
import '../../venues/data/venue_repository.dart';
import '../../../core/theme.dart';

class ManagerBookingsScreen extends ConsumerStatefulWidget {
  const ManagerBookingsScreen({super.key});

  @override
  ConsumerState<ManagerBookingsScreen> createState() =>
      _ManagerBookingsScreenState();
}

class _ManagerBookingsScreenState extends ConsumerState<ManagerBookingsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context); // Unused
    final authState = ref.watch(authStateProvider);
    final userId = authState.value?.uid;

    if (userId == null) {
      return const Center(child: Text('Not logged in'));
    }

    final venuesAsync = ref.watch(venuesProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Manage Bookings',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: venuesAsync.when(
        data: (allVenues) {
          final myVenues =
              allVenues.where((v) => v.managedBy == userId).toList();
          final myVenueIds = myVenues.map((v) => v.id).toList();

          if (myVenueIds.isEmpty) {
            return const Center(
                child: Text('No venues found. Create a venue first.'));
          }

          // Debug prints
          print('Manager ID: $userId');
          print('Managed Venue IDs: $myVenueIds');

          final bookingsAsync = ref.watch(managerBookingsProvider(myVenueIds));

          return bookingsAsync.when(
            data: (bookings) {
              final filteredBookings = bookings.where((booking) {
                if (_searchQuery.isEmpty) return true;
                final query = _searchQuery.toLowerCase();
                return booking.venueName.toLowerCase().contains(query) ||
                    booking.date.contains(query) ||
                    booking.status.toLowerCase().contains(query);
              }).toList();

              return Column(
                children: [
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search bookings...',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        prefixIcon:
                            Icon(Icons.search, color: Colors.grey.shade400),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: AppTheme.primaryColor, width: 1),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: filteredBookings.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.calendar_today_outlined,
                                    size: 60, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isEmpty
                                      ? 'No bookings found'
                                      : 'No matching bookings',
                                  style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 16),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: filteredBookings.length,
                            physics: const BouncingScrollPhysics(),
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _BookingCard(
                                    booking: filteredBookings[index]),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;

  const _BookingCard({required this.booking});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
      case 'cancelled (user)':
      case 'expired':
        return Colors.red;
      case 'booked':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(booking.status);
    final isConfirmed = booking.status.toLowerCase() == 'confirmed' ||
        booking.status.toLowerCase() == 'booked';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Date & Status
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 14, color: Colors.grey.shade700),
                      const SizedBox(width: 6),
                      Text(
                        booking.date,
                        style: TextStyle(
                            color: Colors.grey.shade800,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    booking.status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFEEEEEE)),

          // Body: Venue & Time
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.venueName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _InfoItem(
                        icon: Icons.access_time,
                        label: 'Time',
                        value: '${booking.startTime} - ${booking.endTime}',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _InfoItem(
                        icon: Icons.payments_outlined,
                        label: 'Amount',
                        value: 'Rs. ${booking.amount}',
                        isAmount: true,
                        valueColor: isConfirmed ? Colors.green : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (isConfirmed) ...[
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Mark Paid'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.green,
                      textStyle: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            )
          ],
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isAmount;
  final Color? valueColor;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    this.isAmount = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: Colors.grey.shade500),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: valueColor ?? Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
