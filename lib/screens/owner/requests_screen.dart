import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme.dart';
import '../../providers/parlour_provider.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/booking_details_sheet.dart';
import '../../models/booking.dart';

class OwnerRequestsScreen extends StatefulWidget {
  const OwnerRequestsScreen({super.key});

  @override
  State<OwnerRequestsScreen> createState() => _OwnerRequestsScreenState();
}

class _OwnerRequestsScreenState extends State<OwnerRequestsScreen> {
  String _activeTab = 'Pending'; // Pending, Confirmed, History

  @override
  Widget build(BuildContext context) {
    final parlour = Provider.of<ParlourProvider>(context);
    final pendingList = parlour.bookings.where((b) => b.status == 'Pending').toList();
    final confirmedList = parlour.bookings.where((b) => b.status == 'Confirmed').toList();

    // Past work, most recent first — this is the owner's record of completed
    // (and declined) appointments.
    final historyList = parlour.bookings
        .where((b) => b.status == 'History' || b.status == 'Declined')
        .toList()
      ..sort((a, b) {
        final sa = parlour.bookingStart(a);
        final sb = parlour.bookingStart(b);
        if (sa == null || sb == null) return 0;
        return sb.compareTo(sa);
      });

    List<Booking> tabList = [];
    if (_activeTab == 'Pending') {
      tabList = pendingList;
    } else if (_activeTab == 'Confirmed') {
      tabList = confirmedList;
    } else if (_activeTab == 'History') {
      tabList = historyList;
    }

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
          "Appointments",
          style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkText),
        ),
        centerTitle: true,
        actions: [
          // Client directory lives here now that Appointments holds the nav slot.
          IconButton(
            icon: const Icon(LucideIcons.users, color: AppTheme.darkText, size: 20),
            tooltip: "Client directory",
            onPressed: () => context.go('/owner/directory'),
          ),
          IconButton(
            icon: const Icon(LucideIcons.calendar, color: AppTheme.darkText, size: 20),
            tooltip: "Master schedule",
            onPressed: () => context.go('/owner/schedule'),
          ),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Divider(color: Color(0xFFFFECEF), thickness: 1.5, height: 1),
          ),
          const SizedBox(height: 14),

          // Switcher Tabs Capsule Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(child: _buildTabPill("Pending (${pendingList.length})", 'Pending')),
                  Expanded(child: _buildTabPill("Confirmed (${confirmedList.length})", 'Confirmed')),
                  Expanded(child: _buildTabPill("History (${historyList.length})", 'History')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Requests list scrolling content
          Expanded(
            child: tabList.isEmpty
                ? Center(
                    child: Text(
                      _activeTab == 'History'
                          ? "No completed appointments yet."
                          : "No $_activeTab appointments at this time.",
                      style: const TextStyle(color: AppTheme.lightText, fontWeight: FontWeight.bold),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: tabList.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: _buildRequestCard(context, parlour, tabList[index]),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const OwnerBottomNav(activeTab: 'appointments'),
    );
  }

  Widget _buildTabPill(String label, String tabKey) {
    final isActive = _activeTab == tabKey;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = tabKey),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isActive ? AppTheme.darkText : AppTheme.lightText,
          ),
        ),
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, ParlourProvider parlour, Booking b) {
    final customer = parlour.customerByName(b.customerName);
    final badge = customer?.badge ?? "New Customer";
    final badgeStyle = _badgeStyle(badge);
    final visits = parlour.visitsFor(b.customerName);

    // A real, human sub-line based on the customer's history.
    final String subLine;
    if (b.status == 'Declined') {
      subLine = "Declined request";
    } else if (b.status == 'History') {
      subLine = "Completed visit";
    } else if (customer == null) {
      subLine = "New client";
    } else if (visits == 0) {
      subLine = "First appointment";
    } else {
      subLine = "$visits past ${visits == 1 ? 'visit' : 'visits'} • Member since ${customer.memberSince}";
    }

    final isPending = b.status == 'Pending';
    final isCompleted = b.status == 'History';
    final status = bookingStatusStyle(b.status);

    return GestureDetector(
      // Tapping the customer opens the full breakdown of the appointment.
      onTap: () => showBookingDetailsSheet(context, b),
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFECEF), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _buildInitialAvatar(b.customerName),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            b.customerName,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.darkText, fontFamily: 'Poppins'),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: badgeStyle.$2, borderRadius: BorderRadius.circular(8)),
                          child: Text(
                            badge,
                            style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: badgeStyle.$1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subLine,
                      style: const TextStyle(fontSize: 10, color: AppTheme.lightText, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Where this appointment stands.
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: status.$3, borderRadius: BorderRadius.circular(10)),
                child: Text(
                  status.$1,
                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: status.$2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Pink summary block: what was done, when, and what was paid.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0F2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(flex: 5, child: _buildPinkBlockItem("SERVICE", b.serviceName)),
                    Expanded(flex: 4, child: _buildPinkBlockItem("DATE", _dateLabel(parlour, b))),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(flex: 5, child: _buildPinkBlockItem("TIME SLOT", parlour.timeRangeFor(b))),
                    Expanded(
                      flex: 4,
                      child: _buildPinkBlockItem(
                        isCompleted ? "AMOUNT PAID" : "TOTAL",
                        "Rs. ${b.totalPaid.toStringAsFixed(0)}",
                        highlight: isCompleted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (isPending) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: OutlinedButton(
                      onPressed: () => parlour.declineBooking(b.id),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text("Decline", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: ElevatedButton(
                      onPressed: () => parlour.approveBooking(b.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check, size: 14),
                          SizedBox(width: 6),
                          Text("Approve", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: () => _reschedule(context, parlour, b),
              icon: const Icon(LucideIcons.calendarClock, size: 14, color: AppTheme.lightText),
              label: const Text("Suggest another time", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.lightText)),
            ),
          ],
        ],
      ),
      ),
    );
  }

  /// "Wed, 15 Jul 2026" — falls back to the raw stored date if unparseable.
  String _dateLabel(ParlourProvider parlour, Booking b) {
    final start = parlour.bookingStart(b);
    if (start == null) return b.date;
    const weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return "${weekdays[start.weekday - 1]}, ${start.day} ${months[start.month - 1]} ${start.year}";
  }

  Future<void> _reschedule(BuildContext context, ParlourProvider parlour, Booking b) async {
    final now = DateTime.now();
    final existing = parlour.bookingStart(b) ?? now;
    final initialDate = existing.isBefore(now) ? now : existing;

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(existing),
    );
    if (time == null || !context.mounted) return;

    final dateStr =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    final hour12 = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final ampm = time.period == DayPeriod.am ? 'AM' : 'PM';
    final timeStr = "${hour12.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $ampm";

    await parlour.rescheduleBooking(b.id, dateStr, timeStr);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Rescheduled ${b.customerName} to $dateStr at $timeStr.")),
      );
    }
  }

  /// Returns (textColor, backgroundColor) for a customer badge.
  (Color, Color) _badgeStyle(String badge) {
    switch (badge) {
      case 'Punctual':
        return (Colors.green[700]!, const Color(0xFFE8F5E9));
      case 'Occasional':
        return (Colors.amber[800]!, const Color(0xFFFFF8E1));
      default:
        return (AppTheme.primary, const Color(0xFFFFF0F2));
    }
  }

  Widget _buildInitialAvatar(String name) {
    final initials = name.trim().isEmpty
        ? "?"
        : name.trim().split(RegExp(r'\s+')).take(2).map((w) => w[0]).join().toUpperCase();
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        initials,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primary, fontFamily: 'Poppins'),
      ),
    );
  }

  Widget _buildPinkBlockItem(String label, String value, {bool highlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppTheme.lightText),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: highlight ? AppTheme.primary : AppTheme.darkText,
          ),
        ),
      ],
    );
  }
}
