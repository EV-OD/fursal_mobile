import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/booking.dart';

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository(FirebaseFirestore.instance);
});

final userBookingsProvider = StreamProvider.family<List<Booking>, String>((ref, userId) {
  return ref.watch(bookingRepositoryProvider).getUserBookings(userId);
});

class BookingRepository {
  final FirebaseFirestore _firestore;

  BookingRepository(this._firestore);

  Future<void> createBooking(Booking booking) async {
    await _firestore.collection('bookings').doc(booking.id).set(booking.toMap());
  }

  Future<void> updateBookingStatus(String bookingId, String status, {
    Booking? booking, 
    Map<String, dynamic>? esewaData,
  }) async {
    if (status == 'booked' && booking != null) {
      // Use transaction to update both booking and venueSlots
      await _firestore.runTransaction((transaction) async {
        final bookingRef = _firestore.collection('bookings').doc(bookingId);
        final venueRef = _firestore.collection('venueSlots').doc(booking.venueId);

        // Update booking
        final updateData = <String, dynamic>{
          'status': status,
        };
        if (esewaData != null) {
          updateData.addAll(esewaData);
        }
        transaction.update(bookingRef, updateData);

        // Update venueSlots
        final venueSnapshot = await transaction.get(venueRef);
        if (venueSnapshot.exists) {
          final data = venueSnapshot.data()!;
          final held = List<Map<String, dynamic>>.from(data['held'] ?? []);
          final bookings = List<Map<String, dynamic>>.from(data['bookings'] ?? []);

          // Remove from held
          held.removeWhere((h) => 
            h['date'] == booking.date && 
            h['startTime'] == booking.startTime
          );

          // Add to bookings
          bookings.add({
            'date': booking.date,
            'startTime': booking.startTime,
            'userId': booking.userId,
            'bookingId': bookingId,
            'status': 'booked',
            'bookingType': 'mobile',
          });

          transaction.update(venueRef, {
            'held': held,
            'bookings': bookings,
          });
        }
      });
    } else {
      final updateData = <String, dynamic>{
        'status': status,
      };
      if (esewaData != null) {
        updateData.addAll(esewaData);
      }
      await _firestore.collection('bookings').doc(bookingId).update(updateData);
    }
  }

  Future<void> checkAndExpireBookings(String userId) async {
    final now = DateTime.now();
    final snapshot = await _firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .get();

    final batch = _firestore.batch();
    bool hasUpdates = false;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final holdExpiresAt = (data['holdExpiresAt'] as Timestamp?)?.toDate();

      if (holdExpiresAt != null && holdExpiresAt.isBefore(now)) {
        batch.update(doc.reference, {'status': 'expired'});
        hasUpdates = true;
        
        // Also remove from held slots in venueSlots if needed
        // Ideally we should do this, but for now let's just expire the booking.
        // The held slot in venueSlots also has an expiry, so it will be ignored by getVenueSlots logic anyway.
      }
    }

    if (hasUpdates) {
      await batch.commit();
    }
  }

  Stream<List<Booking>> getUserBookings(String userId) {
    return _firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Booking.fromMap(doc.data())).toList();
    });
  }
}
