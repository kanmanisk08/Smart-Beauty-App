import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';

class RoleSelectorPills extends StatelessWidget {
  final AuthRole activeRole;
  final ValueChanged<AuthRole> onRoleChanged;

  const RoleSelectorPills({
    super.key,
    required this.activeRole,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildPill(
            label: "Customer",
            icon: Icons.person_outline,
            isActive: activeRole == AuthRole.customer,
            onTap: () => onRoleChanged(AuthRole.customer),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildPill(
            label: "Owner/Staff",
            icon: Icons.business_center_outlined,
            isActive: activeRole == AuthRole.owner,
            onTap: () => onRoleChanged(AuthRole.owner),
          ),
        ),
      ],
    );
  }

  Widget _buildPill({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: isActive ? AppTheme.primary : AppTheme.border,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isActive ? AppTheme.primary : AppTheme.lightText,
              size: 20,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? AppTheme.primary : AppTheme.darkText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
