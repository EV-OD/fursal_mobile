import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/venue_repository.dart';
import 'add_review_dialog.dart';
import '../../../../core/theme.dart';

class ReviewSection extends ConsumerWidget {
  final String venueId;

  const ReviewSection({super.key, required this.venueId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(venueReviewsProvider(venueId));

    return reviewsAsync.when(
      data: (reviews) {
        final averageRating = reviews.isEmpty 
            ? 0.0 
            : reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Reviews (${reviews.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AddReviewDialog(venueId: venueId),
                    );
                  },
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Write a Review'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Rating Summary
            if (reviews.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Text(
                      averageRating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.secondaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              index < averageRating.round() 
                                  ? Icons.star_rounded 
                                  : Icons.star_outline_rounded,
                              color: Colors.amber,
                              size: 20,
                            );
                          }),
                        ),
                        Text(
                          'Based on ${reviews.length} reviews',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 24),

            // Reviews List
            if (reviews.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'No reviews yet',
                        style: TextStyle(color: Colors.grey[500], fontSize: 16),
                      ),
                      Text(
                        'Be the first to share your experience!',
                        style: TextStyle(color: Colors.grey[400], fontSize: 14),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: reviews.length,
                separatorBuilder: (context, index) => const Divider(height: 32),
                itemBuilder: (context, index) {
                  final review = reviews[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                            backgroundImage: review.userPhotoUrl != null 
                                ? NetworkImage(review.userPhotoUrl!) 
                                : null,
                            child: review.userPhotoUrl == null 
                                ? Text(
                                    (review.userName?.isNotEmpty == true ? review.userName![0] : 'U').toUpperCase(),
                                    style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                                  ) 
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  review.userName ?? 'User',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Row(
                                  children: [
                                    ...List.generate(5, (starIndex) {
                                      return Icon(
                                        starIndex < review.rating 
                                            ? Icons.star_rounded 
                                            : Icons.star_outline_rounded,
                                        color: Colors.amber,
                                        size: 14,
                                      );
                                    }),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatDate(review.createdAt),
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        review.comment,
                        style: TextStyle(
                          color: Colors.grey[700],
                          height: 1.5,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  );
                },
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Text('Error loading reviews: $err'),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
