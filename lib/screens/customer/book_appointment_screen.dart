import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/parlour_provider.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/common.dart';
import '../../models/service.dart';

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  static const _monthNames = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
  ];

  /// The month shown in the picker; starts on the current month.
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    final parlour = Provider.of<ParlourProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final selectedSvcs = parlour.tempSelectedServiceIds.isNotEmpty
        ? parlour.tempSelectedServiceIds.map((id) => parlour.services.firstWhere((s) => s.id == id)).toList()
        : [parlour.services[0]]; // fallback

    final activeServiceId = parlour.activeServiceId ?? selectedSvcs.first.id;
    final activeSvc = parlour.services.firstWhere((s) => s.id == activeServiceId, orElse: () => selectedSvcs.first);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Real calendar geometry: leading blanks for the first weekday (Sun-first
    // header), then the actual number of days in the visible month.
    final daysInMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final leadingBlanks = DateTime(_visibleMonth.year, _visibleMonth.month, 1).weekday % 7;
    final totalCells = leadingBlanks + daysInMonth;
    // Don't let customers page back into months that are entirely in the past.
    final canGoBack = _visibleMonth.isAfter(DateTime(today.year, today.month));

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9FA), // Soft premium pink background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.darkText, size: 20),
          onPressed: () => context.go('/customer/services'),
        ),
        title: const Text(
          "Book Appointment",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.darkText,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Divider/Thin line
              const Divider(color: Color(0xFFFFECEF), thickness: 1.5, height: 1),
              const SizedBox(height: 20),

              // What's the occasion ?
              const Text(
                "What's the occasion ?",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkText, fontFamily: 'Poppins'),
              ),
              const Text(
                "Help us tailor your experience",
                style: TextStyle(fontSize: 12, color: AppTheme.lightText),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildOccasionPill(parlour, "selfcare", "selfcare", LucideIcons.flower2),
                  const SizedBox(width: 8),
                  _buildOccasionPill(parlour, "Bridal", "bridal", LucideIcons.heart),
                  const SizedBox(width: 8),
                  _buildOccasionPill(parlour, "Party", "party", LucideIcons.sparkles),
                ],
              ),
              const SizedBox(height: 24),

              // Selected Services
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Selected Services",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkText, fontFamily: 'Poppins'),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/customer/services'),
                    child: const Text(
                      "See All",
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 110,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: selectedSvcs.length,
                  itemBuilder: (context, index) {
                    final svc = selectedSvcs[index];
                    final isSelected = svc.id == activeSvc.id;
                    return GestureDetector(
                      onTap: () => parlour.setActiveServiceId(svc.id),
                      child: _buildServiceCard(svc, isSelected, index),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Pick a date
              const Text(
                "Pick a date",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkText, fontFamily: 'Poppins'),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFECEF), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios_new,
                            size: 16,
                            color: canGoBack ? AppTheme.darkText : Colors.black12,
                          ),
                          onPressed: canGoBack
                              ? () => setState(() {
                                    _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1);
                                  })
                              : null,
                        ),
                        Text(
                          "${_monthNames[_visibleMonth.month - 1]} ${_visibleMonth.year}",
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.darkText, fontFamily: 'Poppins'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.darkText),
                          onPressed: () => setState(() {
                            _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1);
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Weekdays header Row
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text("S", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.darkText)),
                        Text("M", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.darkText)),
                        Text("T", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.darkText)),
                        Text("W", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.darkText)),
                        Text("T", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.darkText)),
                        Text("F", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.darkText)),
                        Text("S", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.darkText)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Grid of cells
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        mainAxisSpacing: 4,
                        crossAxisSpacing: 4,
                        childAspectRatio: 1.2,
                      ),
                      itemCount: totalCells,
                      itemBuilder: (context, index) {
                        if (index < leadingBlanks) {
                          return const SizedBox.shrink();
                        }
                        final day = index - leadingBlanks + 1;
                        final cellDate = DateTime(_visibleMonth.year, _visibleMonth.month, day);
                        final dateStr = ParlourProvider.fmtDate(cellDate);
                        final isSelected = parlour.tempDate == dateStr;
                        final isToday = cellDate == today;
                        final isPast = cellDate.isBefore(today);

                        return GestureDetector(
                          onTap: isPast ? null : () => parlour.setTempDate(dateStr),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primary : Colors.transparent,
                              shape: BoxShape.circle,
                              border: isToday && !isSelected
                                  ? Border.all(color: AppTheme.primary, width: 1.5)
                                  : null,
                            ),
                            child: Text(
                              day.toString(),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : isPast
                                        ? Colors.black26
                                        : AppTheme.darkText,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Available time
              const Text(
                "Available time",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkText, fontFamily: 'Poppins'),
              ),
              const SizedBox(height: 12),
              _buildTimeSection(parlour, "MORNING", const [
                "9:00 am", "9:30 am", "10:00 am", "10:30 am", "11:00 am", "11:30 am",
              ]),
              const SizedBox(height: 16),
              _buildTimeSection(parlour, "AFTERNOON", const [
                "12:00 pm", "12:30 pm", "1:00 pm", "1:30 pm", "2:00 pm",
                "2:30 pm", "3:00 pm", "3:30 pm", "4:00 pm", "4:30 pm",
              ]),
              const SizedBox(height: 16),
              _buildTimeSection(parlour, "EVENING", const [
                "5:00 pm", "5:30 pm", "6:00 pm", "6:30 pm", "7:00 pm", "7:30 pm",
              ]),
              const SizedBox(height: 32),
            ],
          ),
        ),
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
                Text(
                  "Total (${selectedSvcs.length} item${selectedSvcs.length > 1 ? 's' : ''})",
                  style: const TextStyle(fontSize: 11, color: AppTheme.lightText, fontWeight: FontWeight.w500),
                ),
                Text(
                  "Rs. ${selectedSvcs.fold<double>(0.0, (sum, s) => sum + s.price).toInt()}",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkText, fontFamily: 'Poppins'),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () async {
                if (parlour.reschedulingBookingId != null) {
                  await parlour.confirmReschedule();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Appointment rescheduled successfully!"),
                        backgroundColor: AppTheme.primary,
                      ),
                    );
                    context.go('/customer/appointments');
                  }
                } else {
                  context.go('/customer/loyalty');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    parlour.reschedulingBookingId != null ? "Confirm Reschedule" : "Continue",
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    parlour.reschedulingBookingId != null ? Icons.check : Icons.arrow_forward,
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOccasionPill(ParlourProvider parlour, String label, String key, IconData icon) {
    final isActive = parlour.tempOccasion == key;
    return GestureDetector(
      onTap: () => parlour.setTempOccasion(key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppTheme.primary : const Color(0xFFFFECEF),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? Colors.white : AppTheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : AppTheme.lightText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(Service svc, bool isSelected, int index) {
    // Bright pink for selected/active service, light pink for others
    final activeColor = const Color(0xFFFF4B72); // Bright pink
    final inactiveColor = const Color(0xFFFFF0F2); // Light pink
    
    IconData iconData = LucideIcons.scissors;
    if (svc.category.toLowerCase().contains('nail')) {
      iconData = LucideIcons.gem;
    } else if (svc.category.toLowerCase().contains('skin') || svc.name.toLowerCase().contains('facial')) {
      iconData = LucideIcons.sparkles;
    } else if (svc.category.toLowerCase().contains('makeup')) {
      iconData = LucideIcons.palette;
    }

    final cardBgColor = isSelected ? activeColor : inactiveColor;
    final textColor = isSelected ? Colors.white : activeColor;
    final subtextColor = isSelected ? Colors.white70 : activeColor.withOpacity(0.7);
    final iconColor = isSelected ? Colors.white : activeColor;
    final iconBgColor = isSelected ? Colors.white.withOpacity(0.2) : activeColor.withOpacity(0.1);

    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(20),
        border: isSelected ? Border.all(color: Colors.white, width: 2) : Border.all(color: const Color(0xFFFFECEF), width: 1),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: activeColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, color: iconColor, size: 14),
          ),
          const Spacer(),
          Text(
            svc.name.split(' ').first,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor, fontFamily: 'Poppins'),
          ),
          Text(
            "${svc.duration} mins",
            style: TextStyle(fontSize: 9, color: subtextColor, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            "Rs. ${svc.price.toInt()}",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSection(ParlourProvider parlour, String label, List<String> times) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.lightText, letterSpacing: 0.5),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: times
              .map((t) => _buildTimePill(
                    parlour,
                    t,
                    isBooked: parlour.isSlotTaken(parlour.tempDate, t),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildTimePill(ParlourProvider parlour, String time, {bool isBooked = false}) {
    final isSelected = parlour.tempTime == time;
    return GestureDetector(
      onTap: isBooked ? null : () => parlour.setTempTime(time),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primary : const Color(0xFFFFECEF),
            width: 1.5,
          ),
        ),
        child: Text(
          time,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isBooked 
                ? Colors.black26 
                : (isSelected ? Colors.white : AppTheme.darkText),
            decoration: isBooked ? TextDecoration.lineThrough : null,
          ),
        ),
      ),
    );
  }
}
