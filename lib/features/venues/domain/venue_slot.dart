import 'package:cloud_firestore/cloud_firestore.dart';

class VenueSlotData {
  final String venueId;
  final VenueConfig config;
  final List<BookedSlot> bookings;
  final List<HeldSlot> held;
  final List<BlockedSlot> blocked;
  final List<ReservedSlot> reserved;
  final Timestamp? updatedAt;

  VenueSlotData({
    required this.venueId,
    required this.config,
    required this.bookings,
    required this.held,
    required this.blocked,
    required this.reserved,
    this.updatedAt,
  });

  factory VenueSlotData.fromMap(Map<String, dynamic> map, String id) {
    return VenueSlotData(
      venueId: id,
      config: VenueConfig.fromMap(map['config'] ?? {}),
      bookings: (map['bookings'] as List<dynamic>?)
              ?.map((e) => BookedSlot.fromMap(e))
              .toList() ??
          [],
      held: (map['held'] as List<dynamic>?)
              ?.map((e) => HeldSlot.fromMap(e))
              .toList() ??
          [],
      blocked: (map['blocked'] as List<dynamic>?)
              ?.map((e) => BlockedSlot.fromMap(e))
              .toList() ??
          [],
      reserved: (map['reserved'] as List<dynamic>?)
              ?.map((e) => ReservedSlot.fromMap(e))
              .toList() ??
          [],
      updatedAt: map['updatedAt'],
    );
  }
}

class VenueConfig {
  final String startTime;
  final String endTime;
  final int slotDuration;
  final List<int> daysOfWeek;
  final String timezone;

  VenueConfig({
    required this.startTime,
    required this.endTime,
    required this.slotDuration,
    required this.daysOfWeek,
    required this.timezone,
  });

  factory VenueConfig.fromMap(Map<String, dynamic> map) {
    return VenueConfig(
      startTime: map['startTime'] ?? '06:00',
      endTime: map['endTime'] ?? '22:00',
      slotDuration: map['slotDuration'] ?? 60,
      daysOfWeek: List<int>.from(map['daysOfWeek'] ?? [0, 1, 2, 3, 4, 5, 6]),
      timezone: map['timezone'] ?? 'Asia/Kathmandu',
    );
  }
}

class BookedSlot {
  final String date;
  final String startTime;
  final String? userId;
  final String? bookingId;
  final String? bookingType;
  final String? status;
  final String? customerName;
  final String? customerPhone;
  final String? notes;

  BookedSlot({
    required this.date,
    required this.startTime,
    this.userId,
    this.bookingId,
    this.bookingType,
    this.status,
    this.customerName,
    this.customerPhone,
    this.notes,
  });

  factory BookedSlot.fromMap(Map<String, dynamic> map) {
    return BookedSlot(
      date: map['date'] ?? '',
      startTime: map['startTime'] ?? '',
      userId: map['userId'],
      bookingId: map['bookingId'],
      bookingType: map['bookingType'],
      status: map['status'],
      customerName: map['customerName'],
      customerPhone: map['customerPhone'],
      notes: map['notes'],
    );
  }
}

class HeldSlot {
  final String date;
  final String startTime;
  final String userId;
  final Timestamp holdExpiresAt;
  final String bookingId;
  final Timestamp createdAt;

  HeldSlot({
    required this.date,
    required this.startTime,
    required this.userId,
    required this.holdExpiresAt,
    required this.bookingId,
    required this.createdAt,
  });

  factory HeldSlot.fromMap(Map<String, dynamic> map) {
    return HeldSlot(
      date: map['date'] ?? '',
      startTime: map['startTime'] ?? '',
      userId: map['userId'] ?? '',
      holdExpiresAt: map['holdExpiresAt'] ?? Timestamp.now(),
      bookingId: map['bookingId'] ?? '',
      createdAt: map['createdAt'] ?? Timestamp.now(),
    );
  }
}

class BlockedSlot {
  final String date;
  final String startTime;
  final String? reason;
  final String blockedBy;
  final Timestamp blockedAt;

  BlockedSlot({
    required this.date,
    required this.startTime,
    this.reason,
    required this.blockedBy,
    required this.blockedAt,
  });

  factory BlockedSlot.fromMap(Map<String, dynamic> map) {
    return BlockedSlot(
      date: map['date'] ?? '',
      startTime: map['startTime'] ?? '',
      reason: map['reason'],
      blockedBy: map['blockedBy'] ?? '',
      blockedAt: map['blockedAt'] ?? Timestamp.now(),
    );
  }
}

class ReservedSlot {
  final String date;
  final String startTime;
  final String? note;
  final String reservedBy;
  final Timestamp reservedAt;

  ReservedSlot({
    required this.date,
    required this.startTime,
    this.note,
    required this.reservedBy,
    required this.reservedAt,
  });

  factory ReservedSlot.fromMap(Map<String, dynamic> map) {
    return ReservedSlot(
      date: map['date'] ?? '',
      startTime: map['startTime'] ?? '',
      note: map['note'],
      reservedBy: map['reservedBy'] ?? '',
      reservedAt: map['reservedAt'] ?? Timestamp.now(),
    );
  }
}
