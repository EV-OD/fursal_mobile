import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../core/config.dart';
import 'logger_service.dart';

class BookingService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Map<String, dynamic>> holdSlot({
    required String venueId,
    required String slotId,
    required String date,
    required String startTime,
    required String bookingId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final idToken = await user.getIdToken();

    final uri = Uri.parse('${AppConfig.backendBaseUrl}/api/slots/hold');
    final bodyMap = {
      'venueId': venueId,
      'slotId': slotId,
      'date': date,
      'startTime': startTime,
      'bookingId': bookingId,
    };
    final body = jsonEncode(bodyMap);

    await LoggerService().info('holdSlot: request', meta: {
      'uri': uri.toString(),
      'body': bodyMap,
      'userId': user.uid,
    });

    final resp = await _postWithRedirects(uri, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $idToken',
    }, body: body);

    await LoggerService().info('holdSlot: response', meta: {
      'status': resp.statusCode,
      'body': resp.body,
    });

    // If slot not found, try again without slotId (some backends identify slots by venue/date/time)
    if (resp.statusCode == 404 && resp.body.contains('Slot not found')) {
      await LoggerService().info('holdSlot: slot not found with slotId, retrying without slotId', meta: {
        'originalBody': bodyMap,
        'status': resp.statusCode,
        'body': resp.body,
      });

      final fallbackBodyMap = Map<String, dynamic>.from(bodyMap)..remove('slotId');
      final fallbackBody = jsonEncode(fallbackBodyMap);
      final resp2 = await _postWithRedirects(uri, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      }, body: fallbackBody);

      await LoggerService().info('holdSlot: response (retry without slotId)', meta: {
        'status': resp2.statusCode,
        'body': resp2.body,
      });

      if (resp2.statusCode != 200 && resp2.statusCode != 201) {
        await LoggerService().error('holdSlot failed (retry)', meta: {
          'status': resp2.statusCode,
          'body': resp2.body,
        });
        throw Exception('Hold slot failed: ${resp2.statusCode} ${resp2.body}');
      }

      return jsonDecode(resp2.body) as Map<String, dynamic>;
    }

    if (resp.statusCode != 200 && resp.statusCode != 201) {
      await LoggerService().error('holdSlot failed', meta: {
        'status': resp.statusCode,
        'body': resp.body,
      });
      throw Exception('Hold slot failed: ${resp.statusCode} ${resp.body}');
    }

    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createBooking({
    required Map<String, dynamic> booking,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final idToken = await user.getIdToken();
    final uri = Uri.parse('${AppConfig.backendBaseUrl}/api/bookings');
    await LoggerService().info('createBooking: request', meta: {
      'uri': uri.toString(),
      'booking': booking,
      'userId': user.uid,
    });

    final resp = await _postWithRedirects(uri, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $idToken',
    }, body: jsonEncode(booking));

    await LoggerService().info('createBooking: response', meta: {
      'status': resp.statusCode,
      'body': resp.body,
    });

    if (resp.statusCode != 200 && resp.statusCode != 201) {
      await LoggerService().error('createBooking failed', meta: {
        'status': resp.statusCode,
        'body': resp.body,
      });
      throw Exception('Create booking failed: ${resp.statusCode} ${resp.body}');
    }

    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  /// Create booking via backend API using venueId and slotId.
  /// Returns the backend response (expected to include bookingId).
  Future<Map<String, dynamic>> createBookingViaApi({
    required String venueId,
    required String date,
    required String startTime,
    String? endTime,
    required double amount,
    Map<String, dynamic>? metadata,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final idToken = await user.getIdToken();
    final uri = Uri.parse('${AppConfig.backendBaseUrl}/api/bookings');
    final bodyMap = {
      'venueId': venueId,
      'date': date,
      'startTime': startTime,
      if (endTime != null) 'endTime': endTime,
      'amount': amount,
      if (metadata != null) 'metadata': metadata,
    };
    final body = jsonEncode(bodyMap);

    await LoggerService().info('createBookingViaApi: request', meta: {
      'uri': uri.toString(),
      'body': bodyMap,
      'userId': user.uid,
    });

    final resp = await _postWithRedirects(uri, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $idToken',
    }, body: body);

    await LoggerService().info('createBookingViaApi: response', meta: {
      'status': resp.statusCode,
      'body': resp.body,
    });
    if (resp.statusCode != 200 && resp.statusCode != 201 && resp.statusCode != 201) {
      await LoggerService().error('createBookingViaApi failed', meta: {
        'status': resp.statusCode,
        'body': resp.body,
      });
      String msg = resp.body;
      try {
        final parsed = jsonDecode(resp.body);
        if (parsed is Map && parsed['error'] != null) msg = parsed['error'].toString();
      } catch (_) {}
      throw Exception('Create booking failed: ${resp.statusCode} $msg');
    }

    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  /// Helper to POST while following redirect locations up to [maxRedirects].
  Future<http.Response> _postWithRedirects(Uri uri,
      {required Map<String, String> headers, required String body, int maxRedirects = 5}) async {
    Uri current = uri;
    for (int i = 0; i <= maxRedirects; i++) {
      final resp = await http.post(current, headers: headers, body: body);
      if (resp.statusCode == 307 || resp.statusCode == 302 || resp.statusCode == 301) {
        final loc = resp.headers['location'];
        if (loc == null) return resp;
        // Resolve relative redirect
        current = Uri.parse(loc).isAbsolute ? Uri.parse(loc) : current.resolve(loc);
        await LoggerService().info('redirect', meta: {'to': current.toString(), 'code': resp.statusCode});
        // continue loop to re-post to new location
        continue;
      }
      return resp;
    }
    throw Exception('Too many redirects');
  }
}
