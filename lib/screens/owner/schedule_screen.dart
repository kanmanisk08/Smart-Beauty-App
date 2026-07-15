import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/parlour_provider.dart';
import '../../models/booking.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/booking_details_sheet.dart';

class OwnerScheduleScreen extends StatefulWidget {
  const OwnerScheduleScreen({super.key});

  @override
  State<OwnerScheduleScreen> createState() => _OwnerScheduleScreenState();
}

class _OwnerScheduleScreenState extends State<OwnerScheduleScreen> {
  /// The day being viewed. Held as a real date (not an index) so that when the
  /// clock rolls past midnight the strip re-anchors to the new today instead of
  /// the selection silently sliding onto a different date. Null means "today".
  DateTime? _selectedDate;

  static const _weekdayLabels = ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"];
  static const _monthLabels = [
    "Jan", "Feb", "Mar", "Apr", "May", "Jun",
    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
  ];

  @override
  Widget build(BuildContext context) {
    final parlour = Provider.of<ParlourProvider>(context);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // A rolling 7-day window starting today, recomputed every rebuild.
    final days = List.generate(7, (i) => today.add(Duration(days: i)));
    // Fall back to today if nothing is chosen, or if the chosen day has aged
    // out of the window (app left open overnight).
    final selectedDay =
        (_selectedDate != null && days.contains(_selectedDate)) ? _selectedDate! : today;
    final isToday = selectedDay == today;

    // Real bookings for the selected day, sorted chronologically.
    final dayBookings = parlour.bookings.where((b) {
      final start = parlour.bookingStart(b);
      return start != null &&
          start.year == selectedDay.year &&
          start.month == selectedDay.month &&
          start.day == selectedDay.day &&
          b.status != 'Declined';
    }).toList()
      ..sort((a, b) => (parlour.bookingStart(a) ?? now).compareTo(parlour.bookingStart(b) ?? now));

    final headerLabel = isToday
        ? "Today's Appointments"
        : "${_weekdayLabels[selectedDay.weekday - 1].substring(0, 1)}${_weekdayLabels[selectedDay.weekday - 1].substring(1).toLowerCase()}, ${_monthLabels[selectedDay.month - 1]} ${selectedDay.day}";

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9FA), // Soft premium pink background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.darkText, size: 20),
          onPressed: () => context.go('/owner/dashboard'),
        ),
        title: const Text(
          "Master Schedule",
          style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkText),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Divider(color: Color(0xFFFFECEF), thickness: 1.5, height: 1),
          ),
          const SizedBox(height: 14),

          // Horizontal calendar dates scroll (real, rolling from today)
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: days.length,
              itemBuilder: (context, index) {
                final d = days[index];
                final isSelected = d == selectedDay;
                final hasBookings = parlour.bookings.any((b) {
                  final start = parlour.bookingStart(b);
                  return start != null &&
                      start.year == d.year &&
                      start.month == d.month &&
                      start.day == d.day &&
                      b.status != 'Declined';
                });

                return GestureDetector(
                  onTap: () => setState(() => _selectedDate = d),
                  child: Container(
                    width: 50,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primary : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppTheme.primary : const Color(0xFFFFECEF),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _weekdayLabels[d.weekday - 1],
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white70 : AppTheme.lightText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          d.day.toString(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : AppTheme.darkText,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        if (hasBookings) ...[
                          const SizedBox(height: 2),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : AppTheme.primary,
                              shape: BoxShape.circle,
                            ),
                          )
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Header section details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    headerLabel,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkText, fontFamily: 'Poppins'),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    dayBookings.length == 1 ? "1 Task" : "${dayBookings.length} Tasks",
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Agenda list view (real bookings)
          Expanded(
            child: dayBookings.isEmpty
                ? const Center(
                    child: Text(
                      "No appointments scheduled for this day.",
                      style: TextStyle(color: AppTheme.lightText, fontWeight: FontWeight.w600),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: dayBookings.length,
                    itemBuilder: (context, index) {
                      return _buildAgendaCard(context, parlour, dayBookings[index]);
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const OwnerBottomNav(activeTab: 'schedule'),
    );
  }

  Widget _buildAgendaCard(BuildContext context, ParlourProvider parlour, Booking b) {
    final isCompleted = b.status == 'History';
    final isPending = b.status == 'Pending';
    final status = isCompleted
        ? "COMPLETED"
        : isPending
            ? "PENDING"
            : "UPCOMING";
    final statusBg = isCompleted
        ? const Color(0xFFE8F5E9)
        : isPending
            ? const Color(0xFFFFF8E1)
            : const Color(0xFFFFF0F2);
    final statusColor = isCompleted
        ? Colors.green[700]!
        : isPending
            ? Colors.amber[800]!
            : AppTheme.primary;

    final time = parlour.timeRangeFor(b).split(' - ').first;

    return GestureDetector(
      // Tap the appointment for its full breakdown.
      onTap: () => showBookingDetailsSheet(context, b),
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFECEF), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: statusColor),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          time,
                          style: const TextStyle(fontSize: 11, color: AppTheme.lightText, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      b.customerName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isCompleted ? Colors.black26 : AppTheme.darkText,
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${b.serviceName}  •  ${b.duration} Mins",
                      style: const TextStyle(fontSize: 11, color: AppTheme.lightText, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildInitialAvatar(b.customerName),
            ],
          ),
          if (!isCompleted) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      onPressed: () {
                        final id = parlour.customerIdForName(b.customerName);
                        if (id != null) {
                          context.go('/owner/customer-profile/$id');
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("This client isn't in the directory yet.")),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        "View Client",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: isPending
                      ? () => parlour.approveBooking(b.id)
                      : () => parlour.markSessionComplete(b.id),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFFECEF), width: 1.5),
                    ),
                    child: Icon(
                      isPending ? Icons.done_all : Icons.check,
                      color: AppTheme.primary,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      ),
    );
  }

  Widget _buildInitialAvatar(String name) {
    final initials = name.trim().isEmpty
        ? "?"
        : name.trim().split(RegExp(r'\s+')).take(2).map((w) => w[0]).join().toUpperCase();
    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        initials,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary, fontFamily: 'Poppins'),
      ),
    );
  }
}
