import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/booking_repository.dart';
import '../domain/booking.dart';
import 'payment_screen.dart';
import 'booking_detail_screen.dart';

class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  @override
  void initState() {
    super.initState();
    // Check for expired bookings when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        ref.read(bookingRepositoryProvider).checkAndExpireBookings(user.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
          body: Center(child: Text('Please login to view bookings')));
    }

    final bookingsAsync = ref.watch(userBookingsProvider(user.uid));

    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: bookingsAsync.when(
        data: (bookings) {
          if (bookings.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No bookings yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBookingSection(context, 'Upcoming Bookings',
                    _getUpcomingBookings(bookings)),
                _buildBookingSection(
                    context, 'Completed', _getCompletedBookings(bookings)),
                _buildBookingSection(context, 'Payment Not Found',
                    _getPaymentPendingBookings(bookings)),
                _buildBookingSection(context, 'Cancelled & Expired',
                    _getCancelledExpiredBookings(bookings)),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  List<Booking> _getUpcomingBookings(List<Booking> bookings) {
    final now = DateTime.now();
    return bookings.where((b) {
      final startDateTime = _parseDateTime(b.date, b.startTime);
      final isBooked = b.status == 'booked' || b.status == 'confirmed';
      return isBooked && startDateTime.isAfter(now);
    }).toList();
  }

  List<Booking> _getCompletedBookings(List<Booking> bookings) {
    final now = DateTime.now();
    return bookings.where((b) {
      final endDateTime = _parseDateTime(b.date, b.endTime);
      final isBooked = b.status == 'booked' || b.status == 'confirmed';
      return isBooked && endDateTime.isBefore(now);
    }).toList();
  }

  List<Booking> _getPaymentPendingBookings(List<Booking> bookings) {
    final now = DateTime.now();
    return bookings.where((b) {
      final endDateTime = _parseDateTime(b.date, b.endTime);
      final isPending = b.status == 'pending';
      final isHoldValid =
          b.holdExpiresAt == null || b.holdExpiresAt!.toDate().isAfter(now);
      // It is pending payment if status is pending, hold is valid (or null), AND slot hasn't passed
      return isPending && isHoldValid && endDateTime.isAfter(now);
    }).toList();
  }

  List<Booking> _getCancelledExpiredBookings(List<Booking> bookings) {
    final now = DateTime.now();
    return bookings.where((b) {
      final endDateTime = _parseDateTime(b.date, b.endTime);
      final isCancelled = b.status == 'cancelled';
      final isExplicitlyExpired = b.status == 'expired';

      final isPendingButExpired = b.status == 'pending' &&
          ((b.holdExpiresAt != null &&
                  b.holdExpiresAt!.toDate().isBefore(now)) ||
              endDateTime.isBefore(now) // Slot passed but still pending
          );

      return isCancelled || isExplicitlyExpired || isPendingButExpired;
    }).toList();
  }

  DateTime _parseDateTime(String date, String time) {
    try {
      return DateTime.parse('$date $time:00');
    } catch (e) {
      return DateTime.now(); // Fallback
    }
  }

  Widget _buildBookingSection(
      BuildContext context, String title, List<Booking> bookings) {
    if (bookings.isEmpty) return const SizedBox.shrink();

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
        ),
        children: bookings.map((booking) {
          final isExpired = booking.status == 'expired' ||
              (booking.status == 'pending' &&
                  booking.holdExpiresAt != null &&
                  booking.holdExpiresAt!.toDate().isBefore(DateTime.now()));

          final endDateTime = _parseDateTime(booking.date, booking.endTime);
          final isTimePassed = endDateTime.isBefore(DateTime.now());
          final effectiveExpired =
              isExpired || (booking.status == 'pending' && isTimePassed);
          final isCompleted =
              (booking.status == 'booked' || booking.status == 'confirmed') &&
                  isTimePassed;

          // Determine card style based on status
          Color? cardColor;
          Color? textColor;
          if (effectiveExpired || booking.status == 'cancelled') {
            cardColor = Colors.grey.shade200;
            textColor = Colors.grey.shade700;
          } else if (isCompleted) {
            cardColor = Colors.green.shade50;
            textColor = Colors.green.shade900;
          }

          return Card(
            color: cardColor,
            elevation:
                (effectiveExpired || booking.status == 'cancelled') ? 0 : 2,
            margin: const EdgeInsets.only(bottom: 16, left: 4, right: 4),
            child: InkWell(
              onTap: (effectiveExpired || booking.status == 'cancelled')
                  ? null
                  : () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              BookingDetailScreen(booking: booking),
                        ),
                      );
                    },
              child: ListTile(
                title: Text(
                  booking.venueName,
                  style:
                      TextStyle(color: textColor, fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${booking.date} at ${booking.startTime}',
                      style: TextStyle(color: textColor),
                    ),
                    if (!isCompleted) ...[
                      Text(
                        effectiveExpired
                            ? 'Status: Expired'
                            : 'Status: ${booking.status}',
                        style: TextStyle(
                          color: effectiveExpired ? Colors.grey : textColor,
                        ),
                      ),
                      if (!effectiveExpired && booking.status != 'cancelled')
                        Text(
                          'Payment: ${booking.paymentStatus}',
                          style: TextStyle(
                            color: booking.paymentStatus == 'paid'
                                ? Colors.green
                                : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ] else
                      const Text(
                        'Status: Completed',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
                trailing: (booking.paymentStatus == 'pending' &&
                        !effectiveExpired &&
                        !isCompleted &&
                        booking.status != 'cancelled')
                    ? ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  PaymentScreen(booking: booking),
                            ),
                          );
                        },
                        child: const Text('Pay'),
                      )
                    : Icon(Icons.chevron_right, color: textColor),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
