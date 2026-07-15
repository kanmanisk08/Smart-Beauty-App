import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme.dart';
import '../../providers/parlour_provider.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/service_form_sheet.dart';

class OwnerServicesScreen extends StatelessWidget {
  const OwnerServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final parlour = Provider.of<ParlourProvider>(context);

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
          "Manage Services",
          style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkText),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
            child: IconButton(
              icon: const Icon(Icons.add, color: Colors.white, size: 18),
              tooltip: "Add a new service",
              onPressed: () => showServiceFormSheet(context),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Divider(color: Color(0xFFFFECEF), thickness: 1.5, height: 1),
          ),
          const SizedBox(height: 16),

          // Two metrics cards side-by-side
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    "Services Completed",
                    parlour.servicesCompleted == 1
                        ? "1 Service"
                        : "${parlour.servicesCompleted} Services",
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard("Avg Price", "Rs. ${parlour.averageServicePrice.round()}"),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Catalog headers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Treatment List",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkText, fontFamily: 'Poppins'),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    "Last Updated Today",
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Service catalog lists
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: parlour.services.length,
              itemBuilder: (context, index) {
                final s = parlour.services[index];
                
                // Set default mock icons & labels
                IconData catIcon = LucideIcons.scissors;
                String catName = "HAIR";
                if (s.category.toLowerCase().contains("nail")) {
                  catIcon = LucideIcons.brush;
                  catName = "NAILS";
                } else if (s.category.toLowerCase().contains("skin") || s.category.toLowerCase().contains("facial")) {
                  catIcon = LucideIcons.sparkles;
                  catName = "SKINCARE";
                }

                return GestureDetector(
                  // Tapping anywhere on the card opens its detail page.
                  onTap: () => context.go('/owner/service-details/${s.id}'),
                  child: Container(
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
                      // Image with check overlap badge
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: s.image.startsWith('http')
                                ? Image.network(
                                    s.image,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  )
                                : Image.asset(
                                    s.image,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          if (s.isActive)
                            Positioned(
                              top: 4,
                              left: 4,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check, color: Colors.white, size: 10),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 14),

                      // Details column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.name,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.darkText, fontFamily: 'Poppins'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              s.description.isNotEmpty ? s.description : "Professional service care for beautiful look.",
                              style: const TextStyle(fontSize: 10, color: AppTheme.lightText, fontWeight: FontWeight.w600),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            // Metrics row
                            Row(
                              children: [
                                const Icon(LucideIcons.clock, size: 12, color: AppTheme.lightText),
                                const SizedBox(width: 4),
                                Text(
                                  "${s.duration} MIN",
                                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.lightText),
                                ),
                                const SizedBox(width: 12),
                                Icon(catIcon, size: 12, color: AppTheme.lightText),
                                const SizedBox(width: 4),
                                Text(
                                  catName,
                                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.lightText),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Actions right-side: price, and an edit affordance that
                      // routes to the detail page (the only place to edit).
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: () => context.go('/owner/service-details/${s.id}'),
                            child: const Icon(LucideIcons.edit3, size: 13, color: AppTheme.lightText),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Rs. ${s.price.toInt()}",
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primary, fontFamily: 'Poppins'),
                          ),
                          const SizedBox(height: 10),
                          const Icon(Icons.chevron_right, size: 16, color: AppTheme.lightText),
                        ],
                      ),
                    ],
                  ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const OwnerBottomNav(activeTab: 'services'),
    );
  }

  Widget _buildMetricCard(String title, String val) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFECEF), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.lightText),
          ),
          const SizedBox(height: 4),
          Text(
            val,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkText, fontFamily: 'Poppins'),
          ),
        ],
      ),
    );
  }
}
