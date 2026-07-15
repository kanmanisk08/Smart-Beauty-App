import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme.dart';
import '../models/booking.dart';
import '../providers/parlour_provider.dart';

/// Full breakdown of a single appointment — who, what, when, how much, and
/// where it currently stands. Opened by tapping any appointment card.
Future<void> showBookingDetailsSheet(BuildContext context, Booking booking) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ChangeNotifierProvider.value(
      value: Provider.of<ParlourProvider>(context, listen: false),
      child: _BookingDetailsSheet(bookingId: booking.id),
    ),
  );
}

class _BookingDetailsSheet extends StatelessWidget {
  final String bookingId;
  const _BookingDetailsSheet({required this.bookingId});

  @override
  Widget build(BuildContext context) {
    final parlour = Provider.of<ParlourProvider>(context);
    // Read back from the provider so the sheet reflects live status changes.
    final matches = parlour.bookings.where((b) => b.id == bookingId);
    if (matches.isEmpty) return const SizedBox.shrink();
    final b = matches.first;

    final status = _statusStyle(b.status);
    final customerId = parlour.customerIdForName(b.customerName);
    final isCompleted = b.status == 'History';

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFFF9FA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: ListView(
          controller: scrollController,
          children: [
            // Grab handle
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD4DA),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Customer header
            Row(
              children: [
                _buildInitialAvatar(b.customerName),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b.customerName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkText, fontFamily: 'Poppins'),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        b.customerPhone.isNotEmpty ? b.customerPhone : b.customerEmail,
                        style: const TextStyle(fontSize: 11, color: AppTheme.lightText, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: status.$3, borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    status.$1,
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: status.$2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // What / when
            _sectionLabel("Appointment"),
            _detailCard([
              _row(LucideIcons.sparkles, "Service", b.serviceName),
              _row(LucideIcons.calendar, "Date", _dateLabel(parlour, b)),
              _row(LucideIcons.clock, "Time slot", parlour.timeRangeFor(b)),
              _row(LucideIcons.timer, "Duration", "${b.duration} min"),
              _row(LucideIcons.user, "Stylist", b.stylist),
            ]),
            const SizedBox(height: 20),

            // Money
            _sectionLabel("Payment"),
            _detailCard([
              _row(LucideIcons.tag, "Service price", "Rs. ${b.price.toInt()}"),
              if (b.loyaltyDiscount > 0)
                _row(LucideIcons.badgePercent, "Loyalty discount", "− Rs. ${b.loyaltyDiscount.toStringAsFixed(0)}"),
              _row(LucideIcons.receipt, "Tax", "Rs. ${b.tax.toStringAsFixed(0)}"),
              _row(
                LucideIcons.indianRupee,
                isCompleted ? "Amount paid" : "Total",
                "Rs. ${b.totalPaid.toStringAsFixed(0)}",
                emphasise: true,
              ),
              if (b.pointsApplied > 0)
                _row(LucideIcons.star, "Points redeemed", "${b.pointsApplied} pts"),
              if (b.pointsEarned > 0)
                _row(LucideIcons.star, "Points earned", "+${b.pointsEarned} pts"),
            ]),

            if (b.review != null && b.review!.trim().isNotEmpty) ...[
              const SizedBox(height: 20),
              _sectionLabel("Customer review"),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFECEF), width: 1.5),
                ),
                child: Text(
                  '"${b.review!.trim()}"',
                  style: const TextStyle(fontSize: 12, color: AppTheme.darkText, fontWeight: FontWeight.w500, height: 1.5, fontStyle: FontStyle.italic),
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Actions that make sense for this status
            if (b.status == 'Pending') ...[
              Row(
                children: [
                  Expanded(
                    child: _sheetButton(
                      label: "Decline",
                      outlined: true,
                      onTap: () {
                        parlour.declineBooking(b.id);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _sheetButton(
                      label: "Approve",
                      onTap: () {
                        parlour.approveBooking(b.id);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            if (b.status == 'Confirmed') ...[
              _sheetButton(
                label: "Mark as completed",
                onTap: () {
                  parlour.markSessionComplete(b.id);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 12),
            ],
            if (customerId != null)
              _sheetButton(
                label: "View client profile",
                outlined: true,
                onTap: () {
                  Navigator.pop(context);
                  context.go('/owner/customer-profile/$customerId');
                },
              ),
          ],
        ),
      ),
    );
  }

  String _dateLabel(ParlourProvider parlour, Booking b) {
    final start = parlour.bookingStart(b);
    if (start == null) return b.date;
    const weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return "${weekdays[start.weekday - 1]}, ${start.day} ${months[start.month - 1]} ${start.year}";
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary, letterSpacing: 0.5),
        ),
      );

  Widget _detailCard(List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFECEF), width: 1.5),
      ),
      child: Column(children: rows),
    );
  }

  Widget _row(IconData icon, String label, String value, {bool emphasise = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 14, color: emphasise ? AppTheme.primary : AppTheme.lightText),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: emphasise ? FontWeight.bold : FontWeight.w600,
                color: emphasise ? AppTheme.darkText : AppTheme.lightText,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: emphasise ? 15 : 12,
              fontWeight: FontWeight.bold,
              color: emphasise ? AppTheme.primary : AppTheme.darkText,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _sheetButton({required String label, required VoidCallback onTap, bool outlined = false}) {
    return SizedBox(
      height: 50,
      child: outlined
          ? OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFFECEF), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.darkText)),
            )
          : ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ),
    );
  }

  Widget _buildInitialAvatar(String name) {
    final initials = name.trim().isEmpty
        ? "?"
        : name.trim().split(RegExp(r'\s+')).take(2).map((w) => w[0]).join().toUpperCase();
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        initials,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.primary, fontFamily: 'Poppins'),
      ),
    );
  }
}

/// (label, textColour, backgroundColour) for an appointment status.
(String, Color, Color) _statusStyle(String status) {
  switch (status) {
    case 'History':
      return ("COMPLETED", Color(0xFF2E7D32), Color(0xFFE8F5E9));
    case 'Confirmed':
      return ("CONFIRMED", AppTheme.primary, Color(0xFFFFF0F2));
    case 'Pending':
      return ("PENDING", Color(0xFFEF6C00), Color(0xFFFFF8E1));
    case 'Declined':
      return ("DECLINED", AppTheme.danger, Color(0xFFFFEBEE));
    default:
      return (status.toUpperCase(), AppTheme.lightText, Color(0xFFF5F5F5));
  }
}

/// Exposed so cards can show the same chip as the sheet.
(String, Color, Color) bookingStatusStyle(String status) => _statusStyle(status);
