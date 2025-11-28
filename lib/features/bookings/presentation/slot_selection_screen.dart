import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../venues/data/venue_repository.dart';
import '../../venues/domain/venue_slot.dart';

class SlotSelectionScreen extends ConsumerStatefulWidget {
  final String venueId;
  final String venueName;
  final double pricePerHour;

  const SlotSelectionScreen({
    super.key,
    required this.venueId,
    required this.venueName,
    required this.pricePerHour,
  });

  @override
  ConsumerState<SlotSelectionScreen> createState() => _SlotSelectionScreenState();
}

class _SlotSelectionScreenState extends ConsumerState<SlotSelectionScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedSlotTime;

  @override
  Widget build(BuildContext context) {
    final venueSlotsAsync = ref.watch(venueSlotsProvider(widget.venueId));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.venueName,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: venueSlotsAsync.when(
        data: (venueSlots) {
          if (venueSlots == null) {
            return const Center(child: Text('No slot configuration found for this venue.'));
          }
          return Column(
            children: [
              _buildDateSelector(),
              Expanded(
                child: _buildSlotsGrid(venueSlots),
              ),
              _buildBottomBar(),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      height: 100,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: 7,
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index));
          final isSelected = _isSameDay(date, _selectedDate);

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
                _selectedSlotTime = null; // Reset selection on date change
              });
            },
            child: Container(
              width: 60,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE').format(date),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('d').format(date),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSlotsGrid(VenueSlotData venueSlots) {
    final slots = _generateSlots(venueSlots.config);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    if (slots.isEmpty) {
      return const Center(child: Text('No slots available for this day.'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Available Slots',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: slots.length,
          itemBuilder: (context, index) {
            final time = slots[index];
            final status = _getSlotStatus(venueSlots, dateStr, time);
            final isSelected = _selectedSlotTime == time;

            return _buildSlotItem(time, status, isSelected);
          },
        ),
        const SizedBox(height: 24),
        _buildLegend(),
      ],
    );
  }

  Widget _buildSlotItem(String time, SlotStatus status, bool isSelected) {
    final isAvailable = status == SlotStatus.available;
    
    Color backgroundColor;
    Color textColor;
    Color borderColor;
    IconData? icon;

    if (isSelected) {
      backgroundColor = AppTheme.primaryColor;
      textColor = Colors.white;
      borderColor = AppTheme.primaryColor;
    } else {
      switch (status) {
        case SlotStatus.available:
          backgroundColor = Colors.white;
          textColor = Colors.black87;
          borderColor = Colors.grey[300]!;
          break;
        case SlotStatus.bookedWebsite:
          backgroundColor = Colors.red[50]!;
          textColor = Colors.red[300]!;
          borderColor = Colors.red[100]!;
          icon = Icons.language;
          break;
        case SlotStatus.bookedPhysical:
          backgroundColor = Colors.red[50]!;
          textColor = Colors.red[300]!;
          borderColor = Colors.red[100]!;
          icon = Icons.person;
          break;
        case SlotStatus.held:
          backgroundColor = Colors.orange[50]!;
          textColor = Colors.orange[300]!;
          borderColor = Colors.orange[100]!;
          break;
        case SlotStatus.blocked:
          backgroundColor = Colors.grey[200]!;
          textColor = Colors.grey[400]!;
          borderColor = Colors.grey[300]!;
          break;
        case SlotStatus.reserved:
          backgroundColor = Colors.blue[50]!;
          textColor = Colors.blue[300]!;
          borderColor = Colors.blue[100]!;
          break;
      }
    }

    return GestureDetector(
      onTap: isAvailable
          ? () {
              setState(() {
                _selectedSlotTime = time;
              });
            }
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: textColor),
              const SizedBox(width: 4),
            ],
            Text(
              time,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                decoration: !isAvailable && icon == null ? TextDecoration.lineThrough : null,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 8,
      children: [
        _buildLegendItem('Available', Colors.white, Colors.grey[300]!),
        _buildLegendItem('Selected', AppTheme.primaryColor, AppTheme.primaryColor),
        _buildLegendItem('Online', Colors.red[50]!, Colors.red[100]!, icon: Icons.language),
        _buildLegendItem('Physical', Colors.red[50]!, Colors.red[100]!, icon: Icons.person),
        _buildLegendItem('Held', Colors.orange[50]!, Colors.orange[100]!),
        _buildLegendItem('Reserved', Colors.blue[50]!, Colors.blue[100]!),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, Color borderColor, {IconData? icon}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: borderColor),
          ),
          child: icon != null 
            ? Icon(icon, size: 12, color: Colors.red[300]) 
            : null,
        ),
        const SizedBox(width: 6),
                Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Total Price',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Rs. ${widget.pricePerHour.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 24),
            Expanded(
              child: ElevatedButton(
                onPressed: _selectedSlotTime != null
                    ? () {
                        // TODO: Proceed to payment/confirmation
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Booking $_selectedSlotTime on ${DateFormat('yyyy-MM-dd').format(_selectedDate)}')),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  disabledBackgroundColor: Colors.grey[300],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _generateSlots(VenueConfig config) {
    // Check if venue is open on selected day
    // 0=Sunday in config, but DateTime.weekday 1=Monday, 7=Sunday
    // Convert DateTime.weekday to 0-6 (0=Sunday, 1=Monday...)
    int weekday = _selectedDate.weekday;
    if (weekday == 7) weekday = 0;

    if (!config.daysOfWeek.contains(weekday)) {
      return [];
    }

    List<String> slots = [];
    
    // Parse start and end times
    // Assuming format HH:mm
    final startParts = config.startTime.split(':');
    final endParts = config.endTime.split(':');
    
    int startHour = int.parse(startParts[0]);
    int startMinute = int.parse(startParts[1]);
    
    int endHour = int.parse(endParts[0]);
    int endMinute = int.parse(endParts[1]);

    DateTime current = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      startHour,
      startMinute,
    );

    DateTime end = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      endHour,
      endMinute,
    );

    final now = DateTime.now();

    while (current.isBefore(end)) {
      // Only add slots that are in the future
      if (current.isAfter(now)) {
        slots.add(DateFormat('HH:mm').format(current));
      }
      current = current.add(Duration(minutes: config.slotDuration));
    }

    return slots;
  }

  SlotStatus _getSlotStatus(VenueSlotData data, String date, String time) {
    // Check blocked
    if (data.blocked.any((b) => b.date == date && b.startTime == time)) {
      return SlotStatus.blocked;
    }

    // Check bookings
    final bookingIndex = data.bookings.indexWhere((b) => b.date == date && b.startTime == time && b.status != 'cancelled');
    if (bookingIndex != -1) {
      final booking = data.bookings[bookingIndex];
      if (booking.bookingType == 'physical') {
        return SlotStatus.bookedPhysical;
      }
      return SlotStatus.bookedWebsite;
    }

    // Check held
    if (data.held.any((h) => h.date == date && h.startTime == time)) {
      // Check if hold is expired
      // For now assume valid if present, ideally check timestamp
      return SlotStatus.held;
    }

    // Check reserved
    if (data.reserved.any((r) => r.date == date && r.startTime == time)) {
      return SlotStatus.reserved;
    }

    return SlotStatus.available;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

enum SlotStatus {
  available,
  bookedWebsite,
  bookedPhysical,
  held,
  blocked,
  reserved,
}
