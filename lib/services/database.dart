import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/service.dart';
import '../models/customer.dart';
import '../models/booking.dart';

class LocalDatabase {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _currentUserKey = 'selvi_current_user';

  // ─── Collection References ───────────────────────────────────────────────
  static CollectionReference get _services => _db.collection('services');
  static CollectionReference get _customers => _db.collection('customers');
  static CollectionReference get _bookings => _db.collection('bookings');

  // ─── Default seed data (only written once if Firestore is empty) ─────────
  static final List<Map<String, dynamic>> _defaultServices = [
    // Haircuts & Styling
    {
      "id": "svc-1",
      "name": "Women's Cut & Style",
      "price": 300.0,
      "duration": 45,
      "category": "Haircuts & Styling",
      "description": "Includes custom consultation, shampoo, conditioning, blow dry & styling.",
      "isActive": true,
      "image": "assets/images/services/01_womens_cut_and_style.png"
    },
    {
      "id": "svc-1b",
      "name": "Classic Hair Trim",
      "price": 150.0,
      "duration": 20,
      "category": "Haircuts & Styling",
      "description": "Simple trimming of split ends to maintain length and healthy hair.",
      "isActive": true,
      "image": "assets/images/services/02_classic_hair_trim.png"
    },
    {
      "id": "svc-1c",
      "name": "Hair Spa & Conditioning",
      "price": 800.0,
      "duration": 60,
      "category": "Haircuts & Styling",
      "description": "Intensive nourishment treatment to repair dry, damaged, or frizzy hair.",
      "isActive": true,
      "image": "assets/images/services/03_hair_spa_and_conditioning.png"
    },
    {
      "id": "svc-1d",
      "name": "Blow-Dry & Styling",
      "price": 250.0,
      "duration": 30,
      "category": "Haircuts & Styling",
      "description": "Wash and styling with blow-dryer, straightener, or curling wand for special occasions.",
      "isActive": true,
      "image": "assets/images/services/04_blow_dry_and_styling.png"
    },
    // Nails & Extensions
    {
      "id": "svc-6",
      "name": "Express Mani",
      "price": 300.0,
      "duration": 30,
      "category": "Nails & Extensions",
      "description": "Quick clean, shaping, cuticle care, and standard polish of your choice.",
      "isActive": true,
      "image": "assets/images/services/10_express_mani.png"
    },
    {
      "id": "svc-3b",
      "name": "Gel Pedicure",
      "price": 500.0,
      "duration": 50,
      "category": "Nails & Extensions",
      "description": "Relaxing foot soak, scrub, nail shaping, cuticle work, and long-lasting gel polish.",
      "isActive": true,
      "image": "assets/images/services/11_gel_pedicure.png"
    },
    {
      "id": "svc-3c",
      "name": "Nail Extensions & Custom Art",
      "price": 1200.0,
      "duration": 75,
      "category": "Nails & Extensions",
      "description": "Full set of acrylic or gel nail extensions with customized paint/gems.",
      "isActive": true,
      "image": "assets/images/services/12_nail_extensions_custom_art.png"
    },
    // Skincare & Facials
    {
      "id": "svc-5",
      "name": "Hydrating Facial",
      "price": 700.0,
      "duration": 60,
      "category": "Skincare & Facials",
      "description": "Deep nourishing hydrating treatment for a glowing, fresh, and radiant skin complexion.",
      "isActive": true,
      "image": "assets/images/services/13_hydrating_facial.png"
    },
    // Threading & Waxing
    {
      "id": "svc-5d",
      "name": "Underarms Waxing",
      "price": 100.0,
      "duration": 15,
      "category": "Threading & Waxing",
      "description": "Quick clean waxing for underarms using gentle, irritation-free wax.",
      "isActive": true,
      "image": "assets/images/services/19_underarms_waxing.png"
    },
    // Makeup & Bridal
    {
      "id": "svc-6b",
      "name": "Party Makeup & Hair Styling",
      "price": 1500.0,
      "duration": 60,
      "category": "Makeup & Bridal",
      "description": "Stunning party makeup look customized to your outfit with standard hair styling.",
      "isActive": true,
      "image": "assets/images/services/20_party_makeup_and_hair_styling.png"
    },
    {
      "id": "svc-6c",
      "name": "Bridal Makeup / HD Makeover",
      "price": 5000.0,
      "duration": 120,
      "category": "Makeup & Bridal",
      "description": "Elite premium bridal makeup with complete HD contouring, hairstyling, and draping.",
      "isActive": true,
      "image": "assets/images/services/21_bridal_makeup_hd_makeover.png"
    }
  ];

  static final List<Map<String, dynamic>> _defaultCustomers = [
    {
      "id": "cust-1",
      "name": "Kanmani",
      "phone": "+91 9876543210",
      "email": "kanmani@gmail.com",
      "badge": "Occasional",
      "memberSince": "Oct 2021",
      "birthday": "Jan 14",
      "skinType": "Sensitive, Dry",
      "hairType": "Curly, 3B",
      "preferredTech": "Selvi",
      "points": 850,
      "privateNote": "Likes honey balayage color styles."
    },
    {
      "id": "cust-2",
      "name": "Kanishka",
      "phone": "+91 9123456780",
      "email": "kanishka@gmail.com",
      "badge": "Punctual",
      "memberSince": "Mar 2022",
      "birthday": "Feb 20",
      "skinType": "Oily",
      "hairType": "Straight",
      "preferredTech": "Selvi",
      "points": 450,
      "privateNote": "Prefer clipper styles."
    },
    {
      "id": "cust-3",
      "name": "Harini",
      "phone": "+91 9988776655",
      "email": "harini@gmail.com",
      "badge": "Punctual",
      "memberSince": "Aug 2021",
      "birthday": "May 12",
      "skinType": "Normal",
      "hairType": "Wavy",
      "preferredTech": "Selvi",
      "points": 620,
      "privateNote": "Regular styling sessions."
    },
    {
      "id": "cust-4",
      "name": "Monica Bellucci",
      "phone": "+91 9999988888",
      "email": "monica@gmail.com",
      "badge": "Punctual",
      "memberSince": "Oct 2021",
      "birthday": "Sep 30",
      "skinType": "Combination",
      "hairType": "Wavy, 2A",
      "preferredTech": "Selvi",
      "points": 850,
      "privateNote": "Favors hair coloring."
    },
    {
      "id": "cust-5",
      "name": "Sarah Jenkins",
      "phone": "+91 8888877777",
      "email": "sarah@gmail.com",
      "badge": "New Customer",
      "memberSince": "May 2026",
      "birthday": "Dec 05",
      "skinType": "Normal",
      "hairType": "Straight",
      "preferredTech": "Selvi",
      "points": 200,
      "privateNote": ""
    },
    {
      "id": "cust-6",
      "name": "Priyanka",
      "phone": "+91 7777766666",
      "email": "priyanka@gmail.com",
      "badge": "Occasional",
      "memberSince": "Jan 2023",
      "birthday": "Mar 21",
      "skinType": "Dry",
      "hairType": "Curly",
      "preferredTech": "Selvi",
      "points": 320,
      "privateNote": ""
    },
    {
      "id": "cust-7",
      "name": "Mithraa",
      "phone": "+91 6666655555",
      "email": "mithraa@gmail.com",
      "badge": "Occasional",
      "memberSince": "Nov 2022",
      "birthday": "Apr 15",
      "skinType": "Oily",
      "hairType": "Straight",
      "preferredTech": "Selvi",
      "points": 150,
      "privateNote": ""
    },
    {
      "id": "cust-8",
      "name": "Medhaa",
      "phone": "+91 5555544444",
      "email": "medhaa@gmail.com",
      "badge": "New Customer",
      "memberSince": "Jun 2026",
      "birthday": "Jul 04",
      "skinType": "Sensitive",
      "hairType": "Wavy",
      "preferredTech": "Selvi",
      "points": 200,
      "privateNote": ""
    },
    {
      "id": "cust-9",
      "name": "Athmika Sumithran",
      "phone": "+91 4444433333",
      "email": "athmika@gmail.com",
      "badge": "New Customer",
      "memberSince": "Apr 2026",
      "birthday": "Jun 18",
      "skinType": "Dry",
      "hairType": "Curly",
      "preferredTech": "Selvi",
      "points": 200,
      "privateNote": ""
    }
  ];

  /// Builds a single booking record, deriving tax (5%), total, and points earned
  /// from the price so seed data stays internally consistent with the checkout flow.
  static Map<String, dynamic> _seedBooking({
    required String id,
    required String customer,
    required String phone,
    required String email,
    required String service,
    required double price,
    required int duration,
    required String date,
    required String time,
    required String status,
    Map<String, dynamic>? liveStatus,
  }) {
    final tax = double.parse((price * 0.05).toStringAsFixed(2));
    final total = double.parse((price + tax).toStringAsFixed(2));
    return {
      "id": id,
      "customerName": customer,
      "customerPhone": phone,
      "customerEmail": email,
      "serviceName": service,
      "price": price,
      "duration": duration,
      "date": date,
      "time": time,
      "stylist": "Selvi",
      "status": status,
      "loyaltyDiscount": 0.0,
      "tax": tax,
      "totalPaid": total,
      "pointsApplied": 0,
      "pointsEarned": (price * 0.1).floor(),
      if (liveStatus != null) "liveStatus": liveStatus,
    };
  }

  /// Default bookings, generated relative to the current date so that "today",
  /// live-session, and month-over-month logic always have realistic data to show.
  /// Every booking references a real catalogue service and a real customer.
  static List<Map<String, dynamic>> _buildDefaultBookings() {
    final now = DateTime.now();
    String fmt(DateTime d) =>
        "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

    final today = fmt(now);
    final tomorrow = fmt(now.add(const Duration(days: 1)));
    final earlierA = fmt(now.subtract(const Duration(days: 5)));
    final earlierB = fmt(now.subtract(const Duration(days: 8)));
    final lastMonthA = fmt(DateTime(now.year, now.month - 1, 8));
    final lastMonthB = fmt(DateTime(now.year, now.month - 1, 15));
    final lastMonthC = fmt(DateTime(now.year, now.month - 1, 21));

    return [
      // ── Today ─────────────────────────────────────────────────────────────
      _seedBooking(
        id: "bk-1", customer: "Harini", phone: "+91 9988776655", email: "harini@gmail.com",
        service: "Classic Hair Trim", price: 150.0, duration: 20,
        date: today, time: "09:30 AM", status: "History",
      ),
      _seedBooking(
        id: "bk-2", customer: "Monica Bellucci", phone: "+91 9999988888", email: "monica@gmail.com",
        service: "Hydrating Facial", price: 700.0, duration: 60,
        date: today, time: "12:00 PM", status: "Confirmed",
        liveStatus: {
          "hasDelay": true,
          "delayMinutes": 10,
          "adjustedTime": "12:10 PM",
          "notes": "Stylist is finishing up a previous service",
        },
      ),
      _seedBooking(
        id: "bk-3", customer: "Kanmani", phone: "+91 9876543210", email: "kanmani@gmail.com",
        service: "Express Mani", price: 300.0, duration: 30,
        date: today, time: "03:00 PM", status: "Confirmed",
      ),
      _seedBooking(
        id: "bk-4", customer: "Kanishka", phone: "+91 9123456780", email: "kanishka@gmail.com",
        service: "Women's Cut & Style", price: 300.0, duration: 45,
        date: today, time: "05:00 PM", status: "Pending",
      ),
      // ── Tomorrow ──────────────────────────────────────────────────────────
      _seedBooking(
        id: "bk-5", customer: "Sarah Jenkins", phone: "+91 8888877777", email: "sarah@gmail.com",
        service: "Gel Pedicure", price: 500.0, duration: 50,
        date: tomorrow, time: "11:00 AM", status: "Confirmed",
      ),
      _seedBooking(
        id: "bk-6", customer: "Priyanka", phone: "+91 7777766666", email: "priyanka@gmail.com",
        service: "Party Makeup & Hair Styling", price: 1500.0, duration: 60,
        date: tomorrow, time: "02:00 PM", status: "Pending",
      ),
      // ── Earlier this month (completed) ────────────────────────────────────
      _seedBooking(
        id: "bk-7", customer: "Mithraa", phone: "+91 6666655555", email: "mithraa@gmail.com",
        service: "Underarms Waxing", price: 100.0, duration: 15,
        date: earlierA, time: "10:00 AM", status: "History",
      ),
      _seedBooking(
        id: "bk-8", customer: "Athmika Sumithran", phone: "+91 4444433333", email: "athmika@gmail.com",
        service: "Bridal Makeup / HD Makeover", price: 5000.0, duration: 120,
        date: earlierB, time: "01:00 PM", status: "History",
      ),
      // ── Last month (baseline for the revenue trend) ───────────────────────
      _seedBooking(
        id: "bk-9", customer: "Kanmani", phone: "+91 9876543210", email: "kanmani@gmail.com",
        service: "Nail Extensions & Custom Art", price: 1200.0, duration: 75,
        date: lastMonthA, time: "11:30 AM", status: "History",
      ),
      _seedBooking(
        id: "bk-10", customer: "Medhaa", phone: "+91 5555544444", email: "medhaa@gmail.com",
        service: "Hydrating Facial", price: 700.0, duration: 60,
        date: lastMonthA, time: "04:00 PM", status: "History",
      ),
      _seedBooking(
        id: "bk-11", customer: "Monica Bellucci", phone: "+91 9999988888", email: "monica@gmail.com",
        service: "Party Makeup & Hair Styling", price: 1500.0, duration: 60,
        date: lastMonthB, time: "05:00 PM", status: "History",
      ),
      _seedBooking(
        id: "bk-12", customer: "Harini", phone: "+91 9988776655", email: "harini@gmail.com",
        service: "Hair Spa & Conditioning", price: 800.0, duration: 60,
        date: lastMonthB, time: "02:30 PM", status: "History",
      ),
      _seedBooking(
        id: "bk-13", customer: "Priyanka", phone: "+91 7777766666", email: "priyanka@gmail.com",
        service: "Women's Cut & Style", price: 300.0, duration: 45,
        date: lastMonthC, time: "10:30 AM", status: "History",
      ),
    ];
  }

  // ─── Initialization ───────────────────────────────────────────────────────
  /// Seeds Firestore with default data. If services list count is outdated, recreates the collection.
  static Future<void> initDatabase() async {
    try {
      final servicesSnap = await _services.get();
      bool needsReSeed = servicesSnap.docs.isEmpty || 
          servicesSnap.docs.length != _defaultServices.length ||
          servicesSnap.docs.any((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final img = data['image'] as String? ?? '';
            return img.startsWith('http');
          });

      if (needsReSeed) {
        final batch = _db.batch();
        // Clear out any old records to avoid duplication
        for (final doc in servicesSnap.docs) {
          batch.delete(doc.reference);
        }
        // Write the fresh list
        for (final svc in _defaultServices) {
          batch.set(_services.doc(svc['id'] as String), svc);
        }
        await batch.commit();
        print('Firestore services initialized with ${_defaultServices.length} items.');
      }

      // Seed customers if empty
      final customersSnap = await _customers.get();
      if (customersSnap.docs.isEmpty) {
        final batch = _db.batch();
        for (final cust in _defaultCustomers) {
          batch.set(_customers.doc(cust['id'] as String), cust);
        }
        await batch.commit();
        print('Firestore customers initialized with ${_defaultCustomers.length} items.');
      }

      // Seed bookings if empty
      final bookingsSnap = await _bookings.get();
      if (bookingsSnap.docs.isEmpty) {
        final defaultBookings = _buildDefaultBookings();
        final batch = _db.batch();
        for (final booking in defaultBookings) {
          batch.set(_bookings.doc(booking['id'] as String), booking);
        }
        await batch.commit();
        print('Firestore bookings initialized with ${defaultBookings.length} items.');
      }
    } catch (e) {
      print('Firestore initDatabase error: $e');
    }
  }

  /// Deletes all documents in services, customers, and bookings, and re-seeds them with default mock data.
  static Future<void> resetAndReSeedDatabase() async {
    try {
      // 1. Delete all services
      final servicesSnap = await _services.get();
      final batch1 = _db.batch();
      for (final doc in servicesSnap.docs) {
        batch1.delete(doc.reference);
      }
      await batch1.commit();

      // 2. Delete all customers
      final customersSnap = await _customers.get();
      final batch2 = _db.batch();
      for (final doc in customersSnap.docs) {
        batch2.delete(doc.reference);
      }
      await batch2.commit();

      // 3. Delete all bookings
      final bookingsSnap = await _bookings.get();
      final batch3 = _db.batch();
      for (final doc in bookingsSnap.docs) {
        batch3.delete(doc.reference);
      }
      await batch3.commit();

      // 4. Seed everything fresh
      final batch4 = _db.batch();
      for (final svc in _defaultServices) {
        batch4.set(_services.doc(svc['id'] as String), svc);
      }
      for (final cust in _defaultCustomers) {
        batch4.set(_customers.doc(cust['id'] as String), cust);
      }
      for (final booking in _buildDefaultBookings()) {
        batch4.set(_bookings.doc(booking['id'] as String), booking);
      }
      await batch4.commit();
      print('Firestore fully reset and re-seeded successfully.');
    } catch (e) {
      print('Firestore resetAndReSeedDatabase error: $e');
    }
  }

  // ─── SERVICES ─────────────────────────────────────────────────────────────
  static Future<List<Service>> getServices() async {
    try {
      final snap = await _services.get();
      return snap.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Service.fromJson(data);
      }).toList();
    } catch (e) {
      print('getServices error: $e');
      return [];
    }
  }

  static Future<void> saveServices(List<Service> services) async {
    try {
      final batch = _db.batch();
      for (final svc in services) {
        batch.set(_services.doc(svc.id), svc.toJson());
      }
      await batch.commit();
    } catch (e) {
      print('saveServices error: $e');
    }
  }

  static Future<void> saveService(Service service) async {
    try {
      await _services.doc(service.id).set(service.toJson());
    } catch (e) {
      print('saveService error: $e');
    }
  }

  static Future<void> deleteService(String id) async {
    try {
      await _services.doc(id).delete();
    } catch (e) {
      print('deleteService error: $e');
    }
  }

  static Stream<List<Service>> streamServices() {
    return _services.snapshots().map((snap) {
      return snap.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Service.fromJson(data);
      }).toList();
    });
  }

  // ─── CUSTOMERS ────────────────────────────────────────────────────────────
  static Future<List<Customer>> getCustomers() async {
    try {
      final snap = await _customers.get();
      return snap.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Customer.fromJson(data);
      }).toList();
    } catch (e) {
      print('getCustomers error: $e');
      return [];
    }
  }

  static Future<void> saveCustomers(List<Customer> customers) async {
    try {
      final batch = _db.batch();
      for (final cust in customers) {
        batch.set(_customers.doc(cust.id), cust.toJson());
      }
      await batch.commit();
    } catch (e) {
      print('saveCustomers error: $e');
    }
  }

  static Future<void> saveCustomer(Customer customer) async {
    try {
      await _customers.doc(customer.id).set(customer.toJson());
    } catch (e) {
      print('saveCustomer error: $e');
    }
  }

  static Stream<List<Customer>> streamCustomers() {
    return _customers.snapshots().map((snap) {
      return snap.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Customer.fromJson(data);
      }).toList();
    });
  }

  // ─── BOOKINGS ─────────────────────────────────────────────────────────────
  static Future<List<Booking>> getBookings() async {
    try {
      final snap = await _bookings.get();
      return snap.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Booking.fromJson(data);
      }).toList();
    } catch (e) {
      print('getBookings error: $e');
      return [];
    }
  }

  static Future<void> saveBookings(List<Booking> bookings) async {
    try {
      final batch = _db.batch();
      for (final booking in bookings) {
        batch.set(_bookings.doc(booking.id), booking.toJson());
      }
      await batch.commit();
    } catch (e) {
      print('saveBookings error: $e');
    }
  }

  static Future<void> saveBooking(Booking booking) async {
    try {
      await _bookings.doc(booking.id).set(booking.toJson());
    } catch (e) {
      print('saveBooking error: $e');
    }
  }

  static Future<void> updateBookingStatus(String bookingId, String status) async {
    try {
      await _bookings.doc(bookingId).update({'status': status});
    } catch (e) {
      print('updateBookingStatus error: $e');
    }
  }

  /// Real-time stream of all bookings — used on owner dashboard
  static Stream<List<Booking>> streamBookings() {
    return _bookings.snapshots().map((snap) {
      return snap.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Booking.fromJson(data);
      }).toList();
    });
  }

  /// Stream bookings for a specific customer by name
  static Stream<List<Booking>> streamBookingsForCustomer(String customerName) {
    return _bookings
        .where('customerName', isEqualTo: customerName)
        .snapshots()
        .map((snap) {
      return snap.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Booking.fromJson(data);
      }).toList();
    });
  }

  // ─── CURRENT USER SESSION (stored locally for speed) ─────────────────────
  static Future<Customer?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_currentUserKey);
    if (jsonStr == null) return null;
    return Customer.fromJson(json.decode(jsonStr));
  }

  /// Stores the session locally. [persist] also mirrors the profile to the
  /// customers collection so the owner can see it — pass false for owner
  /// sessions, which do not belong in the customer directory.
  static Future<void> setCurrentUser(Customer user, {bool persist = true}) async {
    // Save session locally for fast access
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, json.encode(user.toJson()));

    if (persist) {
      await saveCustomer(user);
    }
  }

  static Future<void> clearCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
  }

  static Future<String> getCurrentPerspective() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('selvi_current_perspective') ?? 'customer';
  }

  static Future<void> setCurrentPerspective(String perspective) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selvi_current_perspective', perspective);
  }

  static Future<void> clearCurrentPerspective() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('selvi_current_perspective');
  }
}
