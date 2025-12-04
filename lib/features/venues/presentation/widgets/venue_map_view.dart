import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../domain/venue.dart';

class VenueMapView extends StatefulWidget {
  final List<Venue> venues;
  final Venue? selectedVenue;
  final Function(Venue) onVenueSelected;

  const VenueMapView({
    super.key,
    required this.venues,
    this.selectedVenue,
    required this.onVenueSelected,
  });

  @override
  State<VenueMapView> createState() => _VenueMapViewState();
}

class _VenueMapViewState extends State<VenueMapView> {
  bool _isLocationEnabled = false;
  Position? _currentPosition;
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    // Default center (Kathmandu) if no venues or selected venue
    LatLng center = const LatLng(27.7172, 85.3240);
    double zoom = 13.0;

    if (widget.selectedVenue != null) {
      center = LatLng(
          widget.selectedVenue!.latitude, widget.selectedVenue!.longitude);
      zoom = 15.0;
    } else if (widget.venues.isNotEmpty) {
      // Center on the first venue if available
      center =
          LatLng(widget.venues.first.latitude, widget.venues.first.longitude);
    }

    // Build markers list
    List<Marker> markers = widget.venues.map((venue) {
      final isSelected = venue.id == widget.selectedVenue?.id;
      return Marker(
        point: LatLng(venue.latitude, venue.longitude),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => widget.onVenueSelected(venue),
          child: Icon(
            Icons.location_on,
            color: isSelected ? Colors.red : Colors.green,
            size: 40,
          ),
        ),
      );
    }).toList();

    // Add user location marker if enabled
    if (_isLocationEnabled && _currentPosition != null) {
      markers.add(
        Marker(
          point:
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue.withAlpha(128),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: const Icon(
              Icons.circle,
              color: Colors.blue,
              size: 16,
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: zoom,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.tournament',
            ),
            MarkerLayer(markers: markers),
          ],
        ),
        // Location toggle button
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            mini: true,
            backgroundColor:
                _isLocationEnabled ? const Color(0xFF00C853) : Colors.white,
            onPressed: _toggleLocation,
            child: Icon(
              Icons.my_location,
              color: _isLocationEnabled ? Colors.white : Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _toggleLocation() async {
    if (_isLocationEnabled) {
      // Turn off location
      setState(() {
        _isLocationEnabled = false;
        _currentPosition = null;
      });
    } else {
      // Turn on location
      await _enableLocation();
    }
  }

  Future<void> _enableLocation() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled.')),
        );
      }
      return;
    }

    // Check permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied.')),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permissions are permanently denied.'),
          ),
        );
      }
      return;
    }

    // Get current position
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _isLocationEnabled = true;
      });

      // Center map on user location
      _mapController.move(
        LatLng(position.latitude, position.longitude),
        15.0,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get location: $e')),
        );
      }
    }
  }
}
