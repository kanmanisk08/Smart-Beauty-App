import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme.dart';
import '../../providers/parlour_provider.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/common.dart';
import '../../models/service.dart';

class CustomerServicesScreen extends StatefulWidget {
  const CustomerServicesScreen({super.key});

  @override
  State<CustomerServicesScreen> createState() => _CustomerServicesScreenState();
}

class _CustomerServicesScreenState extends State<CustomerServicesScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final parlour = Provider.of<ParlourProvider>(context);
    
    // Dynamically retrieve unique categories from the database
    final categories = [
      'All',
      ...parlour.services.map((s) => s.category).toSet().toList()
    ];

    // Filter services based on category and search query
    final filteredServices = parlour.services.where((svc) {
      if (!svc.isActive) return false;
      
      final matchesCategory = _selectedCategory == 'All' || svc.category == _selectedCategory;
      final matchesQuery = svc.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          svc.description.toLowerCase().contains(_searchQuery.toLowerCase());
          
      return matchesCategory && matchesQuery;
    }).toList();

    // Group services by category for layout
    final Map<String, List<Service>> groupedServices = {};
    for (var svc in filteredServices) {
      groupedServices.putIfAbsent(svc.category, () => []).add(svc);
    }

    // Check if any service is selected
    final selectedServiceIds = parlour.tempSelectedServiceIds;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9FA), // Soft premium pink background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.darkText, size: 20),
          onPressed: () => context.go('/customer/dashboard'),
        ),
        title: const Text(
          "Our Services",
          style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkText),
        ),
        centerTitle: true,
        actions: [
          _buildCartAction(context, selectedServiceIds.length),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              decoration: InputDecoration(
                hintText: "Search Your needs here",
                hintStyle: const TextStyle(color: AppTheme.lightText, fontSize: 12),
                prefixIcon: const Icon(LucideIcons.search, color: AppTheme.lightText, size: 18),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Color(0xFFFFECEF), width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                ),
              ),
            ),
          ),

          // Horizontal Category Pills
          const SizedBox(height: 8),
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                // Formatting for display
                final cat = categories[index];
                var displayCat = cat;
                if (cat == 'Haircuts & Styling') displayCat = 'Haircuts';
                if (cat == 'Hair Coloring & Treatments') displayCat = 'Colourings';
                if (cat == 'Nails & Extensions') displayCat = 'Nails';

                final isActive = cat == _selectedCategory;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = cat;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive ? AppTheme.primary : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive ? AppTheme.primary : const Color(0xFFFFECEF),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      displayCat,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isActive ? Colors.white : AppTheme.lightText,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // List of Grouped Services
          Expanded(
            child: filteredServices.isEmpty
                ? const Center(
                    child: Text(
                      "No services match your search.",
                      style: TextStyle(color: AppTheme.lightText),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: groupedServices.keys.length,
                    itemBuilder: (context, groupIndex) {
                      final categoryName = groupedServices.keys.elementAt(groupIndex);
                      final services = groupedServices[categoryName]!;
                      
                      // Display group header
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                categoryName == 'Haircuts & Styling' ? 'Popular Services' : categoryName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.darkText,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              const Text(
                                "View All",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // List of items in this group
                          ...services.map((svc) {
                             final isSelected = parlour.tempSelectedServiceIds.contains(svc.id);
                             return GestureDetector(
                               onTap: () => context.go('/customer/service-details?id=${svc.id}'),
                               child: Container(
                                 margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFFFECEF), width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primary.withOpacity(0.02),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ],
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: svc.image.startsWith('http')
                                        ? Image.network(
                                            svc.image,
                                            width: 68,
                                            height: 68,
                                            fit: BoxFit.cover,
                                          )
                                        : Image.asset(
                                            svc.image,
                                            width: 68,
                                            height: 68,
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          svc.name,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.darkText,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          svc.description,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: AppTheme.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Icon(LucideIcons.clock, size: 10, color: AppTheme.lightText),
                                            const SizedBox(width: 4),
                                            Text(
                                              "${svc.duration} mins",
                                              style: const TextStyle(fontSize: 10, color: AppTheme.lightText, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Price + selection control column
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        "Rs. ${svc.price.toInt()}",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                       GestureDetector(
                                         onTap: () {
                                           parlour.toggleTempServiceId(svc.id);
                                         },
                                        child: Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: isSelected ? AppTheme.primary : const Color(0xFFFFECEF),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            isSelected ? Icons.check : Icons.add,
                                            color: isSelected ? Colors.white : AppTheme.primary,
                                            size: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                             );
                           }),
                          const SizedBox(height: 20),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
      // Persistent bottom cart/booking banner if one is selected, else standard navigation bar
      bottomNavigationBar: selectedServiceIds.isNotEmpty
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              color: const Color(0xFFFFF9FA),
              child: Container(
                 padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Total (${selectedServiceIds.length} item${selectedServiceIds.length > 1 ? 's' : ''})",
                          style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Rs. ${selectedServiceIds.map((id) => parlour.services.firstWhere((s) => s.id == id).price).fold<double>(0.0, (sum, price) => sum + price).toInt()}",
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Poppins'),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      // Straight into the booking funnel with every selected
                      // service — not the detail page of just the first one.
                      onPressed: () => context.go('/customer/book-appointment'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Text(
                            "Book now",
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_ios, size: 10),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          : const CustomerBottomNav(activeTab: 'services'),
    );
  }

  /// Cart button showing how many services are queued. Tapping it carries the
  /// whole selection into the booking funnel.
  Widget _buildCartAction(BuildContext context, int count) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: AppTheme.darkText, size: 20),
            tooltip: count == 0 ? "No services selected yet" : "Book $count selected",
            onPressed: () {
              if (count == 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Pick a service first — tap one to add it.")),
                );
                return;
              }
              context.go('/customer/book-appointment');
            },
          ),
          if (count > 0)
            Positioned(
              top: 6,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                child: Text(
                  count.toString(),
                  style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
