import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/parlour_provider.dart';
import '../../widgets/bottom_nav.dart';

class OwnerDirectoryScreen extends StatefulWidget {
  const OwnerDirectoryScreen({super.key});

  @override
  State<OwnerDirectoryScreen> createState() => _OwnerDirectoryScreenState();
}

class _OwnerDirectoryScreenState extends State<OwnerDirectoryScreen> {
  String _searchQuery = '';
  String _activeFilter = 'All';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final parlour = Provider.of<ParlourProvider>(context);

    // Filter logic
    final filteredCustomers = parlour.customers.where((c) {
      final matchesQuery = c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.phone.contains(_searchQuery) ||
          c.email.toLowerCase().contains(_searchQuery.toLowerCase());
      
      if (_activeFilter == 'All') return matchesQuery;
      return matchesQuery && c.badge.toLowerCase() == _activeFilter.toLowerCase();
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9FA), // Soft premium pink background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.darkText, size: 20),
          onPressed: () => context.go('/owner/requests'),
        ),
        title: const Text(
          "Customer Directory",
          style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkText),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Divider(color: Color(0xFFFFECEF), thickness: 1.5, height: 1),
          ),
          const SizedBox(height: 12),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                decoration: const InputDecoration(
                  hintText: "Search by name or contact...",
                  hintStyle: TextStyle(fontSize: 12, color: AppTheme.lightText, fontWeight: FontWeight.w600),
                  prefixIcon: Icon(Icons.search, color: AppTheme.lightText, size: 18),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),

          // Horizontal Filter Segmented Pills scroll
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Row(
              children: [
                _buildFilterPill("All", Icons.apps),
                const SizedBox(width: 8),
                _buildFilterPill("Punctual", Icons.verified),
                const SizedBox(width: 8),
                _buildFilterPill("Occasional", Icons.history),
                const SizedBox(width: 8),
                _buildFilterPill("New Customer", Icons.stars),
              ],
            ),
          ),

          // Total clients label and sort icon
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${filteredCustomers.length} Total Clients",
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.darkText, fontFamily: 'Poppins'),
                ),
                GestureDetector(
                  onTap: () {},
                  child: const Row(
                    children: [
                      Icon(Icons.swap_vert, size: 16, color: AppTheme.primary),
                      SizedBox(width: 4),
                      Text(
                        "Sort",
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Clients lists
          Expanded(
            child: filteredCustomers.isEmpty
                ? const Center(
                    child: Text("No customers found.", style: TextStyle(color: AppTheme.lightText)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: filteredCustomers.length,
                    itemBuilder: (context, index) {
                      final c = filteredCustomers[index];
                      
                      // Fallback badges styling
                      Color badgeBg = const Color(0xFFFFF0F2);
                      Color badgeText = AppTheme.primary;
                      if (c.badge == 'Punctual') {
                        badgeBg = const Color(0xFFE8F5E9);
                        badgeText = Colors.green[700]!;
                      } else if (c.badge == 'Occasional') {
                        badgeBg = const Color(0xFFFFF8E1);
                        badgeText = Colors.amber[800]!;
                      }

                      // Real "last visit" and "preferred service" from booking history
                      final lastVisit = parlour.lastVisitFor(c.name);
                      final lastVisitText = lastVisit == null
                          ? "No visits yet"
                          : "Last Visit: ${_formatVisitDate(lastVisit.date)} • Rs. ${lastVisit.totalPaid.toInt()}";
                      final preferred = parlour.preferredServiceFor(c.name);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFFFECEF), width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  // Profile initials avatar
                                  _buildInitialAvatar(c.name),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              c.name,
                                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.darkText, fontFamily: 'Poppins'),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: badgeBg,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                c.badge,
                                                style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: badgeText),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          lastVisitText,
                                          style: const TextStyle(fontSize: 11, color: AppTheme.lightText, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Right circular action — tap to see contact
                                  GestureDetector(
                                    onTap: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text("${c.name}: ${c.phone}  •  ${c.email}")),
                                      );
                                    },
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFFF0F2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.phone,
                                        color: AppTheme.primary,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Preferred service bottom row container
                            Container(
                              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF0F2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "PREFERRED SERVICE",
                                        style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppTheme.lightText, letterSpacing: 0.5),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        preferred.isEmpty ? "No bookings yet" : preferred,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.darkText),
                                      ),
                                    ],
                                  ),
                                  TextButton(
                                    onPressed: () => context.go('/owner/customer-profile/${c.id}'),
                                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                                    child: const Text(
                                      "DETAILS  >",
                                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.primary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const OwnerBottomNav(activeTab: 'appointments'),
    );
  }

  /// Converts a stored "YYYY-MM-DD" date into a friendly "12 Oct" label.
  String _formatVisitDate(String isoDate) {
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    final parts = isoDate.split('-');
    if (parts.length != 3) return isoDate;
    final month = int.tryParse(parts[1]) ?? 1;
    final day = int.tryParse(parts[2]) ?? 1;
    return "$day ${months[(month - 1).clamp(0, 11)]}";
  }

  Widget _buildInitialAvatar(String name) {
    final initials = name.trim().isEmpty
        ? "?"
        : name.trim().split(RegExp(r'\s+')).take(2).map((w) => w[0]).join().toUpperCase();
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        initials,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primary, fontFamily: 'Poppins'),
      ),
    );
  }

  Widget _buildFilterPill(String filterName, IconData icon) {
    final isActive = _activeFilter == filterName;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeFilter = filterName;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppTheme.primary : const Color(0xFFFFECEF),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isActive ? Colors.white : AppTheme.lightText, size: 14),
            const SizedBox(width: 6),
            Text(
              filterName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : AppTheme.lightText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
