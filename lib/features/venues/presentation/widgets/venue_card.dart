import 'package:flutter/material.dart';
import '../../domain/venue.dart';

class VenueCard extends StatelessWidget {
  final Venue venue;
  final VoidCallback onSeeDetails;
  final VoidCallback onViewOnMap;

  const VenueCard({
    super.key,
    required this.venue,
    required this.onSeeDetails,
    required this.onViewOnMap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              venue.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            if (venue.reviewCount > 0)
              Row(
                children: [
                  const Icon(Icons.star, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    '${venue.averageRating.toStringAsFixed(1)} (${venue.reviewCount})',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              )
            else
              Text(
                'No ratings yet',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            const SizedBox(height: 16),
            if (venue.address != null)
              Text(
                venue.address!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: onSeeDetails,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('See Details'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: onViewOnMap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F1F1F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('View on Map'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
