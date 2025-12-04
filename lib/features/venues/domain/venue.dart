import 'package:cloud_firestore/cloud_firestore.dart';

class Venue {
  final String id;
  final String name;
  final String? description;
  final double latitude;
  final double longitude;
  final String? address;
  final List<String> imageUrls;
  final double pricePerHour;
  final Map<String, String> attributes;
  final String createdAt;
  final String managedBy;
  final double averageRating;
  final int reviewCount;

  const Venue({
    required this.id,
    required this.name,
    this.description,
    required this.latitude,
    required this.longitude,
    this.address,
    required this.imageUrls,
    required this.pricePerHour,
    required this.attributes,
    required this.createdAt,
    required this.managedBy,
    this.averageRating = 0.0,
    this.reviewCount = 0,
  });

  factory Venue.fromMap(Map<String, dynamic> map, String id) {
    String createdAtStr = '';
    if (map['createdAt'] is Timestamp) {
      createdAtStr = (map['createdAt'] as Timestamp).toDate().toIso8601String();
    } else if (map['createdAt'] is String) {
      createdAtStr = map['createdAt'];
    }

    return Venue(
      id: id,
      name: map['name'] ?? '',
      description: map['description'],
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      address: map['address'],
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      pricePerHour: (map['pricePerHour'] ?? 0.0).toDouble(),
      attributes: Map<String, String>.from(map['attributes'] ?? {}),
      createdAt: createdAtStr,
      managedBy: map['managedBy'] ?? '',
      averageRating: (map['averageRating'] ?? 0.0).toDouble(),
      reviewCount: (map['reviewCount'] ?? 0).toInt(),
    );
  }
}
