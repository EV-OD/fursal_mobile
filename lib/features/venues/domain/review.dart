import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String venueId;
  final String userId;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final String? userName;
  final String? userPhotoUrl;

  Review({
    required this.id,
    required this.venueId,
    required this.userId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.userName,
    this.userPhotoUrl,
  });

  factory Review.fromMap(Map<String, dynamic> map, String id) {
    return Review(
      id: id,
      venueId: map['venueId'] ?? '',
      userId: map['userId'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      comment: map['comment'] ?? '',
      createdAt: map['createdAt'] is Timestamp 
          ? (map['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      userName: map['userName'],
      userPhotoUrl: map['userPhotoUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'venueId': venueId,
      'userId': userId,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
    };
  }
}
