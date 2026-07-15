import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme.dart';
import '../../models/service.dart';
import '../../providers/parlour_provider.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/service_form_sheet.dart';

/// Owner-facing detail page for a single catalogue service. This is the only
/// place a service's details can be edited.
class OwnerServiceDetailsScreen extends StatelessWidget {
  final String serviceId;

  const OwnerServiceDetailsScreen({super.key, required this.serviceId});

  @override
  Widget build(BuildContext context) {
    final parlour = Provider.of<ParlourProvider>(context);
    final service = parlour.serviceById(serviceId);

    if (service == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFFFF9FA),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.darkText, size: 20),
            onPressed: () => context.go('/owner/services'),
          ),
        ),
        body: const Center(
          child: Text(
            "This service is no longer in the catalogue.",
            style: TextStyle(color: AppTheme.lightText, fontWeight: FontWeight.w600),
          ),
        ),
        bottomNavigationBar: const OwnerBottomNav(activeTab: 'services'),
      );
    }

    final timesBooked = parlour.bookings.where((b) => b.serviceName == service.name).length;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.darkText, size: 20),
          onPressed: () => context.go('/owner/services'),
        ),
        title: const Text(
          "Service Details",
          style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkText),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Divider(color: Color(0xFFFFECEF), thickness: 1.5, height: 1),
            const SizedBox(height: 20),

            // Hero image
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: SizedBox(
                height: 200,
                width: double.infinity,
                child: _buildImage(service),
              ),
            ),
            const SizedBox(height: 20),

            // Title + active pill
            Row(
              children: [
                Expanded(
                  child: Text(
                    service.name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.darkText, fontFamily: 'Poppins'),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: service.isActive ? const Color(0xFFE8F5E9) : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    service.isActive ? "ACTIVE" : "HIDDEN",
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: service.isActive ? Colors.green[700] : AppTheme.lightText,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              service.category,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primary),
            ),
            const SizedBox(height: 20),

            // Facts grid
            Row(
              children: [
                Expanded(child: _buildFactCard(LucideIcons.indianRupee, "Price", "Rs. ${service.price.toInt()}")),
                const SizedBox(width: 12),
                Expanded(child: _buildFactCard(LucideIcons.clock, "Duration", "${service.duration} min")),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildFactCard(LucideIcons.tag, "Category", service.category)),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildFactCard(
                    LucideIcons.calendarCheck,
                    "Times booked",
                    timesBooked.toString(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Description — displayed, but deliberately not editable.
            const Text(
              "Description",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.darkText, fontFamily: 'Poppins'),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFECEF), width: 1.5),
              ),
              child: Text(
                service.description.isNotEmpty
                    ? service.description
                    : "No description added for this service yet.",
                style: const TextStyle(fontSize: 12, color: AppTheme.lightText, fontWeight: FontWeight.w500, height: 1.5),
              ),
            ),
            const SizedBox(height: 24),

            // Actions
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => showServiceFormSheet(context, existing: service),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.edit3, size: 16),
                          SizedBox(width: 8),
                          Text("Edit Details", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () => parlour.toggleServiceState(service.id),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFFECEF), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      service.isActive ? "Hide" : "Show",
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.darkText),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 50,
              child: OutlinedButton(
                onPressed: () => _confirmDelete(context, parlour, service),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFFCDD2), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.trash2, size: 15, color: AppTheme.danger),
                    SizedBox(width: 8),
                    Text("Remove from catalogue", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.danger)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: const OwnerBottomNav(activeTab: 'services'),
    );
  }

  Widget _buildImage(Service service) {
    const fallback = ColoredBox(
      color: Color(0xFFFFF0F2),
      child: Center(child: Icon(LucideIcons.sparkles, color: AppTheme.primary, size: 40)),
    );
    if (service.image.isEmpty) return fallback;
    return service.image.startsWith('http')
        ? Image.network(service.image, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => fallback)
        : Image.asset(service.image, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => fallback);
  }

  Widget _buildFactCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFECEF), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: AppTheme.lightText),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.lightText),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.darkText, fontFamily: 'Poppins'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, ParlourProvider parlour, Service service) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Service"),
        content: Text('Remove "${service.name}" from your catalogue? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              parlour.deleteService(service.id);
              Navigator.pop(ctx);
              context.go('/owner/services');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('"${service.name}" removed from catalogue.')),
              );
            },
            child: const Text("Delete", style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
  }
}
