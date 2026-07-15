import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/bottom_nav.dart';

class CustomerGiftCardsScreen extends StatefulWidget {
  const CustomerGiftCardsScreen({super.key});

  @override
  State<CustomerGiftCardsScreen> createState() => _CustomerGiftCardsScreenState();
}

class _CustomerGiftCardsScreenState extends State<CustomerGiftCardsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Predefined points redemption list
  final List<Map<String, dynamic>> _pointsRewards = [
    {
      "id": "rew-1",
      "title": "Classic Haircut Coupon",
      "desc": "Get a free Classic Hair Trim or conditioning treatment on your next visit.",
      "points": 150,
      "value": "Rs. 300 Value",
      "color": Color(0xFFFE8F9E),
    },
    {
      "id": "rew-2",
      "title": "Selvi's Gold Gift Card",
      "desc": "Can be applied as flat discount on any spa, nail, or skincare treatment.",
      "points": 500,
      "value": "Rs. 1000 Value",
      "color": Color(0xFFFF597B),
    },
    {
      "id": "rew-3",
      "title": "Premium Pamper Day Pass",
      "desc": "Includes choice of Hydrating Facial, Gel Pedicure, and custom Blow Dry styling.",
      "points": 900,
      "value": "Rs. 2000 Value",
      "color": Color(0xFF8B5CF6),
    },
    {
      "id": "rew-4",
      "title": "Ultimate Bridal Makeover Pass",
      "desc": "Get Rs. 5000 off on bridal prep packages, wedding makeup, and hair sets.",
      "points": 2000,
      "value": "Rs. 5000 Value",
      "color": Color(0xFFD97706),
    },
  ];

  // Predefined buy cards list
  final List<Map<String, dynamic>> _buyCards = [
    {"value": 500, "price": 450, "bonus": "Get 50 free loyalty points"},
    {"value": 1000, "price": 900, "bonus": "Get 100 free loyalty points"},
    {"value": 2000, "price": 1800, "bonus": "Get 250 free loyalty points"},
    {"value": 5000, "price": 4500, "bonus": "Get 700 free loyalty points"},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _generatePromoCode() {
    final random = Random();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return 'GC-' + List.generate(8, (index) => chars[random.nextInt(chars.length)]).join();
  }

  void _redeemReward(BuildContext context, AuthProvider auth, Map<String, dynamic> reward) async {
    final user = auth.currentUser;
    if (user == null) return;

    if (user.points < reward['points']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Insufficient Points! You need ${reward['points'] - user.points} more points to redeem this card."),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    // Deduct points
    final newPoints = user.points - (reward['points'] as int);
    await auth.updateUserPoints(newPoints);

    final promoCode = _generatePromoCode();

    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF0F2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.gift, color: AppTheme.primary, size: 40),
                ),
                const SizedBox(height: 18),
                const Text(
                  "Redemption Successful!",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkText, fontFamily: 'Poppins'),
                ),
                const SizedBox(height: 8),
                Text(
                  "You have successfully redeemed ${reward['title']}.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: AppTheme.lightText),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF9FA),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFECEF), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "YOUR GIFT CARD CODE",
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.primary, letterSpacing: 1),
                      ),
                      const SizedBox(height: 6),
                      SelectableText(
                        promoCode,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.darkText, fontFamily: 'Poppins', letterSpacing: 2),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Show this code at check-in to apply discount.",
                        style: TextStyle(fontSize: 9, color: AppTheme.lightText),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: const Text("Got it, Thanks!", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
        ),
      );
    }
  }

  void _buyGiftCard(BuildContext context, AuthProvider auth, Map<String, dynamic> card) async {
    final user = auth.currentUser;
    if (user == null) return;

    // Simulate payment and add points
    final bonusPoints = card['value'] == 500 ? 50 : card['value'] == 1000 ? 100 : card['value'] == 2000 ? 250 : 700;
    final newPoints = user.points + bonusPoints;
    await auth.updateUserPoints(newPoints);

    final promoCode = _generatePromoCode();

    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.checkCircle2, color: Colors.green, size: 40),
                ),
                const SizedBox(height: 18),
                const Text(
                  "Purchase Successful!",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkText, fontFamily: 'Poppins'),
                ),
                const SizedBox(height: 8),
                Text(
                  "Purchased Rs. ${card['value']} Card for Rs. ${card['price']}. Points bonus added!",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: AppTheme.lightText),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F8F5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFC8E6C9), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "GIFT CARD CODE",
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.green, letterSpacing: 1),
                      ),
                      const SizedBox(height: 6),
                      SelectableText(
                        promoCode,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.darkText, fontFamily: 'Poppins', letterSpacing: 2),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Share this code with your friend!",
                        style: TextStyle(fontSize: 9, color: AppTheme.lightText),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: const Text("Awesome!", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.darkText, size: 20),
          onPressed: () => context.go('/customer/dashboard'),
        ),
        title: const Text(
          "Gift Cards & Rewards",
          style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkText),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const Divider(color: Color(0xFFFFECEF), thickness: 1.5, height: 1),
          
          // Gorgeous Points Balance Banner
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, Color(0xFFFF7E96)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "YOUR REWARDS BALANCE",
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "${user.points} PTS",
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, fontFamily: 'Poppins'),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Redeem for free services or cash-equivalent gift passes.",
                        style: TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.sparkles, color: Colors.white, size: 28),
                ),
              ],
            ),
          ),

          // Custom design TabBar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFECEF), width: 1.5),
            ),
            child: TabBar(
              controller: _tabController,
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
                Tab(text: "Redeem Points"),
                Tab(text: "Buy Gift Cards"),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Scrollable list content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Redeem tab
                _buildRedeemList(auth),
                // Buy tab
                _buildBuyList(auth),
              ],
            ),
          )
        ],
      ),
      bottomNavigationBar: const CustomerBottomNav(activeTab: 'dashboard'),
    );
  }

  Widget _buildRedeemList(AuthProvider auth) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _pointsRewards.length,
      itemBuilder: (context, index) {
        final item = _pointsRewards[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFFECEF), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Title / Value
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'] as String,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.darkText, fontFamily: 'Poppins'),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item['value'] as String,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: item['color'] as Color),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Points Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: (item['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      "${item['points']} PTS",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: item['color'] as Color),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 12),
              Text(
                item['desc'] as String,
                style: const TextStyle(fontSize: 11, color: AppTheme.lightText, height: 1.4),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Divider(color: Color(0xFFFFECEF), height: 1, thickness: 1.5),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Exchanges instantly",
                    style: TextStyle(fontSize: 10, color: AppTheme.lightText, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(
                    height: 34,
                    child: ElevatedButton(
                      onPressed: () => _redeemReward(context, auth, item),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: item['color'] as Color,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                      ),
                      child: const Text("Redeem Now", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildBuyList(AuthProvider auth) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _buyCards.length,
      itemBuilder: (context, index) {
        final item = _buyCards[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFFECEF), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Selvi's E-Gift Voucher",
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.lightText),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Rs. ${item['value']} Card",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.darkText, fontFamily: 'Poppins'),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F2),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFFFECEF), width: 1),
                    ),
                    child: const Icon(LucideIcons.gift, color: AppTheme.primary, size: 20),
                  )
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F8F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.sparkles, color: Colors.green, size: 14),
                    const SizedBox(width: 8),
                    Text(
                      item['bonus'] as String,
                      style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Divider(color: Color(0xFFFFECEF), height: 1, thickness: 1.5),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "PROMO VALUE PRICE",
                        style: TextStyle(fontSize: 8, color: AppTheme.lightText, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                      Text(
                        "Rs. ${item['price']}",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.primary, fontFamily: 'Poppins'),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      onPressed: () => _buyGiftCard(context, auth, item),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                      child: const Text("Purchase Now", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }
}
