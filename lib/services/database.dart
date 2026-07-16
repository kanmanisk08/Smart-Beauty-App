import 'dart:convert';
import 'package:flutter/foundation.dart';
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

  // ─── Initialization ───────────────────────────────────────────────────────
  /// Seeds the service catalogue if it is missing or out of date. Customers and
  /// bookings are deliberately never seeded — they come from real signups and
  /// real appointments.
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
        debugPrint('Firestore services initialized with ${_defaultServices.length} items.');
      }
    } catch (e) {
      debugPrint('Firestore initDatabase error: $e');
    }
  }

  /// Wipes every customer and booking and restores the service catalogue to the
  /// defaults. Destructive: real signups and real appointments are deleted too.
  /// Requires an owner session — only owners may write the catalogue.
  static Future<void> resetAndReSeedDatabase() async {
    try {
      for (final collection in [_services, _customers, _bookings]) {
        final snap = await collection.get();
        final batch = _db.batch();
        for (final doc in snap.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }

      final batch = _db.batch();
      for (final svc in _defaultServices) {
        batch.set(_services.doc(svc['id'] as String), svc);
      }
      await batch.commit();
      debugPrint('Firestore reset: catalogue restored, customers and bookings cleared.');
    } catch (e) {
      debugPrint('Firestore resetAndReSeedDatabase error: $e');
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
