import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme.dart';
import '../../providers/parlour_provider.dart';
import '../../models/service.dart';

class ServiceDetailsScreen extends StatefulWidget {
  final String serviceId;

  const ServiceDetailsScreen({super.key, required this.serviceId});

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  // Extras selection state
  final Map<String, bool> _selectedExtras = {
    "Aromatherapy Oils": false,
    "15-Min Extra Massage": false,
    "Premium Organic Products": false,
    "Complimentary Herbal Tea": true,
  };

  final Map<String, double> _extraPrices = {
    "Aromatherapy Oils": 150.0,
    "15-Min Extra Massage": 300.0,
    "Premium Organic Products": 200.0,
    "Complimentary Herbal Tea": 0.0,
  };

  @override
  Widget build(BuildContext context) {
    final parlour = Provider.of<ParlourProvider>(context);
    
    // Find the current service
    final svc = parlour.services.firstWhere(
      (s) => s.id == widget.serviceId,
      orElse: () => parlour.services.first,
    );

    // Dynamic benefits and afterlook based on service name/category
    List<String> benefits = [];
    String afterlook = "";

    final nameLower = svc.name.toLowerCase();
    final catLower = svc.category.toLowerCase();

    if (nameLower.contains("cut") || nameLower.contains("trim")) {
      benefits = [
        "Eliminates split ends and breakage for healthy hair growth.",
        "Adds bouncy volume, custom movement, and frames your face.",
        "Enhances natural hair texture and simplifies daily styling."
      ];
      afterlook = "Freshly styled, smooth, and lightweight hair with clean ends and professional movement. It will hold its shape beautifully for weeks.";
    } else if (nameLower.contains("spa") || nameLower.contains("condition") || nameLower.contains("treatment")) {
      benefits = [
        "Deeply nourishes hair follicles to restore protein and hydration.",
        "Improves blood circulation in the scalp, promoting relaxation.",
        "Tames frizz and leaves hair exceptionally soft and shiny."
      ];
      afterlook = "Silky, touchably soft hair with a healthy gloss. Your scalp will feel refreshed, hydrated, and completely rejuvenated.";
    } else if (catLower.contains("nail") || nameLower.contains("mani") || nameLower.contains("pedi")) {
      benefits = [
        "Promotes nail health by clean-shaping and cuticle nourishment.",
        "Gently exfoliates dead skin cells, restoring skin suppleness.",
        "Relaxing massage boosts hand/foot blood flow."
      ];
      afterlook = "Perfectly shaped, shiny nails with clean cuticles. Gel polish will look mirror-like, glossy, and remain chip-free for up to 3 weeks.";
    } else if (catLower.contains("skin") || nameLower.contains("facial")) {
      benefits = [
        "Deep cleanses pores to eliminate impurities and blackheads.",
        "Hydrates dry skin layers, leaving a bright and glowing tone.",
        "Stimulates skin cellular turnover and increases elasticity."
      ];
      afterlook = "Radiant, plump, and deeply hydrated skin with an immediate glow. Any redness will soothe within hours, leaving a smooth complexion.";
    } else {
      benefits = [
        "Boosts confidence with a customized professional styling touch.",
        "Uses top-tier, salon-grade nourishing products.",
        "Designed to relax and pamper you from start to finish."
      ];
      afterlook = "A flawless, long-lasting finish styled perfectly to match your preference, making you look and feel your absolute best.";
    }

    double extrasTotal = 0.0;
    _selectedExtras.forEach((key, selected) {
      if (selected) {
        extrasTotal += (_extraPrices[key] ?? 0.0);
      }
    });
    final totalCost = svc.price + extrasTotal;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9FA), // Soft premium pink background
      body: CustomScrollView(
        slivers: [
          // Elegant Sliver App Bar with Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppTheme.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              onPressed: () => context.go('/customer/services'),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  svc.image.startsWith('http')
                      ? Image.network(svc.image, fit: BoxFit.cover)
                      : Image.asset(svc.image, fit: BoxFit.cover),
                  // Dark gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.4),
                          Colors.black.withOpacity(0.0),
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Details content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      svc.category.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Service Name
                  Text(
                    svc.name,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkText,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Duration & Stylist Info
                  Row(
                    children: [
                      const Icon(LucideIcons.clock, size: 14, color: AppTheme.lightText),
                      const SizedBox(width: 4),
                      Text(
                        "${svc.duration} Minutes",
                        style: const TextStyle(fontSize: 12, color: AppTheme.lightText, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 16),
                      const Icon(LucideIcons.user, size: 14, color: AppTheme.lightText),
                      const SizedBox(width: 4),
                      const Text(
                        "Stylist: Selvi",
                        style: TextStyle(fontSize: 12, color: AppTheme.lightText, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Price Tag Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFFECEF), width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "SERVICE PRICE",
                              style: TextStyle(fontSize: 10, color: AppTheme.lightText, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 2),
                            Text(
                              "Base Rate",
                              style: TextStyle(fontSize: 12, color: AppTheme.darkText, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        Text(
                          "Rs. ${svc.price.toInt()}",
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Service Description
                  const Text(
                    "Description",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    svc.description,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: AppTheme.lightText,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Key Benefits
                  const Text(
                    "Key Benefits",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkText,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Column(
                    children: benefits.map((b) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle_outline, color: AppTheme.primary, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                b,
                                style: const TextStyle(fontSize: 13, color: AppTheme.lightText),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // The Afterlook
                  const Text(
                    "The Afterlook",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFFECEF), width: 1),
                    ),
                    child: Text(
                      afterlook,
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Premium Add-ons / Extras Section
                  const Text(
                    "Enhance Your Experience (Extras)",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkText,
                    ),
                  ),
                  const Text(
                    "Select premium add-ons for your service",
                    style: TextStyle(fontSize: 11, color: AppTheme.lightText),
                  ),
                  const SizedBox(height: 12),

                  // List of Extras
                  Column(
                    children: _selectedExtras.keys.map((extraName) {
                      final isSelected = _selectedExtras[extraName]!;
                      final price = _extraPrices[extraName]!;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? AppTheme.primary : const Color(0xFFFFECEF),
                            width: 1.5,
                          ),
                        ),
                        child: CheckboxListTile(
                          activeColor: AppTheme.primary,
                          title: Text(
                            extraName,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.darkText),
                          ),
                          subtitle: Text(
                            price > 0.0 ? "+Rs. ${price.toInt()}" : "Complimentary",
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected ? AppTheme.primary : AppTheme.lightText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          value: isSelected,
                          onChanged: (bool? val) {
                            setState(() {
                              _selectedExtras[extraName] = val ?? false;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, -4),
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
                const Text(
                  "Total Cost",
                  style: TextStyle(fontSize: 11, color: AppTheme.lightText, fontWeight: FontWeight.w500),
                ),
                Text(
                  "Rs. ${totalCost.toInt()}",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkText, fontFamily: 'Poppins'),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () {
                // Ensure this service is added to the selection
                if (!parlour.tempSelectedServiceIds.contains(svc.id)) {
                  parlour.toggleTempServiceId(svc.id);
                }
                context.go('/customer/book-appointment');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Row(
                children: [
                  Text(
                    "Book Service",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.calendar_month, size: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
