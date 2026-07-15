import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/parlour_provider.dart';
import '../../widgets/bottom_nav.dart';

class OwnerDashboardScreen extends StatelessWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final parlour = Provider.of<ParlourProvider>(context);

    // Real metrics, all derived from live Firestore bookings
    final pendingList = parlour.pendingBookings;

    final revenue = parlour.monthlyRevenue;
    final capacity = parlour.bookedSlotsPercent;
    final revenueChange = parlour.revenueChangePercent;
    final bookedToday = parlour.bookedSlotsToday;
    final liveSession = parlour.liveSession;
    final sessionState =
        liveSession != null ? parlour.stateFor(liveSession) : SessionState.done;
    final isSessionRunning =
        sessionState == SessionState.running || sessionState == SessionState.overrun;
    // The clock only appears once a session is inside its 5-minute reminder
    // window (or is actually running) — a countdown hours out is just noise.
    final showCountdown = isSessionRunning || sessionState == SessionState.upNext;

    // Nudge the owner the moment a session enters that window. Marked as
    // announced synchronously so a rebuild mid-frame can't double-fire it.
    final alert = parlour.upNextAlert;
    if (alert != null) {
      parlour.markUpNextAnnounced(alert.id);
      final startsAt = parlour.timeRangeFor(alert).split(' - ').first;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        // A banner rides at the top of the screen, where a reminder belongs —
        // rather than a snackbar the owner has to catch at the bottom.
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentMaterialBanner();
        messenger.showMaterialBanner(
          MaterialBanner(
            backgroundColor: const Color(0xFF0F1012),
            surfaceTintColor: Colors.transparent,
            dividerColor: Colors.transparent,
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
            leading: const Icon(LucideIcons.bellRing, color: AppTheme.primary, size: 20),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Starting in 5 minutes",
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  "${alert.serviceName} with ${alert.customerName} at $startsAt",
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  messenger.hideCurrentMaterialBanner();
                  context.go('/owner/happening-now');
                },
                child: const Text("VIEW", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary)),
              ),
              TextButton(
                onPressed: messenger.hideCurrentMaterialBanner,
                child: const Text("DISMISS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white38)),
              ),
            ],
          ),
        );
        // Clear it after a while so it doesn't sit over the dashboard forever.
        Future.delayed(const Duration(seconds: 12), () {
          if (messenger.mounted) messenger.hideCurrentMaterialBanner();
        });
      });
    }

    final revenueDesc = revenueChange == null
        ? "First month of tracking"
        : "${revenueChange >= 0 ? '+' : ''}${revenueChange.toStringAsFixed(0)}% vs last month";

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9FA), // Soft premium pink, matching the customer app
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom header, mirroring the customer dashboard.
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      // Logo in a soft pink circular container
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0F2),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFFFECEF), width: 1.5),
                        ),
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 38,
                          height: 38,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            LucideIcons.flower,
                            color: AppTheme.primary,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Application name as the heading, owner beneath it.
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Selvi's Beauty Parlour",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.darkText,
                                fontFamily: 'Poppins',
                                height: 1.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              auth.currentUser?.name ?? 'Selvi',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
                                letterSpacing: 0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Requests bell with a live pending count
                      _buildHeaderIcon(
                        icon: LucideIcons.bell,
                        onTap: () => context.go('/owner/requests'),
                        badgeCount: pendingList.length,
                      ),
                      const SizedBox(width: 8),
                      _buildHeaderIcon(
                        icon: LucideIcons.logOut,
                        color: AppTheme.danger,
                        onTap: () async {
                          await auth.signOut();
                          if (context.mounted) context.go('/');
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

              // Metrics Card Grid
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: "Monthly Revenue",
                      value: "Rs. ${revenue.toInt().toString()}",
                      desc: revenueDesc,
                      icon: LucideIcons.dollarSign,
                      iconColor: AppTheme.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      title: "Booked Slots",
                      value: "$capacity%",
                      desc: bookedToday == 1
                          ? "1 session booked today"
                          : "$bookedToday sessions booked today",
                      icon: LucideIcons.calendar,
                      iconColor: AppTheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Happening Now Session countdown card
              GestureDetector(
                onTap: () => context.go('/owner/happening-now'),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1012),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: liveSession == null
                      ? const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(LucideIcons.coffee, color: Colors.white70, size: 16),
                                SizedBox(width: 8),
                                Text(
                                  "No active session",
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ],
                            ),
                            SizedBox(height: 6),
                            Text(
                              "No confirmed appointments left on today's calendar.",
                              style: TextStyle(fontSize: 11, color: Colors.white38),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: sessionState == SessionState.overrun
                                        ? AppTheme.danger
                                        : AppTheme.primary,
                                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                  ),
                                  child: Text(
                                    _cardBadge(sessionState),
                                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: sessionState == SessionState.overrun
                                        ? AppTheme.danger
                                        : AppTheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              liveSession.customerName,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "${liveSession.serviceName} • Stylist: ${liveSession.stylist}",
                              style: const TextStyle(fontSize: 11, color: Colors.white70),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                if (showCountdown) ...[
                                  Text(
                                    sessionState == SessionState.overrun
                                        ? "+${parlour.getTimerString()}"
                                        : parlour.getTimerString(),
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: sessionState == SessionState.overrun
                                          ? const Color(0xFFFF8A9B)
                                          : Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Expanded(
                                  child: Text(
                                    _cardCaption(sessionState, parlour.timeRangeFor(liveSession).split(' - ').first),
                                    style: const TextStyle(fontSize: 10, color: Colors.white38),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                // Start the session without leaving the dashboard.
                                if (!isSessionRunning)
                                  ElevatedButton(
                                    onPressed: () => parlour.startSession(liveSession.id),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primary,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.play_arrow_rounded, size: 16),
                                        SizedBox(width: 4),
                                        Text("START", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Pending Requests previews
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Pending Requests (${pendingList.length})",
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.darkText),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/owner/requests'),
                    child: const Text(
                      "View all",
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (pendingList.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: AppTheme.border, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    "No pending requests.",
                    style: TextStyle(fontSize: 12, color: AppTheme.lightText),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: pendingList.take(2).length,
                  itemBuilder: (context, index) {
                    final r = pendingList[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  r.customerName,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  "Rs. ${r.price.toInt()}",
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "${r.serviceName} • ${r.date} at ${r.time}",
                              style: const TextStyle(fontSize: 11, color: AppTheme.lightText),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => parlour.declineBooking(r.id),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: AppTheme.border),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                      ),
                                    ),
                                    child: const Text("Decline", style: TextStyle(fontSize: 11, color: AppTheme.danger)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => parlour.approveBooking(r.id),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primary,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                      ),
                                    ),
                                    child: const Text("Approve", style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const OwnerBottomNav(activeTab: 'dashboard'),
    );
  }

  /// Badge on the live-session card.
  String _cardBadge(SessionState state) {
    switch (state) {
      case SessionState.running:
        return "Happening Now";
      case SessionState.overrun:
        return "Running Over";
      case SessionState.awaitingStart:
        return "Ready to Start";
      default:
        return "Up Next";
    }
  }

  /// Explains what the countdown on the card refers to.
  String _cardCaption(SessionState state, String startLabel) {
    switch (state) {
      case SessionState.running:
        return "remaining";
      case SessionState.overrun:
        return "over scheduled time";
      case SessionState.awaitingStart:
        return "due at $startLabel — not started";
      case SessionState.upNext:
        return "until $startLabel";
      default:
        return "scheduled at $startLabel";
    }
  }

  /// Compact circular action for the header (bell / log out).
  Widget _buildHeaderIcon({
    required IconData icon,
    required VoidCallback onTap,
    Color color = AppTheme.darkText,
    int badgeCount = 0,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFFECEF), width: 1.5),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          if (badgeCount > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                child: Text(
                  badgeCount.toString(),
                  style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String desc,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.lightText),
              ),
              Icon(icon, color: iconColor, size: 16),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkText),
          ),
          const SizedBox(height: 2),
          Text(
            desc,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: iconColor == AppTheme.success ? AppTheme.success : AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
