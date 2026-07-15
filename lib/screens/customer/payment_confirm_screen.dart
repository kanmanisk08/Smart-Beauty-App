import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/parlour_provider.dart';
import '../../models/booking.dart';

class PaymentConfirmScreen extends StatelessWidget {
  final String bookingId;

  const PaymentConfirmScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    final parlour = Provider.of<ParlourProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    
    // Find current booking
    final booking = parlour.bookings.firstWhere(
      (b) => b.id == bookingId,
      orElse: () => parlour.bookings.isNotEmpty 
          ? parlour.bookings.last 
          : Booking(
              id: 'fallback',
              customerName: auth.currentUser?.name ?? '',
              customerPhone: '',
              customerEmail: '',
              serviceName: 'Women\'s Cut & Style',
              price: 300.0,
              duration: 45,
              date: 'Monday, Oct 5th',
              time: '11:00 AM - 12:00PM',
              stylist: 'Selvi',
              status: 'Confirmed',
              loyaltyDiscount: 0,
              tax: 15,
              totalPaid: 315,
              pointsApplied: 0,
              pointsEarned: 30,
            ),
    );

    final timestampMatch = RegExp(r'\d{13}').firstMatch(bookingId);
    final String? batchTimestamp = timestampMatch?.group(0);

    final List<Booking> batchBookings = batchTimestamp != null
        ? parlour.bookings.where((b) => b.id.contains(batchTimestamp)).toList()
        : [];

    if (batchBookings.isEmpty) {
      batchBookings.add(booking);
    }

    final totalPaidSum = batchBookings.fold<double>(0.0, (sum, b) => sum + b.totalPaid);
    final totalPointsEarned = batchBookings.fold<int>(0, (sum, b) => sum + b.pointsEarned);
    final totalDiscount = batchBookings.fold<double>(0.0, (sum, b) => sum + b.loyaltyDiscount);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9FA), // Soft premium pink background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.x, color: AppTheme.darkText, size: 20),
          onPressed: () => context.go('/customer/dashboard'),
        ),
        title: const Text(
          "Confirmation",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.darkText,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Divider(color: Color(0xFFFFECEF), thickness: 1.5, height: 1),
                const SizedBox(height: 32),

                // Large checked circle checkmark
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 42),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Thank You !",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkText,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Your booking is successfully confirmed",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppTheme.lightText, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 32),

                // Summary Card Info Box
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFFFECEF), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.02),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "APPOINTMENT SUMMARY",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            "Rs. ${totalPaidSum.toStringAsFixed(2)}",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // List of all booked services with dates and times
                      ...batchBookings.map((b) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(LucideIcons.scissors, color: AppTheme.primary, size: 14),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      b.serviceName,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.darkText,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                    Text(
                                      "Scheduled: ${b.date} at ${b.time}",
                                      style: const TextStyle(fontSize: 11, color: AppTheme.lightText, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                "Rs. ${b.price.toInt()}",
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primary),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      if (totalDiscount > 0) ...[
                        const Divider(color: Color(0xFFFFECEF), thickness: 1),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Loyalty Discount Applied",
                              style: TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "-Rs. ${totalDiscount.toInt()}",
                              style: const TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      // Details Rows
                      _buildSummaryRow(LucideIcons.user, booking.stylist, "Senior Stylist"),
                      const SizedBox(height: 12),
                      _buildSummaryRow(LucideIcons.mapPin, "Selvi's Beauty Parlour", "Sri Shiva nagar, Alasanatham Road, Hosur"),
                      const SizedBox(height: 24),
                      // Add to Calendar Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => context.go('/customer/dashboard'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.calendar_month, size: 18),
                              SizedBox(width: 8),
                              Text(
                                "Add to Calender",
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Points earned banner at bottom
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFECEF), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.star, color: AppTheme.primary, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Points Earned Today",
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.darkText),
                            ),
                            Text(
                              "New Total: ${auth.currentUser?.points ?? 900} points",
                              style: const TextStyle(fontSize: 11, color: AppTheme.lightText, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        "+$totalPointsEarned",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primary, fontFamily: 'Poppins'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String title, String subText) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Color(0xFFFFF0F2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.primary, size: 14),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.darkText),
              ),
              Text(
                subText,
                style: const TextStyle(fontSize: 11, color: AppTheme.lightText, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
