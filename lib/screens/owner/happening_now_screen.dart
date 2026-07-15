import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme.dart';
import '../../providers/parlour_provider.dart';
import '../../widgets/bottom_nav.dart';

class OwnerHappeningNowScreen extends StatelessWidget {
  const OwnerHappeningNowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final parlour = Provider.of<ParlourProvider>(context);
    final session = parlour.liveSession;

    final state = session != null ? parlour.stateFor(session) : SessionState.done;
    final isRunning = state == SessionState.running || state == SessionState.overrun;

    // While running, count down the service. Before it starts, count down to
    // the scheduled time and then hold at 00:00 — the service clock must only
    // move once the owner presses Start.
    final int shownSeconds = session == null
        ? 0
        : isRunning
            ? parlour.remainingSecondsFor(session)
            : parlour.secondsUntilStartForDisplay(session);
    final int minutes = shownSeconds.abs() ~/ 60;
    final int seconds = shownSeconds.abs() % 60;

    final delayMinutes = (session?.liveStatus?['delayMinutes'] as int?) ?? 0;
    final startLabel = session != null
        ? parlour.timeRangeFor(session).split(' - ').first
        : "";

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9FA), // Premium soft pink background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.darkText, size: 20),
          onPressed: () => context.go('/owner/dashboard'),
        ),
        title: Column(
          children: [
            const Text(
              "Happening Now",
              style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkText),
            ),
            Text(
              _todayLabel(),
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primary),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.calendar, color: AppTheme.darkText, size: 20),
            onPressed: () => context.go('/owner/schedule'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: session == null
                  ? _buildEmptyState()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Divider(color: Color(0xFFFFECEF), thickness: 1.5, height: 1),
                        const SizedBox(height: 20),

                        // Service in progress header row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _stateHeadline(state),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary, letterSpacing: 0.5),
                            ),
                            if (state == SessionState.overrun)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFEBEE),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFFFCDD2)),
                                ),
                                child: Text(
                                  "+${parlour.formatClock(shownSeconds)} OVER",
                                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.danger),
                                ),
                              )
                            else if (delayMinutes > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF0F2),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFFFECEF)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "+$delayMinutes Mins Over",
                                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.primary),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Duration badge
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFFFE0B2), width: 1.5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(LucideIcons.clock, color: Color(0xFFE65100), size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  "${session.duration} MIN SERVICE",
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFE65100)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Service details
                        Center(
                          child: Text(
                            session.serviceName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.darkText, fontFamily: 'Poppins'),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Center(
                          child: Text(
                            "with ${session.customerName}",
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Circular timer graphic containing pink text boxes
                        Center(
                          child: Container(
                            width: 220,
                            height: 220,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: state == SessionState.overrun
                                    ? const Color(0xFFFFCDD2)
                                    : const Color(0xFFFFD4DA),
                                width: 4,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _timerCaption(state),
                                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.lightText, letterSpacing: 0.5),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Minutes Box
                                    _buildTimeBox(minutes.toString().padLeft(2, '0'), "MINUTES", state),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                      child: Text(
                                        ":",
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: state == SessionState.overrun ? AppTheme.danger : AppTheme.primary,
                                        ),
                                      ),
                                    ),
                                    // Seconds Box
                                    _buildTimeBox(seconds.toString().padLeft(2, '0'), "SECONDS", state),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  isRunning ? "Scheduled for $startLabel" : "Starts at $startLabel",
                                  style: const TextStyle(fontSize: 11, color: AppTheme.lightText, fontWeight: FontWeight.w600, fontStyle: FontStyle.italic),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Controls: Start this service, or manage it once running.
                        if (!isRunning)
                          SizedBox(
                            height: 54,
                            child: ElevatedButton(
                              onPressed: () => parlour.startSession(session.id),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.play_arrow_rounded, size: 22),
                                  const SizedBox(width: 8),
                                  Text(
                                    "START ${session.serviceName.toUpperCase()}",
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                child: _buildControlCard(
                                  onTap: () {
                                    parlour.finishSession(session.id);
                                    context.go('/owner/dashboard');
                                  },
                                  topLabel: "FINISH",
                                  subLabel: "COMPLETE",
                                  isCheck: true,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildControlCard(
                                  onTap: () => parlour.addTimerMinutes(5),
                                  topLabel: "+5",
                                  subLabel: "ADD TIME",
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildControlCard(
                                  onTap: () => parlour.addTimerMinutes(10),
                                  topLabel: "+10",
                                  subLabel: "ADD TIME",
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 32),

                        // UPCOMING SCHEDULE Header
                        const Text(
                          "UPCOMING SCHEDULE",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 12),

                        // Upcoming schedule cards list (real bookings after the live session)
                        if (parlour.upcomingToday.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              "Nothing else on the calendar today.",
                              style: TextStyle(fontSize: 12, color: AppTheme.lightText, fontWeight: FontWeight.w600),
                            ),
                          )
                        else
                          ...parlour.upcomingToday.map((b) {
                            final st = parlour.stateFor(b);
                            // Each upcoming service gets its own live countdown
                            // once it's inside the 5-minute pre-start window.
                            final countdown = st == SessionState.upNext
                                ? "in ${parlour.formatClock(parlour.secondsUntilStartFor(b))}"
                                : null;
                            return _buildUpcomingScheduleCard(
                              time: parlour.timeRangeFor(b).split(' - ').first,
                              serviceName: b.serviceName,
                              clientName: b.customerName,
                              statusText: b.status == 'Pending'
                                  ? "Awaiting approval"
                                  : countdown ?? (st == SessionState.awaitingStart ? "Due now" : null),
                              highlight: countdown != null || st == SessionState.awaitingStart,
                            );
                          }),
                        const SizedBox(height: 20),
                      ],
                    ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const OwnerBottomNav(activeTab: 'dashboard'),
    );
  }

  String _todayLabel() {
    const weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    final now = DateTime.now();
    return "${weekdays[now.weekday - 1]} ${months[now.month - 1]} ${now.day.toString().padLeft(2, '0')}";
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(color: Color(0xFFFFF0F2), shape: BoxShape.circle),
            child: const Icon(LucideIcons.coffee, color: AppTheme.primary, size: 36),
          ),
          const SizedBox(height: 20),
          const Text(
            "No active session",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkText, fontFamily: 'Poppins'),
          ),
          const SizedBox(height: 8),
          const Text(
            "There are no confirmed appointments left\non today's calendar.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppTheme.lightText, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  /// Headline above the timer, driven purely by the session's state.
  String _stateHeadline(SessionState state) {
    switch (state) {
      case SessionState.running:
        return "SERVICE IN PROGRESS";
      case SessionState.overrun:
        return "RUNNING OVER";
      case SessionState.upNext:
        return "UP NEXT";
      case SessionState.awaitingStart:
        return "READY TO START";
      default:
        return "NEXT UP TODAY";
    }
  }

  /// Small caption inside the ring explaining what the digits mean.
  String _timerCaption(SessionState state) {
    switch (state) {
      case SessionState.running:
        return "TIME REMAINING";
      case SessionState.overrun:
        return "OVER BY";
      case SessionState.awaitingStart:
        return "DUE NOW";
      default:
        return "STARTS IN";
    }
  }

  Widget _buildTimeBox(String val, String lbl, SessionState state) {
    final isOver = state == SessionState.overrun;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isOver ? const Color(0xFFFFEBEE) : const Color(0xFFFFF0F2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isOver ? const Color(0xFFFFCDD2) : const Color(0xFFFFECEF)),
          ),
          child: Text(
            val,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isOver ? AppTheme.danger : AppTheme.darkText,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          lbl,
          style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppTheme.lightText),
        ),
      ],
    );
  }

  Widget _buildControlCard({
    required VoidCallback onTap,
    required String topLabel,
    required String subLabel,
    bool isCheck = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFECEF), width: 1.5),
        ),
        child: Column(
          children: [
            isCheck
                ? const Icon(Icons.check_circle, color: AppTheme.primary, size: 20)
                : Text(
                    topLabel,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primary, fontFamily: 'Poppins'),
                  ),
            const SizedBox(height: 4),
            Text(
              subLabel,
              style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppTheme.lightText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingScheduleCard({
    required String time,
    required String serviceName,
    required String clientName,
    String? statusText,
    bool highlight = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight ? AppTheme.primary : const Color(0xFFFFECEF),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Time column
          SizedBox(
            width: 68,
            child: Text(
              time,
              style: const TextStyle(fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
            ),
          ),
          const SizedBox(width: 14),
          // Vertical separator
          Container(width: 1.5, height: 32, color: Colors.black12),
          const SizedBox(width: 14),
          // Service/Client details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  serviceName,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.darkText),
                ),
                Text(
                  clientName,
                  style: const TextStyle(fontSize: 11, color: AppTheme.lightText, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          if (statusText != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                statusText,
                style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppTheme.primary),
              ),
            ),
        ],
      ),
    );
  }
}
