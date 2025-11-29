import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/venue.dart';
import '../domain/review.dart';
import '../domain/venue_slot.dart';

final venueRepositoryProvider = Provider<VenueRepository>((ref) {
  return VenueRepository(FirebaseFirestore.instance);
});

final venuesProvider = StreamProvider<List<Venue>>((ref) {
  return ref.watch(venueRepositoryProvider).getVenues();
});

final venueProvider = StreamProvider.family<Venue?, String>((ref, id) {
  return ref.watch(venueRepositoryProvider).getVenue(id);
});

final venueSlotsProvider = StreamProvider.family<VenueSlotData?, String>((ref, venueId) {
  return ref.watch(venueRepositoryProvider).getVenueSlots(venueId);
});

final venueReviewsProvider = StreamProvider.family<List<Review>, String>((ref, venueId) {
  return ref.watch(venueRepositoryProvider).getReviews(venueId);
});

class VenueRepository {
  final FirebaseFirestore _firestore;

  VenueRepository(this._firestore);

  Stream<List<Venue>> getVenues() {
    return _firestore.collection('venues').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Venue.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Stream<Venue?> getVenue(String id) {
    return _firestore.collection('venues').doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Venue.fromMap(doc.data()!, doc.id);
    });
  }

  Stream<List<Review>> getReviews(String venueId) {
    return _firestore
        .collection('reviews')
        .where('venueId', isEqualTo: venueId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Review.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Stream<VenueSlotData?> getVenueSlots(String venueId) {
    return _firestore.collection('venueSlots').doc(venueId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return VenueSlotData.fromMap(doc.data()!, doc.id);
    });
  }

  Future<void> addReview(Review review) async {
    // Use a transaction or batch if we were updating the venue average rating here,
    // but the user said "rating is not saved it has to be calculated",
    // so we might just save the review.
    // However, to ensure "one review per user per venue", we use the composite ID.
    final docId = '${review.venueId}_${review.userId}';
    await _firestore.collection('reviews').doc(docId).set(review.toMap());
  }

  Future<void> holdSlot(String venueId, HeldSlot heldSlot) async {
    final docRef = _firestore.collection('venueSlots').doc(venueId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) {
        throw Exception("Venue slots not found");
      }

      final data = VenueSlotData.fromMap(snapshot.data()!, snapshot.id);

      // Check if slot is already booked or blocked
      bool isBooked = data.bookings.any((b) =>
          b.date == heldSlot.date &&
          b.startTime == heldSlot.startTime &&
          b.status != 'cancelled');

      bool isBlocked = data.blocked.any((b) =>
          b.date == heldSlot.date &&
          b.startTime == heldSlot.startTime);

      bool isHeld = data.held.any((h) =>
          h.date == heldSlot.date &&
          h.startTime == heldSlot.startTime &&
          h.holdExpiresAt.toDate().isAfter(DateTime.now()));

      if (isBooked || isBlocked || isHeld) {
        throw Exception("Slot is no longer available");
      }

      List<HeldSlot> currentHeld = List.from(data.held);
      // Remove expired holds for this slot if any (though isHeld check handles valid ones)
      currentHeld.removeWhere((h) =>
          h.date == heldSlot.date &&
          h.startTime == heldSlot.startTime);

      currentHeld.add(heldSlot);

      transaction.update(docRef, {
        'held': currentHeld.map((e) => {
          'date': e.date,
          'startTime': e.startTime,
          'userId': e.userId,
          'holdExpiresAt': e.holdExpiresAt,
          'bookingId': e.bookingId,
          'createdAt': e.createdAt,
        }).toList(),
      });
    });
  }
}
