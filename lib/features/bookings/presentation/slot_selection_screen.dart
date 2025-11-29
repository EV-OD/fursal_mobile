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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.venueName,
          style: theme.appBarTheme.titleTextStyle,
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.appBarTheme.iconTheme?.color),
          onPressed: () => context.pop(),
        ),
      ),
      body: venueSlotsAsync.when(
        data: (venueSlots) {
          if (venueSlots == null) {
            return Center(child: Text('No slot configuration found for this venue.', style: theme.textTheme.bodyLarge));
          }
          return Column(
            children: [
              _buildDateSelector(theme),
              Expanded(
                child: _buildSlotsGrid(venueSlots, theme),
              ),
              _buildBottomBar(theme),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err', style: TextStyle(color: theme.colorScheme.error))),
      ),
    );
  }

  Widget _buildDateSelector(ThemeData theme) {
    return Container(
      height: 100,
      color: theme.cardColor,
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
                color: isSelected ? theme.primaryColor : theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? theme.primaryColor : Colors.grey.shade200,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: theme.primaryColor.withOpacity(0.3),
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
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('d').format(date),
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
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

  Widget _buildSlotsGrid(VenueSlotData venueSlots, ThemeData theme) {
    final slots = _generateSlots(venueSlots.config);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    if (slots.isEmpty) {
      return Center(child: Text('No slots available for this day.', style: theme.textTheme.bodyLarge));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Available Slots',
          style: theme.textTheme.titleLarge,
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

            return _buildSlotItem(time, status, isSelected, theme);
          },
        ),
        const SizedBox(height: 24),
        _buildLegend(theme),
      ],
    );
  }

  Widget _buildSlotItem(String time, SlotStatus status, bool isSelected, ThemeData theme) {
    final isAvailable = status == SlotStatus.available;
    
    Color backgroundColor;
    Color textColor;
    Color borderColor;
    IconData? icon;

    if (isSelected) {
      backgroundColor = theme.primaryColor;
      textColor = Colors.white;
      borderColor = theme.primaryColor;
    } else {
      switch (status) {
        case SlotStatus.available:
          backgroundColor = theme.cardColor;
          textColor = AppTheme.textPrimary;
          borderColor = Colors.grey.shade200;
          break;
        case SlotStatus.bookedWebsite:
          backgroundColor = AppTheme.errorColor.withOpacity(0.1);
          textColor = AppTheme.errorColor;
          borderColor = AppTheme.errorColor.withOpacity(0.2);
          icon = Icons.language;
          break;
        case SlotStatus.bookedPhysical:
          backgroundColor = AppTheme.errorColor.withOpacity(0.1);
          textColor = AppTheme.errorColor;
          borderColor = AppTheme.errorColor.withOpacity(0.2);
          icon = Icons.person;
          break;
        case SlotStatus.held:
          backgroundColor = AppTheme.secondaryColor.withOpacity(0.1);
          textColor = AppTheme.secondaryColor;
          borderColor = AppTheme.secondaryColor.withOpacity(0.2);
          break;
        case SlotStatus.blocked:
          backgroundColor = Colors.grey.shade100;
          textColor = Colors.grey.shade400;
          borderColor = Colors.grey.shade200;
          break;
        case SlotStatus.reserved:
          backgroundColor = Colors.purple.shade50;
          textColor = Colors.purple.shade300;
          borderColor = Colors.purple.shade100;
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

  Widget _buildLegend(ThemeData theme) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 8,
      children: [
        _buildLegendItem('Available', theme.cardColor, Colors.grey.shade200),
        _buildLegendItem('Selected', theme.primaryColor, theme.primaryColor),
        _buildLegendItem('Online', AppTheme.errorColor.withOpacity(0.1), AppTheme.errorColor.withOpacity(0.2), icon: Icons.language, iconColor: AppTheme.errorColor),
        _buildLegendItem('Physical', AppTheme.errorColor.withOpacity(0.1), AppTheme.errorColor.withOpacity(0.2), icon: Icons.person, iconColor: AppTheme.errorColor),
        _buildLegendItem('Held', AppTheme.secondaryColor.withOpacity(0.1), AppTheme.secondaryColor.withOpacity(0.2)),
        // _buildLegendItem('Reserved', Colors.purple.shade50, Colors.purple.shade100),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, Color borderColor, {IconData? icon, Color? iconColor}) {
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
            ? Icon(icon, size: 12, color: iconColor) 
            : null,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildBottomBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
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
                Text(
                  'Total Price',
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  'Rs. ${widget.pricePerHour.toStringAsFixed(0)}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.bold,
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
                  backgroundColor: theme.primaryColor,
                  disabledBackgroundColor: Colors.grey.shade300,
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
