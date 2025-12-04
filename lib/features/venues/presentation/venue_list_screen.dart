import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/venue_repository.dart';
import '../domain/venue.dart';
import 'widgets/venue_card.dart';
import 'widgets/venue_map_view.dart';

class VenueListScreen extends ConsumerStatefulWidget {
  const VenueListScreen({super.key});

  @override
  ConsumerState<VenueListScreen> createState() => _VenueListScreenState();
}

class _VenueListScreenState extends ConsumerState<VenueListScreen> {
  bool _isMapView = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Filter & Sort State
  RangeValues _priceRange = const RangeValues(0, 5000);
  final double _maxPrice = 5000;
  final double _minPrice = 0;
  final Set<String> _selectedAmenities = {};
  String _sortOption = 'rating'; // 'rating', 'price_low', 'price_high'

  // Available amenities for filtering (could be dynamic in real app)
  final List<String> _availableAmenities = [
    'Parking',
    'Changing Room',
    'Shower',
    'Canteen',
    'Floodlights',
    'Lockers'
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final venuesAsync = ref.watch(venuesProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Toggle Buttons
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isMapView = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_isMapView
                            ? const Color(0xFF1F1F1F)
                            : Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          bottomLeft: Radius.circular(8),
                        ),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.list,
                            color: !_isMapView ? Colors.white : Colors.black,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'List',
                            style: TextStyle(
                              color: !_isMapView ? Colors.white : Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isMapView = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color:
                            _isMapView ? const Color(0xFF1F1F1F) : Colors.white,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.map_outlined,
                            color: _isMapView ? Colors.white : Colors.black,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Map',
                            style: TextStyle(
                              color: _isMapView ? Colors.white : Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search Bar & Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search by name...',
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF00C853)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _showFilterBottomSheet,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                      color: (_selectedAmenities.isNotEmpty ||
                              _priceRange.start > _minPrice ||
                              _priceRange.end < _maxPrice)
                          ? const Color(0xFFE8F5E9)
                          : Colors.white,
                    ),
                    child: Icon(Icons.filter_list,
                        size: 24,
                        color: (_selectedAmenities.isNotEmpty ||
                                _priceRange.start > _minPrice ||
                                _priceRange.end < _maxPrice)
                            ? const Color(0xFF00C853)
                            : Colors.black),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Content
          Expanded(
            child: venuesAsync.when(
              data: (venues) {
                // 1. Filter
                var filteredVenues = venues.where((venue) {
                  // Search query
                  if (_searchQuery.isNotEmpty &&
                      !venue.name
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase())) {
                    return false;
                  }
                  // Price range
                  if (venue.pricePerHour < _priceRange.start ||
                      venue.pricePerHour > _priceRange.end) {
                    return false;
                  }
                  // Amenities
                  if (_selectedAmenities.isNotEmpty) {
                    // Check if venue has ALL selected amenities (AND logic)
                    // Or ANY (OR logic) - usually AND is better for filtering
                    for (var amenity in _selectedAmenities) {
                      // Simple check: key contains amenity string
                      bool hasAmenity = venue.attributes.keys.any((key) =>
                          key.toLowerCase().contains(amenity.toLowerCase()));
                      if (!hasAmenity) return false;
                    }
                  }
                  return true;
                }).toList();

                // 2. Sort
                filteredVenues.sort((a, b) {
                  switch (_sortOption) {
                    case 'price_low':
                      return a.pricePerHour.compareTo(b.pricePerHour);
                    case 'price_high':
                      return b.pricePerHour.compareTo(a.pricePerHour);
                    case 'rating':
                    default:
                      return b.averageRating.compareTo(a.averageRating);
                  }
                });

                if (_isMapView) {
                  return VenueMapView(
                    venues: filteredVenues,
                    onVenueSelected: (venue) {
                      _showVenuePreview(context, venue);
                    },
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Available Venues (${filteredVenues.length})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          // Sort Dropdown (Mini)
                          DropdownButton<String>(
                            value: _sortOption,
                            underline: const SizedBox(),
                            icon: const Icon(Icons.sort, size: 16),
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _sortOption = newValue;
                                });
                              }
                            },
                            items: const [
                              DropdownMenuItem(
                                  value: 'rating', child: Text('Top Rated')),
                              DropdownMenuItem(
                                  value: 'price_low',
                                  child: Text('Price: Low to High')),
                              DropdownMenuItem(
                                  value: 'price_high',
                                  child: Text('Price: High to Low')),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredVenues.length,
                        itemBuilder: (context, index) {
                          final venue = filteredVenues[index];
                          return VenueCard(
                            venue: venue,
                            onSeeDetails: () =>
                                context.go('/home/venue/${venue.id}'),
                            onViewOnMap: () {
                              setState(() {
                                _isMapView = true;
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filters',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _priceRange = RangeValues(_minPrice, _maxPrice);
                            _selectedAmenities.clear();
                            _sortOption = 'rating';
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Sort By
                  const Text('Sort By',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildSortChip(setModalState, 'Top Rated', 'rating'),
                      _buildSortChip(
                          setModalState, 'Price: Low to High', 'price_low'),
                      _buildSortChip(
                          setModalState, 'Price: High to Low', 'price_high'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Price Range
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Price Range',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16)),
                      Text(
                        'Rs. ${_priceRange.start.round()} - Rs. ${_priceRange.end.round()}',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  RangeSlider(
                    values: _priceRange,
                    min: _minPrice,
                    max: _maxPrice,
                    divisions: 50,
                    activeColor: const Color(0xFF00C853),
                    labels: RangeLabels(
                      _priceRange.start.round().toString(),
                      _priceRange.end.round().toString(),
                    ),
                    onChanged: (values) {
                      setModalState(() {
                        _priceRange = values;
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // Amenities
                  const Text('Amenities',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableAmenities.map((amenity) {
                      final isSelected = _selectedAmenities.contains(amenity);
                      return FilterChip(
                        label: Text(amenity),
                        selected: isSelected,
                        selectedColor: const Color(0xFF00C853).withAlpha(51),
                        checkmarkColor: const Color(0xFF00C853),
                        onSelected: (selected) {
                          setModalState(() {
                            if (selected) {
                              _selectedAmenities.add(amenity);
                            } else {
                              _selectedAmenities.remove(amenity);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {}); // Apply filters
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1F1F1F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Apply Filters'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSortChip(StateSetter setModalState, String label, String value) {
    final isSelected = _sortOption == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFF00C853).withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF00C853) : Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (selected) {
        if (selected) {
          setModalState(() {
            _sortOption = value;
          });
        }
      },
    );
  }

  void _showVenuePreview(BuildContext context, Venue venue) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            VenueCard(
              venue: venue,
              onSeeDetails: () {
                Navigator.pop(context);
                context.go('/home/venue/${venue.id}');
              },
              onViewOnMap: () {
                Navigator.pop(context);
                // Already on map
              },
            ),
          ],
        ),
      ),
    );
  }
}
