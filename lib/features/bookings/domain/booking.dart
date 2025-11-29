import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String id;
  final String venueId;
  final String venueName;
  final String userId;
  final String date;
  final String startTime;
  final String endTime;
  final double amount;
  final String status; // 'pending', 'confirmed', 'cancelled', 'completed'
  final String? bookingType;
  final double? esewaAmount;
  final Timestamp? esewaInitiatedAt;
  final String? esewaStatus;
  final String? esewaTransactionCode;
  final String? esewaTransactionUuid;
  final Timestamp? paymentTimestamp;
  final Timestamp? verifiedAt;

  Booking({
    required this.id,
    required this.venueId,
    required this.venueName,
    required this.userId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.holdExpiresAt,
    this.bookingType,
    this.esewaAmount,
    this.esewaInitiatedAt,
    this.esewaStatus,
    this.esewaTransactionCode,
    this.esewaTransactionUuid,
    this.paymentTimestamp,
    this.verifiedAt,
  });

  // Computed property for UI compatibility
  String get paymentStatus => esewaStatus == 'COMPLETE' ? 'paid' : 'pending';
  String? get paymentId => esewaTransactionCode;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'venueId': venueId,
      'venueName': venueName,
      'userId': userId,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'amount': amount,
      'status': status,
      'createdAt': createdAt,
      'holdExpiresAt': holdExpiresAt,
      'bookingType': bookingType,
      'esewaAmount': esewaAmount,
      'esewaInitiatedAt': esewaInitiatedAt,
      'esewaStatus': esewaStatus,
      'esewaTransactionCode': esewaTransactionCode,
      'esewaTransactionUuid': esewaTransactionUuid,
      'paymentTimestamp': paymentTimestamp,
      'verifiedAt': verifiedAt,
    };
  }

  factory Booking.fromMap(Map<String, dynamic> map) {
    return Booking(
      id: map['id'] ?? '',
      venueId: map['venueId'] ?? '',
      venueName: map['venueName'] ?? '',
      userId: map['userId'] ?? '',
      date: map['date'] ?? '',
      startTime: map['startTime'] ?? '',
      endTime: map['endTime'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      status: map['status'] ?? 'pending',
      createdAt: map['createdAt'] ?? Timestamp.now(),
      holdExpiresAt: map['holdExpiresAt'],
      bookingType: map['bookingType'],
      esewaAmount: (map['esewaAmount'] ?? 0).toDouble(),
      esewaInitiatedAt: map['esewaInitiatedAt'],
      esewaStatus: map['esewaStatus'],
      esewaTransactionCode: map['esewaTransactionCode'],
      esewaTransactionUuid: map['esewaTransactionUuid'],
      paymentTimestamp: map['paymentTimestamp'],
      verifiedAt: map['verifiedAt'],
    );
  }
}
