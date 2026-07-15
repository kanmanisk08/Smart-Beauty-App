import 'dart:async';
import 'package:flutter/material.dart';
import '../models/service.dart';
import '../models/customer.dart';
import '../models/booking.dart';
import '../services/database.dart';

/// Where a single appointment sits in its lifecycle. Derived from the wall
/// clock plus whether the owner has pressed Start — never stored.
enum SessionState {
  /// More than [ParlourProvider.upNextWindow] away — shown as a plain time.
  scheduled,

  /// Inside the pre-start window: the "starts in mm:ss" countdown is live.
  upNext,

  /// Due (or overdue) but the owner hasn't pressed Start yet.
  awaitingStart,

  /// Started, still within its planned duration.
  running,

  /// Started and past its planned duration — counting up.
  overrun,

  /// Completed.
  done,
}

class ParlourProvider extends ChangeNotifier {
  List<Service> _services = [];
  List<Customer> _customers = [];
  List<Booking> _bookings = [];

  /// Repaint ticker. The session countdown is *derived* from wall-clock time
  /// (see [remainingSecondsFor]), so this only needs to nudge the UI each second.
  Timer? _timer;

  /// A session's "Up Next" countdown becomes live this long before its start.
  static const Duration upNextWindow = Duration(minutes: 5);

  /// How many appointment slots the parlour can realistically serve in one day.
  /// Used to turn today's booked count into a capacity percentage.
  static const int dailyCapacity = 8;

  // Temporary booking funnel state
  List<String> _tempSelectedServiceIds = [];
  Map<String, String> _tempSelectedDates = {};
  Map<String, String> _tempSelectedTimes = {};
  String? _activeServiceId;
  String _tempOccasion = 'selfcare';
  double _tempLoyaltyDiscount = 0.0;
  int _tempPointsApplied = 0;
  String _tempPaymentMethod = 'Credit Card **** 4242';
  String? _reschedulingBookingId;

  // Getters
  List<Service> get services => _services;
  List<Customer> get customers => _customers;
  List<Booking> get bookings => _bookings;

  /// Convenience accessors for the session shown on the dashboard/Happening Now.
  String get timerClient => liveSession?.customerName ?? "";
  String get timerService => liveSession?.serviceName ?? "";
  bool get isTimerActive {
    final b = liveSession;
    return b != null && b.startedAt != null;
  }

  List<String> get tempSelectedServiceIds => _tempSelectedServiceIds;
  Map<String, String> get tempSelectedDates => _tempSelectedDates;
  Map<String, String> get tempSelectedTimes => _tempSelectedTimes;
  String? get activeServiceId => _activeServiceId;
  String? get tempServiceId => _tempSelectedServiceIds.isNotEmpty ? _tempSelectedServiceIds.first : null;
  String get tempOccasion => _tempOccasion;

  /// "YYYY-MM-DD" for a date — the storage format used by every booking.
  static String fmtDate(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  /// New bookings default to today, so an appointment made now lands on today's
  /// schedule rather than a fixed calendar date.
  String get defaultDate => fmtDate(DateTime.now());
  static const String defaultTime = '11:00 am';

  String get tempDate => _activeServiceId != null ? (_tempSelectedDates[_activeServiceId!] ?? defaultDate) : defaultDate;
  String get tempTime => _activeServiceId != null ? (_tempSelectedTimes[_activeServiceId!] ?? defaultTime) : defaultTime;
  double get tempLoyaltyDiscount => _tempLoyaltyDiscount;
  int get tempPointsApplied => _tempPointsApplied;
  String get tempPaymentMethod => _tempPaymentMethod;
  String? get reschedulingBookingId => _reschedulingBookingId;

  // ─── Real-data derivations (all computed from live Firestore bookings) ────

  /// Parses a booking's date ("YYYY-MM-DD") + start time ("hh:mm AM/PM", or a
  /// legacy "hh:mm AM - hh:mm PM" range) into a concrete DateTime. Returns null
  /// if the strings can't be understood.
  DateTime? bookingStart(Booking b) {
    try {
      final dateParts = b.date.split('-');
      if (dateParts.length != 3) return null;
      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);

      // Take the part before any range separator, e.g. "10:00 AM - 11:30 AM".
      var timeStr = b.time.split('-').first.trim();
      final match = RegExp(r'(\d{1,2}):(\d{2})\s*([AaPp][Mm])?').firstMatch(timeStr);
      if (match == null) return DateTime(year, month, day);

      var hour = int.parse(match.group(1)!);
      final minute = int.parse(match.group(2)!);
      final meridiem = match.group(3)?.toUpperCase();
      if (meridiem == 'PM' && hour != 12) hour += 12;
      if (meridiem == 'AM' && hour == 12) hour = 0;

      return DateTime(year, month, day, hour, minute);
    } catch (_) {
      return null;
    }
  }

  /// Parses a clock string ("1:00 pm", "10:00 AM", "12:30 PM") to (hour24, minute).
  (int, int)? parseClock(String raw) {
    final match = RegExp(r'(\d{1,2}):(\d{2})\s*([AaPp][Mm])?').firstMatch(raw.trim());
    if (match == null) return null;
    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final meridiem = match.group(3)?.toUpperCase();
    if (meridiem == 'PM' && hour != 12) hour += 12;
    if (meridiem == 'AM' && hour == 12) hour = 0;
    return (hour, minute);
  }

  /// True when a slot on [date] at [timeLabel] is already taken by a
  /// confirmed or pending appointment.
  bool isSlotTaken(String date, String timeLabel) {
    final target = parseClock(timeLabel);
    if (target == null) return false;
    return _bookings.any((b) {
      if (b.date != date) return false;
      if (b.status != 'Confirmed' && b.status != 'Pending') return false;
      final start = bookingStart(b);
      return start != null && start.hour == target.$1 && start.minute == target.$2;
    });
  }

  DateTime? bookingEnd(Booking b) {
    final start = bookingStart(b);
    if (start == null) return null;
    return start.add(Duration(minutes: b.duration));
  }

  /// "09:30 AM - 09:50 AM" derived from start time + duration.
  String timeRangeFor(Booking b) {
    final start = bookingStart(b);
    final end = bookingEnd(b);
    if (start == null || end == null) return b.time;
    return "${_fmtClock(start)} - ${_fmtClock(end)}";
  }

  String _fmtClock(DateTime d) {
    final h = d.hour == 0 ? 12 : (d.hour > 12 ? d.hour - 12 : d.hour);
    final m = d.minute.toString().padLeft(2, '0');
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    return "${h.toString().padLeft(2, '0')}:$m $ampm";
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // Status buckets
  List<Booking> get pendingBookings => _bookings.where((b) => b.status == 'Pending').toList();
  List<Booking> get confirmedBookings => _bookings.where((b) => b.status == 'Confirmed').toList();
  List<Booking> get historyBookings => _bookings.where((b) => b.status == 'History').toList();

  /// Bookings scheduled for today (any status), sorted by start time.
  List<Booking> get todaysBookings {
    final now = DateTime.now();
    final list = _bookings.where((b) {
      final start = bookingStart(b);
      return start != null && _isSameDay(start, now);
    }).toList();
    list.sort((a, b) => (bookingStart(a) ?? now).compareTo(bookingStart(b) ?? now));
    return list;
  }

  /// Slots actually occupied today = confirmed + already-completed appointments.
  int get bookedSlotsToday =>
      todaysBookings.where((b) => b.status == 'Confirmed' || b.status == 'History').length;

  int get bookedSlotsPercent =>
      ((bookedSlotsToday / dailyCapacity) * 100).round().clamp(0, 100);

  double _revenueForMonth(DateTime month) {
    return _bookings.where((b) {
      if (b.status != 'History' && b.status != 'Confirmed') return false;
      final start = bookingStart(b);
      return start != null && start.year == month.year && start.month == month.month;
    }).fold<double>(0, (sum, b) => sum + b.totalPaid);
  }

  /// Confirmed + completed revenue booked in the current calendar month.
  double get monthlyRevenue => _revenueForMonth(DateTime.now());

  double get lastMonthRevenue {
    final now = DateTime.now();
    return _revenueForMonth(DateTime(now.year, now.month - 1, 1));
  }

  /// Percentage change vs last month. Null when there's no prior-month baseline.
  double? get revenueChangePercent {
    final last = lastMonthRevenue;
    if (last <= 0) return null;
    return ((monthlyRevenue - last) / last) * 100;
  }

  /// The session the owner is actually being asked to act on: whatever is
  /// running right now, else the next confirmed appointment left today.
  /// Null when there is nothing confirmed on today's calendar.
  Booking? get liveSession {
    final todaysConfirmed = todaysBookings.where((b) => b.status == 'Confirmed').toList();
    if (todaysConfirmed.isEmpty) return null;

    // A session the owner has actually started always wins.
    final running = todaysConfirmed.where((b) => b.startedAt != null);
    if (running.isNotEmpty) return running.first;

    // Otherwise the earliest one not yet done (todaysBookings is start-sorted).
    return todaysConfirmed.first;
  }

  /// Only true once the owner has pressed Start — never from the clock alone.
  bool get isLiveSessionInProgress {
    final b = liveSession;
    return b != null && b.startedAt != null;
  }

  DateTime? startedAtOf(Booking b) =>
      b.startedAt == null ? null : DateTime.tryParse(b.startedAt!);

  /// Total seconds the session is allowed to run: booked duration + any
  /// minutes the owner added mid-session.
  int plannedSecondsFor(Booking b) => (b.duration + b.addedMinutes) * 60;

  /// Seconds left on a *running* session. Goes negative once it overruns.
  /// Falls back to the full planned time before it has been started.
  int remainingSecondsFor(Booking b) {
    final started = startedAtOf(b);
    if (started == null) return plannedSecondsFor(b);
    return plannedSecondsFor(b) - DateTime.now().difference(started).inSeconds;
  }

  /// Seconds until a not-yet-started session is due to begin. Negative when
  /// the scheduled time has already passed.
  int secondsUntilStartFor(Booking b) {
    final start = bookingStart(b);
    if (start == null) return 0;
    return start.difference(DateTime.now()).inSeconds;
  }

  SessionState stateFor(Booking b) {
    if (b.status == 'History') return SessionState.done;
    if (b.startedAt != null) {
      return remainingSecondsFor(b) > 0 ? SessionState.running : SessionState.overrun;
    }
    final until = secondsUntilStartFor(b);
    if (until <= 0) return SessionState.awaitingStart;
    if (until <= upNextWindow.inSeconds) return SessionState.upNext;
    return SessionState.scheduled;
  }

  /// mm:ss for any second count (absolute value, so overruns read "+02:15").
  String formatClock(int seconds) {
    final s = seconds.abs();
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return "$m:$sec";
  }

  /// Sessions already announced as "starting soon", so the owner gets nudged
  /// once per appointment rather than on every one-second tick.
  final Set<String> _announcedUpNext = {};

  /// A confirmed session that has just crossed into its [upNextWindow] and
  /// hasn't been announced yet. Null when there's nothing to announce.
  Booking? get upNextAlert {
    for (final b in todaysBookings) {
      if (b.status != 'Confirmed' || b.startedAt != null) continue;
      if (_announcedUpNext.contains(b.id)) continue;
      if (stateFor(b) == SessionState.upNext) return b;
    }
    return null;
  }

  /// Records that the reminder for [id] has been shown. Intentionally does not
  /// call notifyListeners: the per-second ticker already drives the next
  /// rebuild, and notifying from a build/frame callback would loop.
  void markUpNextAnnounced(String id) => _announcedUpNext.add(id);

  // ── Session controls ──────────────────────────────────────────────────────
  /// Starts the timer for one specific booking. Only one session runs at a
  /// time, so any other running session today is closed out first.
  Future<void> startSession(String bookingId) async {
    for (final b in todaysBookings) {
      if (b.id != bookingId && b.startedAt != null && b.status == 'Confirmed') {
        b.status = 'History';
        b.startedAt = null;
        await LocalDatabase.saveBooking(b);
      }
    }
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index == -1) return;
    _bookings[index].startedAt = DateTime.now().toIso8601String();
    _bookings[index].addedMinutes = 0;
    await LocalDatabase.saveBooking(_bookings[index]);
    notifyListeners();
  }

  /// Ends a session and files it under History.
  Future<void> finishSession(String bookingId) async {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index == -1) return;
    _bookings[index].status = 'History';
    _bookings[index].startedAt = null;
    _bookings[index].liveStatus = null;
    await LocalDatabase.saveBooking(_bookings[index]);
    notifyListeners();
  }

  /// Remaining confirmed/pending appointments today after the live session.
  List<Booking> get upcomingToday {
    final live = liveSession;
    return todaysBookings.where((b) {
      if (b.status != 'Confirmed' && b.status != 'Pending') return false;
      return b.id != live?.id;
    }).toList();
  }

  // ── Per-customer CRM derivations ──────────────────────────────────────────
  List<Booking> bookingsForCustomer(String name) =>
      _bookings.where((b) => b.customerName == name).toList();

  /// The customer's most recent past appointment (for "last visit").
  Booking? lastVisitFor(String name) {
    final now = DateTime.now();
    final past = bookingsForCustomer(name).where((b) {
      final start = bookingStart(b);
      return start != null && start.isBefore(now);
    }).toList();
    if (past.isEmpty) return null;
    past.sort((a, b) => (bookingStart(b) ?? now).compareTo(bookingStart(a) ?? now));
    return past.first;
  }

  /// The service this customer books most often, or '' if they have no bookings.
  String preferredServiceFor(String name) {
    final counts = <String, int>{};
    for (final b in bookingsForCustomer(name)) {
      counts[b.serviceName] = (counts[b.serviceName] ?? 0) + 1;
    }
    if (counts.isEmpty) return '';
    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  int visitsFor(String name) =>
      bookingsForCustomer(name).where((b) => b.status == 'History').length;

  double totalSpentFor(String name) => bookingsForCustomer(name)
      .where((b) => b.status == 'History' || b.status == 'Confirmed')
      .fold<double>(0, (sum, b) => sum + b.totalPaid);

  int cancellationsFor(String name) =>
      bookingsForCustomer(name).where((b) => b.status == 'Declined').length;

  // ── Services catalogue derivations ────────────────────────────────────────
  int get servicesCompleted => historyBookings.length;

  double get averageServicePrice {
    if (_services.isEmpty) return 0;
    final total = _services.fold<double>(0, (sum, s) => sum + s.price);
    return total / _services.length;
  }

  StreamSubscription? _servicesSub;
  StreamSubscription? _customersSub;
  StreamSubscription? _bookingsSub;

  // Initialize data
  Future<void> initializeData() async {
    await LocalDatabase.initDatabase();
    
    _servicesSub = LocalDatabase.streamServices().listen((list) {
      _services = list;
      notifyListeners();
    });

    _customersSub = LocalDatabase.streamCustomers().listen((list) {
      _customers = list;
      notifyListeners();
    });

    _bookingsSub = LocalDatabase.streamBookings().listen((list) {
      _bookings = list;
      notifyListeners();
    });

    startTimerInterval();
  }

  Future<void> refreshData() async {
    // Kept for backward compatibility, streams handle updates
    notifyListeners();
  }

  Future<void> resetDatabase() async {
    await LocalDatabase.resetAndReSeedDatabase();
  }

  // Temporary booking setters
  void toggleTempServiceId(String id) {
    if (_tempSelectedServiceIds.contains(id)) {
      _tempSelectedServiceIds.remove(id);
      _tempSelectedDates.remove(id);
      _tempSelectedTimes.remove(id);
      if (_activeServiceId == id) {
        _activeServiceId = _tempSelectedServiceIds.isNotEmpty ? _tempSelectedServiceIds.first : null;
      }
    } else {
      _tempSelectedServiceIds.add(id);
      _tempSelectedDates[id] = defaultDate;
      _tempSelectedTimes[id] = defaultTime;
      _activeServiceId = id;
    }
    _tempLoyaltyDiscount = 0.0;
    _tempPointsApplied = 0;
    notifyListeners();
  }

  void setTempServiceId(String? id) {
    _tempSelectedServiceIds.clear();
    _tempSelectedDates.clear();
    _tempSelectedTimes.clear();
    if (id != null) {
      _tempSelectedServiceIds.add(id);
      _tempSelectedDates[id] = defaultDate;
      _tempSelectedTimes[id] = defaultTime;
      _activeServiceId = id;
    } else {
      _activeServiceId = null;
    }
    _tempLoyaltyDiscount = 0.0;
    _tempPointsApplied = 0;
    notifyListeners();
  }

  void setActiveServiceId(String id) {
    if (_tempSelectedServiceIds.contains(id)) {
      _activeServiceId = id;
      notifyListeners();
    }
  }

  void startRescheduling(String bookingId) {
    _reschedulingBookingId = bookingId;
    final booking = _bookings.firstWhere((b) => b.id == bookingId);
    final svc = _services.firstWhere(
      (s) => s.name == booking.serviceName,
      orElse: () => _services.first,
    );
    _tempSelectedServiceIds = [svc.id];
    _tempSelectedDates[svc.id] = booking.date;
    _tempSelectedTimes[svc.id] = booking.time;
    _activeServiceId = svc.id;
    notifyListeners();
  }

  Future<void> confirmReschedule() async {
    if (_reschedulingBookingId != null) {
      final index = _bookings.indexWhere((b) => b.id == _reschedulingBookingId);
      if (index != -1) {
        final svcId = _tempSelectedServiceIds.first;
        final newDate = _tempSelectedDates[svcId] ?? defaultDate;
        final newTime = _tempSelectedTimes[svcId] ?? defaultTime;
        _bookings[index].date = newDate;
        _bookings[index].time = newTime;
        await LocalDatabase.saveBooking(_bookings[index]);
      }
      _reschedulingBookingId = null;
      _tempSelectedServiceIds.clear();
      _tempSelectedDates.clear();
      _tempSelectedTimes.clear();
      _activeServiceId = null;
    }
    await refreshData();
  }

  void setTempOccasion(String occasion) {
    _tempOccasion = occasion;
    notifyListeners();
  }

  void setTempDate(String date) {
    if (_activeServiceId != null) {
      _tempSelectedDates[_activeServiceId!] = date;
    }
    notifyListeners();
  }

  void setTempTime(String time) {
    if (_activeServiceId != null) {
      _tempSelectedTimes[_activeServiceId!] = time;
    }
    notifyListeners();
  }

  void setTempPaymentMethod(String method) {
    _tempPaymentMethod = method;
    notifyListeners();
  }

  void applyPointsReward(int points, double discount) {
    _tempPointsApplied = points;
    _tempLoyaltyDiscount = discount;
    notifyListeners();
  }

  // Services admin actions
  Future<void> toggleServiceState(String id) async {
    final index = _services.indexWhere((s) => s.id == id);
    if (index != -1) {
      _services[index].isActive = !_services[index].isActive;
      await LocalDatabase.saveServices(_services);
      notifyListeners();
    }
  }

  Future<void> deleteService(String id) async {
    _services.removeWhere((s) => s.id == id);
    await LocalDatabase.deleteService(id);
    notifyListeners();
  }

  /// Look up a catalogue entry by id (used by the service detail page).
  Service? serviceById(String id) {
    final match = _services.where((s) => s.id == id);
    return match.isEmpty ? null : match.first;
  }

  /// Every distinct category in the catalogue — offered when editing/adding.
  List<String> get serviceCategories {
    final set = _services.map((s) => s.category).toSet().toList()..sort();
    return set;
  }

  /// Updates any editable field of a service. Description and image are kept
  /// as-is unless explicitly passed.
  Future<void> updateServiceDetails(
    String id, {
    String? name,
    String? category,
    double? price,
    int? duration,
    bool? isActive,
    String? description,
    String? image,
  }) async {
    final index = _services.indexWhere((s) => s.id == id);
    if (index == -1) return;
    final old = _services[index];
    _services[index] = Service(
      id: old.id,
      name: name ?? old.name,
      category: category ?? old.category,
      price: price ?? old.price,
      duration: duration ?? old.duration,
      image: image ?? old.image,
      description: description ?? old.description,
      isActive: isActive ?? old.isActive,
    );
    await LocalDatabase.saveService(_services[index]);
    notifyListeners();
  }

  /// Kept for callers that only change the price.
  Future<void> updateServicePrice(String id, double price) =>
      updateServiceDetails(id, price: price);

  /// Adds a brand-new service to the catalogue and returns it.
  Future<Service> addService({
    required String name,
    required String category,
    required double price,
    required int duration,
    String description = '',
    String? image,
  }) async {
    final service = Service(
      id: 'svc-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      category: category,
      price: price,
      duration: duration,
      // Reuse an existing catalogue image from the same category so new
      // services don't render a broken tile.
      image: image ?? _fallbackImageFor(category),
      description: description,
      isActive: true,
    );
    _services.add(service);
    await LocalDatabase.saveService(service);
    notifyListeners();
    return service;
  }

  String _fallbackImageFor(String category) {
    final sameCategory = _services.where((s) => s.category == category);
    if (sameCategory.isNotEmpty) return sameCategory.first.image;
    return _services.isNotEmpty ? _services.first.image : '';
  }

  // CRM client note saving
  Future<void> saveClientPrivateNote(String customerId, String note) async {
    final index = _customers.indexWhere((c) => c.id == customerId);
    if (index != -1) {
      _customers[index].privateNote = note;
      await LocalDatabase.saveCustomers(_customers);
      notifyListeners();
    }
  }

  // Booking orders actions
  Future<Booking> createBookingOrder({
    required Customer user,
    required Service service,
    required double subtotal,
    required double discount,
    required double tax,
    required double total,
  }) async {
    // Deduct points
    if (_tempPointsApplied > 0) {
      user.points -= _tempPointsApplied;
    }

    double totalSubtotal = 0;
    for (final serviceId in _tempSelectedServiceIds) {
      final s = _services.firstWhere((svc) => svc.id == serviceId, orElse: () => service);
      totalSubtotal += s.price;
    }
    if (totalSubtotal == 0) {
      totalSubtotal = subtotal;
    }

    final earned = (totalSubtotal * 0.1).floor();
    user.points += earned;
    await LocalDatabase.setCurrentUser(user);

    Booking? lastBooking;
    for (int i = 0; i < _tempSelectedServiceIds.length; i++) {
      final serviceId = _tempSelectedServiceIds[i];
      final s = _services.firstWhere((svc) => svc.id == serviceId, orElse: () => service);
      final date = _tempSelectedDates[serviceId] ?? defaultDate;
      final time = _tempSelectedTimes[serviceId] ?? defaultTime;

      final svcDiscount = _tempSelectedServiceIds.length == 1
          ? discount
          : (s.price / totalSubtotal) * discount;
      final svcTax = (s.price - svcDiscount) * 0.05;
      final svcTotal = s.price - svcDiscount + svcTax;

      final newBooking = Booking(
        id: 'bk-${serviceId}-${DateTime.now().millisecondsSinceEpoch}-${i}',
        customerName: user.name,
        customerPhone: user.phone,
        customerEmail: user.email,
        serviceName: s.name,
        price: s.price,
        duration: s.duration,
        date: date,
        time: time,
        stylist: "Selvi",
        status: "Pending",
        loyaltyDiscount: svcDiscount,
        tax: svcTax,
        totalPaid: svcTotal,
        pointsApplied: i == 0 ? _tempPointsApplied : 0,
        pointsEarned: i == 0 ? earned : 0,
      );

      _bookings.add(newBooking);
      await LocalDatabase.saveBooking(newBooking);
      lastBooking = newBooking;
    }

    if (lastBooking == null) {
      lastBooking = Booking(
        id: 'bk-${DateTime.now().millisecondsSinceEpoch}',
        customerName: user.name,
        customerPhone: user.phone,
        customerEmail: user.email,
        serviceName: service.name,
        price: subtotal,
        duration: service.duration,
        date: tempDate,
        time: tempTime,
        stylist: "Selvi",
        status: "Pending",
        loyaltyDiscount: discount,
        tax: tax,
        totalPaid: total,
        pointsApplied: _tempPointsApplied,
        pointsEarned: earned,
      );
      _bookings.add(lastBooking);
      await LocalDatabase.saveBooking(lastBooking);
    }

    _tempSelectedServiceIds.clear();
    _tempSelectedDates.clear();
    _tempSelectedTimes.clear();
    _activeServiceId = null;

    await refreshData();
    return lastBooking;
  }

  /// Reschedules a booking to a new date/time and moves it back to Pending
  /// (owner-initiated changes need the slot re-confirmed).
  Future<void> rescheduleBooking(String bookingId, String date, String time) async {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      _bookings[index].date = date;
      _bookings[index].time = time;
      _bookings[index].status = "Pending";
      await LocalDatabase.saveBooking(_bookings[index]);
      notifyListeners();
    }
  }

  Future<void> cancelBooking(String bookingId) async {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      _bookings[index].status = "Declined";
      await LocalDatabase.updateBookingStatus(bookingId, "Declined");
      notifyListeners();
    }
  }

  /// Marks a confirmed appointment as completed (moves it into History).
  Future<void> markSessionComplete(String bookingId) async {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      _bookings[index].status = "History";
      await LocalDatabase.updateBookingStatus(bookingId, "History");
      notifyListeners();
    }
  }

  /// Finds a customer's id by their display name (used to open CRM from bookings).
  String? customerIdForName(String name) {
    final match = _customers.where((c) => c.name == name);
    return match.isEmpty ? null : match.first.id;
  }

  /// Full customer record for a display name, or null if not in the directory.
  Customer? customerByName(String name) {
    final match = _customers.where((c) => c.name == name);
    return match.isEmpty ? null : match.first;
  }

  Future<void> approveBooking(String bookingId) async {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      _bookings[index].status = "Confirmed";
      await LocalDatabase.updateBookingStatus(bookingId, "Confirmed");
      notifyListeners();
    }
  }

  Future<void> declineBooking(String bookingId) async {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      _bookings[index].status = "Declined";
      await LocalDatabase.updateBookingStatus(bookingId, "Declined");
      notifyListeners();
    }
  }

  /// Drives the countdowns. Everything on screen is computed from the clock, so
  /// this just asks the UI to repaint once a second — but only while something
  /// is actually counting. Rebuilding every listener every second when no timer
  /// is moving is pure jank; booking changes arrive via the Firestore streams
  /// independently of this ticker.
  void startTimerInterval() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_hasMovingCountdown) notifyListeners();
    });
  }

  /// True when some session today has a countdown that changes this second:
  /// one that is running, or one inside its pre-start window. The small
  /// negative grace lets the display settle on 00:00 and flip to
  /// "Ready to Start" before the ticker goes quiet again.
  bool get _hasMovingCountdown {
    for (final b in todaysBookings) {
      if (b.status != 'Confirmed') continue;
      if (b.startedAt != null) return true;
      final until = secondsUntilStartFor(b);
      if (until > -3 && until <= upNextWindow.inSeconds) return true;
    }
    return false;
  }

  /// Grants the live session more time, and tells the waiting customers about
  /// the knock-on delay.
  void addTimerMinutes(int minutes) {
    final session = liveSession;
    if (session == null) return;

    final index = _bookings.indexWhere((b) => b.id == session.id);
    if (index == -1) return;

    final booking = _bookings[index];
    booking.addedMinutes += minutes;

    final end = bookingEnd(booking)?.add(Duration(minutes: booking.addedMinutes));
    booking.liveStatus = {
      "hasDelay": true,
      "delayMinutes": booking.addedMinutes,
      "adjustedTime": end != null ? _fmtClock(end) : "",
      "notes": "Your stylist is finishing up a previous service.",
    };
    LocalDatabase.saveBooking(booking);
    notifyListeners();
  }

  /// "Finish" on the live session — completes it there and then.
  void finishSessionEarly() {
    final session = liveSession;
    if (session != null) finishSession(session.id);
  }

  Future<void> submitBookingReview(String bookingId, String reviewText) async {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      _bookings[index].review = reviewText;
      await LocalDatabase.saveBooking(_bookings[index]);
      notifyListeners();
    }
  }

  /// The headline countdown for the live session: time left while running,
  /// time until start while waiting. "--:--" when there's nothing on today.
  String getTimerString() {
    final session = liveSession;
    if (session == null) return "--:--";
    if (session.startedAt != null) return formatClock(remainingSecondsFor(session));
    // Not started yet: the pre-start countdown floors at 00:00 and holds there.
    // Nothing may run until the owner presses Start.
    return formatClock(secondsUntilStartForDisplay(session));
  }

  /// Pre-start countdown, never negative — so a session that is due but not
  /// started reads a steady 00:00 instead of counting up.
  int secondsUntilStartForDisplay(Booking b) {
    final until = secondsUntilStartFor(b);
    return until > 0 ? until : 0;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _servicesSub?.cancel();
    _customersSub?.cancel();
    _bookingsSub?.cancel();
    super.dispose();
  }
}
