import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/parlour_provider.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/common.dart';
import '../../models/booking.dart';
import '../../models/service.dart';

class CustomerAppointmentsScreen extends StatelessWidget {
  final String initialTab;

  const CustomerAppointmentsScreen({super.key, this.initialTab = 'upcoming'});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final parlour = Provider.of<ParlourProvider>(context);

    final user = auth.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Filter appointments
    final userBookings = parlour.bookings.where(
      (b) => b.customerName.toLowerCase() == user.name.toLowerCase()
    ).toList();

    final upcomingList = userBookings.where(
      (b) => b.status == 'Confirmed' || b.status == 'Pending'
    ).toList();

    final historyList = userBookings.where(
      (b) => b.status == 'History' || b.status == 'Declined'
    ).toList();

    return DefaultTabController(
      length: 2,
      initialIndex: initialTab == 'history' ? 1 : 0,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF9FA), // Soft premium pink background
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.darkText, size: 20),
            onPressed: () => context.go('/customer/dashboard'),
          ),
          title: const Text(
            "My Appointments",
            style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkText),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            const Divider(color: Color(0xFFFFECEF), thickness: 1.5, height: 1),
            const SizedBox(height: 12),

            // Tab bar switcher capsule matching design
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFECEF), width: 1.5),
              ),
              child: TabBar(
                indicator: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: AppTheme.lightText,
                dividerColor: Colors.transparent,
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                tabs: const [
                  Tab(text: "Upcoming"),
                  Tab(text: "History"),
                ],
              ),
            ),

            // Tab view contents
            Expanded(
              child: TabBarView(
                children: [
                  // Upcoming Tab View
                  _buildUpcomingTab(context, parlour, upcomingList),
                  // History Tab View
                  _buildHistoryTab(context, parlour, historyList),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: const CustomerBottomNav(activeTab: 'bookings'),
      ),
    );
  }

  Widget _buildUpcomingTab(BuildContext context, ParlourProvider parlour, List<Booking> list) {
    // Sort list by date ascending
    list.sort((a, b) => a.date.compareTo(b.date));

    // Check if any upcoming booking has a live delay
    final delayedBookings = list.where(
      (b) => b.liveStatus != null && b.liveStatus!['hasDelay'] == true,
    ).toList();
    final hasDelay = delayedBookings.isNotEmpty;
    final delayedBooking = hasDelay ? delayedBookings.first : null;

    final now = DateTime.now();
    final thisWeekBookings = <Booking>[];
    final futureBookings = <Booking>[];

    for (final b in list) {
      try {
        final bDate = DateTime.parse(b.date);
        final difference = bDate.difference(now).inDays;
        if (difference <= 7) {
          thisWeekBookings.add(b);
        } else {
          futureBookings.add(b);
        }
      } catch (e) {
        thisWeekBookings.add(b);
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Live Status Delay Banner
          if (hasDelay) ...[
            _buildSectionHeader("LIVE STATUS"),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F3), // Soft pink background
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFECEF), width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFECEF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.alarmClock, color: AppTheme.primary, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Your stylist is finishing up a previous service",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "New Start Time : ${delayedBooking!.liveStatus!['adjustedTime']} (${delayedBooking.liveStatus!['delayMinutes']} Mins Delay)",
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Upcoming this week section
          _buildSectionHeader("UPCOMING THIS WEEK"),
          if (thisWeekBookings.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Text("No upcoming appointments this week.", style: TextStyle(color: AppTheme.lightText)),
              ),
            )
          else
            ...thisWeekBookings.map((b) => _buildUpcomingCard(context, parlour, b)),

          // Next Month section matching mockup dynamically
          if (futureBookings.isNotEmpty) ...[
            _buildSectionHeader("NEXT MONTH"),
            ...futureBookings.map((b) => _buildUpcomingCard(context, parlour, b)),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildUpcomingCard(BuildContext context, ParlourProvider parlour, Booking b) {
    final isConfirmed = b.status == 'Confirmed';
    
    // Find matching service image
    final serviceImg = parlour.services.firstWhere(
      (s) => s.name == b.serviceName,
      orElse: () => Service(id: '', name: '', category: '', price: 0, duration: 0, image: "https://images.unsplash.com/photo-1562322140-8baeececf3df?auto=format&fit=crop&w=300&q=80", description: ''),
    ).image;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFECEF), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: serviceImg.startsWith('http')
                ? Image.network(
                    serviceImg,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  )
                : Image.asset(
                    serviceImg,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        b.serviceName,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.darkText, fontFamily: 'Poppins'),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isConfirmed ? AppTheme.successLight : AppTheme.warningLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        b.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: isConfirmed ? AppTheme.success : AppTheme.warning,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  "With ${b.stylist}",
                  style: const TextStyle(fontSize: 11, color: AppTheme.lightText, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(LucideIcons.calendar, color: AppTheme.primary, size: 12),
                    const SizedBox(width: 6),
                    Text(
                      "${b.date} • ${b.time}",
                      style: const TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 32,
                        child: ElevatedButton(
                          onPressed: () {
                            if (b.status == 'Pending') {
                              parlour.startRescheduling(b.id);
                              context.go('/customer/book-appointment');
                            } else {
                              _showBookingDetailsDialog(context, parlour, b);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: b.status == 'Pending' ? AppTheme.primaryLight : AppTheme.primary,
                            foregroundColor: b.status == 'Pending' ? AppTheme.primary : Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                b.status == 'Pending' ? LucideIcons.calendar : LucideIcons.eye,
                                size: 12,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                b.status == 'Pending' ? "Reschedule" : "View Details",
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text("Cancel Booking"),
                            content: const Text("Are you sure you want to cancel this booking?"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text("No"),
                              ),
                              TextButton(
                                onPressed: () {
                                  parlour.cancelBooking(b.id);
                                  Navigator.pop(ctx);
                                },
                                child: const Text("Yes", style: TextStyle(color: AppTheme.danger)),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black26, width: 1.5),
                        ),
                        child: const Icon(Icons.close, color: Colors.black54, size: 16),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showBookingDetailsDialog(BuildContext context, ParlourProvider parlour, Booking b) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFFECEF), width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.successLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      b.status.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.success,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: AppTheme.lightText),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                b.serviceName,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkText,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(color: Color(0xFFFFECEF), thickness: 1),
              const SizedBox(height: 12),
              _buildDetailRow(LucideIcons.calendar, "Scheduled Time", "${b.date} at ${b.time}"),
              const SizedBox(height: 12),
              _buildDetailRow(LucideIcons.user, "Stylist", "${b.stylist} (Senior Stylist)"),
              const SizedBox(height: 12),
              _buildDetailRow(LucideIcons.wallet, "Payment Method", "Paid via Card"),
              const SizedBox(height: 12),
              _buildDetailRow(LucideIcons.hash, "Booking ID", b.id),
              const SizedBox(height: 16),
              const Divider(color: Color(0xFFFFECEF), thickness: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Amount Paid",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.lightText),
                  ),
                  Text(
                    "Rs. ${b.totalPaid.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
              if (b.loyaltyDiscount > 0) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Points Discount",
                      style: TextStyle(fontSize: 12, color: AppTheme.success, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      "-Rs. ${b.loyaltyDiscount.toInt()}.00",
                      style: const TextStyle(fontSize: 12, color: AppTheme.success, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text("Close", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppTheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 10, color: AppTheme.lightText, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 12, color: AppTheme.darkText, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTab(BuildContext context, ParlourProvider parlour, List<Booking> list) {
    if (list.isEmpty) {
      return Column(
        children: [
          const Expanded(
            child: Center(
              child: Text(
                "No past appointments completed yet.",
                style: TextStyle(color: AppTheme.lightText, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          // Book New Appointment bottom button
          Container(
            padding: const EdgeInsets.all(20),
            color: const Color(0xFFFFF9FA),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => context.go('/customer/services'),
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
                    Icon(Icons.add, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Book New Appointment",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Sort past visits by date descending
    list.sort((a, b) => b.date.compareTo(a.date));

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader("RECENT VISIT"),
                ...list.map((b) {
                  final serviceImg = parlour.services.firstWhere(
                    (s) => s.name == b.serviceName,
                    orElse: () => Service(id: '', name: '', category: '', price: 0, duration: 0, image: "https://images.unsplash.com/photo-1562322140-8baeececf3df?auto=format&fit=crop&w=300&q=80", description: ''),
                  ).image;
                  
                  return _buildHistoryCard(context, parlour, b, serviceImg);
                }),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        // Book New Appointment bottom button
        Container(
          padding: const EdgeInsets.all(20),
          color: const Color(0xFFFFF9FA),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => context.go('/customer/services'),
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
                  Icon(Icons.add, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Book New Appointment",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showReviewBottomSheet(BuildContext context, ParlourProvider parlour, Booking b) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header indicator
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFECEF),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Write a Review",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkText,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "How was your experience with ${b.serviceName}?",
                style: const TextStyle(fontSize: 12, color: AppTheme.lightText),
              ),
              const SizedBox(height: 20),

              // Review Text Field
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9FA),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFECEF), width: 1.5),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: controller,
                  maxLines: 4,
                  autofocus: true,
                  style: const TextStyle(fontSize: 13, color: AppTheme.darkText),
                  decoration: const InputDecoration(
                    hintText: "Loved the luxury treatment! Hair feels silky...",
                    hintStyle: TextStyle(color: AppTheme.lightText),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    final text = controller.text.trim();
                    if (text.isNotEmpty) {
                      await parlour.submitBookingReview(b.id, text);
                      if (context.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Thank you for your feedback!"),
                            backgroundColor: AppTheme.primary,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    "Submit Review",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistoryCard(BuildContext context, ParlourProvider parlour, Booking b, String serviceImg) {
    final hasReview = b.review != null && b.review!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFECEF), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: serviceImg.startsWith('http')
                ? Image.network(
                    serviceImg,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  )
                : Image.asset(
                    serviceImg,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        b.serviceName,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.darkText, fontFamily: 'Poppins'),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(LucideIcons.calendar, color: AppTheme.primary, size: 10),
                        const SizedBox(width: 4),
                        Text(
                          "${b.date} • ${b.time}",
                          style: const TextStyle(fontSize: 9, color: AppTheme.primary, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(LucideIcons.wand2, color: AppTheme.primary, size: 10),
                    const SizedBox(width: 4),
                    Text(
                      "Style : Standard Care",
                      style: const TextStyle(fontSize: 10, color: AppTheme.primary, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (hasReview)
                  Text(
                    "“${b.review}”",
                    style: const TextStyle(
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                      color: AppTheme.lightText,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => _showReviewBottomSheet(context, parlour, b),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 24),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.rate_review, size: 12, color: AppTheme.primary),
                      label: const Text(
                        "Write a Review",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14.0),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.lightText,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Divider(color: Color(0xFFFFECEF), thickness: 1.5),
          ),
        ],
      ),
    );
  }
}
