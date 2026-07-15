import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/parlour_provider.dart';
import '../../widgets/common.dart';

class CustomerCheckoutScreen extends StatelessWidget {
  const CustomerCheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final parlour = Provider.of<ParlourProvider>(context);

    final user = auth.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final selectedSvcs = parlour.tempSelectedServiceIds.isNotEmpty
        ? parlour.tempSelectedServiceIds.map((id) => parlour.services.firstWhere((s) => s.id == id)).toList()
        : [parlour.services[0]]; // fallback

    final selectedSvc = selectedSvcs.first;

    // Bill Calculations
    final subtotal = selectedSvcs.fold<double>(0.0, (sum, s) => sum + s.price);
    final discount = parlour.tempLoyaltyDiscount;
    final tax = double.parse(((subtotal - discount) * 0.08).toStringAsFixed(2));
    final total = double.parse((subtotal - discount + tax).toStringAsFixed(2));

    Future<void> _handleConfirmPayment() async {
      final booking = await parlour.createBookingOrder(
        user: user,
        service: selectedSvc,
        subtotal: subtotal,
        discount: discount,
        tax: tax,
        total: total,
      );

      if (context.mounted) {
        context.go('/customer/payment-confirm?id=${booking.id}');
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9FA), // Soft premium pink background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.darkText, size: 20),
          onPressed: () => context.go('/customer/loyalty'),
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

                  // Selected Services
                  Text(
                    selectedSvcs.length > 1 ? "Selected Services" : "Selected Service",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkText, fontFamily: 'Poppins'),
                  ),
                  const SizedBox(height: 12),
                  ...selectedSvcs.map((svc) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFFECEF), width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Rs. ${svc.price.toInt()}",
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  svc.name,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.darkText, fontFamily: 'Poppins'),
                                ),
                                const SizedBox(height: 4),
                                 Text(
                                   "${svc.duration} Mins  •  With Selvi",
                                   style: const TextStyle(fontSize: 11, color: AppTheme.lightText, fontWeight: FontWeight.w600),
                                 ),
                                 const SizedBox(height: 6),
                                 Row(
                                   children: [
                                     const Icon(LucideIcons.calendar, size: 10, color: AppTheme.primary),
                                     const SizedBox(width: 4),
                                     Text(
                                       "${parlour.tempSelectedDates[svc.id] ?? parlour.defaultDate} at ${parlour.tempSelectedTimes[svc.id] ?? ParlourProvider.defaultTime}",
                                       style: const TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.bold),
                                     ),
                                   ],
                                 ),
                               ],
                             ),
                           ),
                          const SizedBox(width: 14),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: svc.image.startsWith('http')
                                ? Image.network(
                                    svc.image,
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.cover,
                                  )
                                : Image.asset(
                                    svc.image,
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      height: 32,
                      child: ElevatedButton(
                        onPressed: () => context.go('/customer/services'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFF0F2),
                          foregroundColor: AppTheme.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: const Text(
                          "Edit Services",
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Loyalty Rewards Card
                  const Text(
                    "Loyalty Rewards",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkText, fontFamily: 'Poppins'),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFFECEF), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFF0F2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.sparkles, color: AppTheme.primary, size: 18),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${user.points} Points Available",
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.darkText),
                              ),
                              const Text(
                                "Use 50 points for a Rs.50 discount",
                                style: TextStyle(fontSize: 11, color: AppTheme.lightText, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: discount > 0,
                          activeColor: Colors.white,
                          activeTrackColor: AppTheme.primary,
                          inactiveThumbColor: Colors.grey[200],
                          inactiveTrackColor: Colors.grey[300],
                          onChanged: (val) {
                            if (val) {
                              if (user.points >= 50) {
                                parlour.applyPointsReward(50, 50.0);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("You need at least 50 points to apply a discount.")),
                                );
                              }
                            } else {
                              parlour.applyPointsReward(0, 0.0);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Payment Method
                  const Text(
                    "Payment Method",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkText, fontFamily: 'Poppins'),
                  ),
                  const SizedBox(height: 12),
                  Column(
                    children: [
                      _buildPaymentItem(
                        parlour: parlour,
                        method: "Credit Card **** 4242",
                        icon: LucideIcons.creditCard,
                      ),
                      const SizedBox(height: 10),
                      _buildPaymentItem(
                        parlour: parlour,
                        method: "Apple Pay",
                        icon: LucideIcons.smartphone,
                      ),
                      const SizedBox(height: 10),
                      _buildPaymentItem(
                        parlour: parlour,
                        method: "Pay at Salon",
                        icon: LucideIcons.wallet,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Pricing Invoice lines
                  _buildInvoiceRow("Subtotal", "Rs. ${subtotal.toStringAsFixed(2)}"),
                  if (discount > 0) ...[
                    const SizedBox(height: 8),
                    _buildInvoiceRow("Loyalty Reward Applied", "-Rs. ${discount.toStringAsFixed(2)}", isDiscount: true),
                  ],
                  const SizedBox(height: 8),
                  _buildInvoiceRow("Tax", "Rs. ${tax.toStringAsFixed(2)}"),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Divider(color: Color(0xFFFFECEF), thickness: 1.5),
                  ),
                  _buildInvoiceRow("Total", "Rs. ${total.toStringAsFixed(2)}", isTotal: true),
                  const SizedBox(height: 24),
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
                onPressed: _handleConfirmPayment,
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

  Widget _buildPaymentItem({
    required ParlourProvider parlour,
    required String method,
    required IconData icon,
  }) {
    final isSelected = parlour.tempPaymentMethod == method;
    return GestureDetector(
      onTap: () => parlour.setTempPaymentMethod(method),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primary : const Color(0xFFFFECEF),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppTheme.primary : AppTheme.lightText, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                method,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkText,
                ),
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppTheme.primary : Colors.black26,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceRow(String label, String value, {bool isDiscount = false, bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 15 : 13,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isDiscount 
                ? AppTheme.primary 
                : (isTotal ? AppTheme.darkText : AppTheme.lightText),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 16 : 13,
            fontWeight: isTotal || isDiscount ? FontWeight.bold : FontWeight.w600,
            color: isDiscount 
                ? AppTheme.primary 
                : (isTotal ? AppTheme.darkText : AppTheme.darkText),
            fontFamily: isTotal ? 'Poppins' : null,
          ),
        ),
      ],
    );
  }
}
