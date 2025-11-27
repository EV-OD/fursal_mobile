import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/venue.dart';
import '../domain/review.dart';

final venueRepositoryProvider = Provider<VenueRepository>((ref) {
  return VenueRepository(FirebaseFirestore.instance);
});

final venuesProvider = StreamProvider<List<Venue>>((ref) {
  return ref.watch(venueRepositoryProvider).getVenues();
});

final venueProvider = StreamProvider.family<Venue?, String>((ref, id) {
  return ref.watch(venueRepositoryProvider).getVenue(id);
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

  Future<void> addReview(Review review) async {
    // Use a transaction or batch if we were updating the venue average rating here,
    // but the user said "rating is not saved it has to be calculated",
    // so we might just save the review.
    // However, to ensure "one review per user per venue", we use the composite ID.
    final docId = '${review.venueId}_${review.userId}';
    await _firestore.collection('reviews').doc(docId).set(review.toMap());
  }
}
