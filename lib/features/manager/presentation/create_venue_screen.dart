import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme.dart';

class CreateVenueScreen extends ConsumerStatefulWidget {
  const CreateVenueScreen({super.key});

  @override
  ConsumerState<CreateVenueScreen> createState() => _CreateVenueScreenState();
}

class _CreateVenueScreenState extends ConsumerState<CreateVenueScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // State variables for form fields
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  LatLng? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Create New Venue',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryColor,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Basic Info'),
            Tab(text: 'Location'),
            Tab(text: 'Slot Config'),
            Tab(text: 'Images'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics:
            const NeverScrollableScrollPhysics(), // Prevent swiping to force validation if needed
        children: [
          _buildBasicInfoStep(),
          _buildLocationStep(),
          const Center(child: Text('Slot Config Step - Coming Soon')),
          const Center(child: Text('Images Step - Coming Soon')),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () {
            if (_tabController.index < 3) {
              _tabController.animateTo(_tabController.index + 1);
            } else {
              // Submit form
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black87,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            _tabController.index < 3
                ? 'Next: ${_getNextStepName()}'
                : 'Create Venue',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  String _getNextStepName() {
    switch (_tabController.index) {
      case 0:
        return 'Location';
      case 1:
        return 'Slot Config';
      case 2:
        return 'Images';
      default:
        return '';
    }
  }

  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add a new venue with location and slot configuration. Fill in all the details below.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            _buildLabel('Venue Name *'),
            TextFormField(
              controller: _nameController,
              decoration: _inputDecoration('e.g., Champion Futsal Arena'),
            ),
            const SizedBox(height: 16),
            _buildLabel('Description'),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: _inputDecoration('Describe your venue...'),
            ),
            const SizedBox(height: 16),
            _buildLabel('Price per Hour (NPR) *'),
            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration('e.g., 1500'),
            ),
            const SizedBox(height: 16),
            _buildLabel('Attributes (Optional)'),
            OutlinedButton.icon(
              onPressed: () {
                // TODO: Add attribute dialog
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Attribute'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black87,
                side: BorderSide(color: Colors.grey.shade300),
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                alignment: Alignment.centerLeft,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }

  Widget _buildLocationStep() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Address (Optional)'),
              TextFormField(
                decoration: _inputDecoration('e.g., Kumaripati, Lalitpur'),
              ),
              const SizedBox(height: 16),
              _buildLabel('Map Location'),
              const Text(
                'Click on the map or search to set your venue location',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: const LatLng(27.7172, 85.3240), // Kathmandu
                    initialZoom: 13.0,
                    onTap: (position, latlng) {
                      setState(() {
                        _selectedLocation = latlng;
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.fursal_mobile',
                    ),
                    if (_selectedLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedLocation!,
                            width: 40,
                            height: 40,
                            child: const Icon(Icons.location_on,
                                color: Colors.red, size: 40),
                          ),
                        ],
                      ),
                  ],
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 10)
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.grey),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              hintText: 'Search for a location...',
                              border: InputBorder.none,
                              contentPadding:
                                  EdgeInsets.symmetric(vertical: 14),
                            ),
                            enabled: false, // Make clickable in future
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    mini: true,
                    onPressed: () {
                      // Get current location
                    },
                    child: const Icon(Icons.my_location),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        borderSide: const BorderSide(color: AppTheme.primaryColor),
      ),
    );
  }
}
