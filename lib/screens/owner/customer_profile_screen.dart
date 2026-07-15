import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme.dart';
import '../../providers/parlour_provider.dart';
import '../../widgets/bottom_nav.dart';

class OwnerCustomerProfileScreen extends StatefulWidget {
  final String customerId;

  const OwnerCustomerProfileScreen({super.key, required this.customerId});

  @override
  State<OwnerCustomerProfileScreen> createState() => _OwnerCustomerProfileScreenState();
}

class _OwnerCustomerProfileScreenState extends State<OwnerCustomerProfileScreen> {
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final parlour = Provider.of<ParlourProvider>(context);

    // Find customer in directory list
    final customer = parlour.customers.firstWhere(
      (c) => c.id == widget.customerId,
      orElse: () => parlour.customers[0],
    );

    // Set initial text for textfield if empty
    if (_noteController.text != customer.privateNote) {
      _noteController.text = customer.privateNote;
    }

    final isPunctual = customer.badge == 'Punctual';
    final isOccasional = customer.badge == 'Occasional';

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9FA), // Soft premium pink, as everywhere else
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.darkText, size: 20),
          onPressed: () => context.go('/owner/directory'),
        ),
        title: const Text(
          "Customer Profile",
          style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkText),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(color: Color(0xFFFFECEF), thickness: 1.5, height: 1),
              const SizedBox(height: 20),

              // Profile avatar card details
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: const Color(0xFFFFF0F2),
                      child: Text(
                        _initials(customer.name),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      customer.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPunctual
                            ? AppTheme.successLight
                            : isOccasional
                                ? AppTheme.warningLight
                                : AppTheme.dangerLight,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: Text(
                        "${customer.badge} Badge",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isPunctual
                              ? AppTheme.success
                              : isOccasional
                                  ? AppTheme.warning
                                  : AppTheme.danger,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Stats Row — all derived from this client's real booking history
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(parlour.visitsFor(customer.name).toString(), "Visits"),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatItem("Rs. ${parlour.totalSpentFor(customer.name).toInt()}", "Total Spent"),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatItem(customer.points.toString(), "Points"),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Private Notes Box
              const Text(
                "OWNER'S PRIVATE NOTE",
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.lightText, letterSpacing: 1),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFDF5),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: const Color(0xFFFFEFA8), width: 1.5),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _noteController,
                      maxLines: 4,
                      onChanged: (val) {
                        parlour.saveClientPrivateNote(customer.id, val);
                      },
                      style: const TextStyle(fontSize: 12, color: AppTheme.darkText, height: 1.4),
                      decoration: const InputDecoration(
                        hintText: "Add a private note about client preferences...",
                        border: InputBorder.none,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        "Auto-saves when you edit",
                        style: TextStyle(fontSize: 8, color: Color(0xFFB27B00), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Contact detail items
              const Text(
                "Contact Details",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.darkText),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: AppTheme.border, width: 1.5),
                ),
                child: Column(
                  children: [
                    _buildDetailItem(LucideIcons.phone, "Phone Number", customer.phone),
                    const Divider(height: 1, color: AppTheme.border, indent: 48),
                    _buildDetailItem(LucideIcons.mail, "Email Address", customer.email),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Diagnostics Detail Box
              const Text(
                "Skin & Hair Diagnostics",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.darkText),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: AppTheme.border, width: 1.5),
                ),
                child: Column(
                  children: [
                    _buildDetailItem(LucideIcons.smile, "Skin Diagnostics", customer.skinType),
                    const Divider(height: 1, color: AppTheme.border, indent: 48),
                    _buildDetailItem(LucideIcons.scissors, "Hair Profile", customer.hairType),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const OwnerBottomNav(activeTab: 'appointments'),
    );
  }

  String _initials(String name) {
    if (name.trim().isEmpty) return "?";
    return name.trim().split(RegExp(r'\s+')).take(2).map((w) => w[0]).join().toUpperCase();
  }

  Widget _buildStatItem(String val, String lbl) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border, width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            val,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.darkText),
          ),
          const SizedBox(height: 4),
          Text(
            lbl,
            style: const TextStyle(fontSize: 10, color: AppTheme.lightText),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.lightText, size: 18),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.darkText),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 11, color: AppTheme.lightText),
          ),
        ],
      ),
    );
  }
}
