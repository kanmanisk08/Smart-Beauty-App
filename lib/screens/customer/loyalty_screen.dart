import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/parlour_provider.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/common.dart';

class CustomerLoyaltyScreen extends StatelessWidget {
  const CustomerLoyaltyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final parlour = Provider.of<ParlourProvider>(context);
    
    final user = auth.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Static offers matching Image 4
    final offers = [
      {
        "id": "off-1",
        "title": "Free Scalp Massage",
        "points": 200,
        "icon": LucideIcons.heart,
        "isLocked": false,
      },
      {
        "id": "off-2",
        "title": "15 % Off Any Service",
        "points": 500,
        "icon": LucideIcons.tag,
        "isLocked": false,
      },
      {
        "id": "off-3",
        "title": "Manicure Upgrade",
        "points": 1000,
        "icon": LucideIcons.brush,
        "isLocked": true,
      }
    ];

    // Calculate progress (850 out of 1000 points for platinum)
    final double progress = (user.points / 1000).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9FA), // Soft premium pink background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.darkText, size: 20),
          onPressed: () => context.go('/customer/book-appointment'),
        ),
        title: const Text(
          "Book Appointment",
          style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkText),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: Color(0xFFFFECEF), thickness: 1.5, height: 1),
                  const SizedBox(height: 20),

                  // Selected Services summary
                  const Text(
                    "Your Selection",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkText, fontFamily: 'Poppins'),
                  ),
                  const SizedBox(height: 12),
                  ...parlour.tempSelectedServiceIds.map((serviceId) {
                    final svc = parlour.services.firstWhere((s) => s.id == serviceId);
                    final date = parlour.tempSelectedDates[serviceId] ?? parlour.defaultDate;
                    final time = parlour.tempSelectedTimes[serviceId] ?? ParlourProvider.defaultTime;
                    
                    IconData iconData = LucideIcons.scissors;
                    if (svc.category.toLowerCase().contains('nail')) {
                      iconData = LucideIcons.gem;
                    } else if (svc.category.toLowerCase().contains('skin') || svc.name.toLowerCase().contains('facial')) {
                      iconData = LucideIcons.sparkles;
                    } else if (svc.category.toLowerCase().contains('makeup')) {
                      iconData = LucideIcons.palette;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFFECEF), width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Icon(iconData, color: AppTheme.primary, size: 16),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  svc.name,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.darkText),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Scheduled: $date at $time",
                                  style: const TextStyle(fontSize: 11, color: AppTheme.lightText, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            "Rs. ${svc.price.toInt()}",
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primary),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 24),

                  // Points Balance Hero Box Container
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFFFECEF), width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(22),
                            topRight: Radius.circular(22),
                          ),
                          child: Image.network(
                            "https://images.unsplash.com/photo-1562322140-8baeececf3df?auto=format&fit=crop&w=600&q=80",
                            height: 140,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "AVAILABLE BALANCE",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    user.points.toString(),
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.darkText,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    "Points",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.darkText,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Progress slider bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 8,
                                  backgroundColor: const Color(0xFFFFF0F2),
                                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "150 Points away from platinum Status",
                                style: TextStyle(fontSize: 11, color: AppTheme.lightText, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Earning since Jan 22",
                                    style: TextStyle(fontSize: 11, color: AppTheme.lightText, fontStyle: FontStyle.italic),
                                  ),
                                  SizedBox(
                                    height: 32,
                                    child: ElevatedButton(
                                      onPressed: () {},
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primary,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(horizontal: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                      ),
                                      child: const Text(
                                        "POINTS HISTORY",
                                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Exclusive Offers section header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Exclusive Offers",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkText,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      GestureDetector(
                        onTap: () {},
                        child: const Text(
                          "View all",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Vertically stacked offer items
                  ...offers.map((off) {
                    final points = off['points'] as int;
                    final title = off['title'] as String;
                    final icon = off['icon'] as IconData;
                    final isLocked = off['isLocked'] as bool;
                    
                    final isApplied = parlour.tempPointsApplied == points;
                    final canAfford = user.points >= points && !isLocked;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFFECEF), width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isLocked ? Colors.grey[200] : const Color(0xFFFFF0F2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              icon,
                              color: isLocked ? Colors.black38 : AppTheme.primary,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.darkText),
                                ),
                                Text(
                                  "$points PTS",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isLocked ? Colors.black38 : AppTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Action button on right
                          if (isLocked)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.lock_outline, size: 10, color: Colors.black45),
                                  SizedBox(width: 4),
                                  Text(
                                    "LOCKED",
                                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black45),
                                  ),
                                ],
                              ),
                            )
                          else
                            ElevatedButton(
                              onPressed: !canAfford && !isApplied
                                  ? null
                                  : () {
                                      if (isApplied) {
                                        parlour.applyPointsReward(0, 0.0);
                                      } else {
                                        parlour.applyPointsReward(points, 50.0);
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isApplied ? AppTheme.primary : AppTheme.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                isApplied ? "Applied" : "REDEEM",
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          // Complete payment bottom button
          Container(
            padding: const EdgeInsets.all(20),
            color: const Color(0xFFFFF9FA),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => context.go('/customer/checkout'),
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
                    Text(
                      "Complete payment",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.lock_outline, size: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
