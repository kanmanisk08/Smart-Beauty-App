import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme.dart';

class CustomerBottomNav extends StatelessWidget {
  final String activeTab;

  const CustomerBottomNav({super.key, required this.activeTab});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFF9FA), // Matching premium background
        border: Border(top: BorderSide(color: Color(0xFFFFECEF), width: 1.5)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              context: context,
              icon: Icons.home,
              label: "Home",
              isActive: activeTab == 'home',
              path: '/customer/dashboard',
            ),
            _buildNavItem(
              context: context,
              icon: LucideIcons.flower2,
              label: "Services",
              isActive: activeTab == 'services',
              path: '/customer/services',
            ),
            _buildNavItem(
              context: context,
              icon: Icons.calendar_month,
              label: "Appointments",
              isActive: activeTab == 'bookings',
              path: '/customer/appointments',
            ),
            _buildNavItem(
              context: context,
              icon: Icons.person,
              label: "Profile",
              isActive: activeTab == 'profile',
              path: '/customer/profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isActive,
    required String path,
  }) {
    return InkWell(
      onTap: () => context.go(path),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? AppTheme.primary : AppTheme.lightText,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? AppTheme.primary : AppTheme.lightText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OwnerBottomNav extends StatelessWidget {
  final String activeTab;

  const OwnerBottomNav({super.key, required this.activeTab});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFF9FA),
        border: Border(top: BorderSide(color: Color(0xFFFFECEF), width: 1.5)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              context: context,
              icon: Icons.home,
              label: "Dashboard",
              isActive: activeTab == 'dashboard',
              path: '/owner/dashboard',
            ),
            _buildNavItem(
              context: context,
              icon: LucideIcons.flower2,
              label: "Services",
              isActive: activeTab == 'services',
              path: '/owner/services',
            ),
            // Mockup wireless pulse center button
            GestureDetector(
              onTap: () => context.go('/owner/happening-now'),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: const Icon(Icons.sensors, color: Colors.white, size: 20),
              ),
            ),
            _buildNavItem(
              context: context,
              icon: Icons.calendar_month,
              label: "Schedule",
              isActive: activeTab == 'schedule',
              path: '/owner/schedule',
            ),
            _buildNavItem(
              context: context,
              icon: Icons.receipt_long,
              label: "Appointments",
              isActive: activeTab == 'appointments',
              path: '/owner/requests',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isActive,
    required String path,
  }) {
    return InkWell(
      onTap: () => context.go(path),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        // Kept tight: five destinations plus the centre button have to fit a
        // 393px-wide phone frame without overflowing.
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? AppTheme.primary : AppTheme.lightText,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? AppTheme.primary : AppTheme.lightText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
