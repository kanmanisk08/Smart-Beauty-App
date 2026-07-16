import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'database.dart';
import '../models/customer.dart';

/// A sign-in or sign-up failure with a message that is safe to show the user.
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

class AuthService {
  static final fb.FirebaseAuth _firebaseAuth = fb.FirebaseAuth.instance;
  static bool _useFirebase = true;

  static void setUseFirebase(bool val) {
    _useFirebase = val;
  }

  static bool get isFirebaseEnabled => _useFirebase;

  static Customer _ownerFrom(String uid, Map<String, dynamic> data, String email) {
    return Customer(
      id: uid,
      name: data['name'] as String? ?? email.split('@').first,
      badge: 'Owner',
      memberSince: 'Jul 2026',
      phone: data['phone'] as String? ?? '',
      email: data['email'] as String? ?? email,
      birthday: '',
      skinType: '',
      hairType: '',
      preferredTech: '',
      points: 0,
      age: 0,
    );
  }

  /// Signs in with an email address. Username and phone sign-in is not supported:
  /// looking an account up by name would mean reading the customers collection
  /// before the user is authenticated, which the security rules deny.
  static Future<Customer?> login(String usernameOrEmail, String password, {required bool isOwner}) async {
    if (_useFirebase) {
      final email = usernameOrEmail.trim();
      if (!email.contains('@')) {
        throw AuthException('Please sign in with your email address.');
      }

      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final fbUser = credential.user;
      if (fbUser == null) {
        throw AuthException('Sign in failed. Please try again.');
      }
      final uid = fbUser.uid;

      if (isOwner) {
        final doc = await FirebaseFirestore.instance.collection('owners').doc(uid).get();
        if (!doc.exists) {
          // Owner records are created in the Firebase Console, never from the
          // app — otherwise anyone could grant themselves the owner dashboard.
          await _firebaseAuth.signOut();
          throw AuthException(
            'This account is not registered as an owner. Sign in through the Customer portal instead.',
          );
        }
        final owner = _ownerFrom(uid, doc.data()!, email);
        // persist: false — an owner is not a customer and should stay out of the directory.
        await LocalDatabase.setCurrentUser(owner, persist: false);
        return owner;
      }

      final doc = await FirebaseFirestore.instance.collection('customers').doc(uid).get();
      if (doc.exists) {
        final existing = Customer.fromJson(doc.data()!);
        await LocalDatabase.setCurrentUser(existing);
        return existing;
      }

      // Authenticated but no profile yet (e.g. account created before this
      // collection existed) — create one keyed to the uid.
      final created = Customer(
        id: uid,
        name: fbUser.displayName ?? email.split('@').first,
        badge: 'Occasional',
        memberSince: 'Jul 2026',
        phone: fbUser.phoneNumber ?? '',
        email: email,
        birthday: '',
        skinType: 'Normal',
        hairType: 'Straight',
        preferredTech: 'Selvi',
      );
      await LocalDatabase.setCurrentUser(created);
      return created;
    }

    // Offline fallback flow
    if (isOwner) {
      final user = Customer(
        id: 'owner-offline',
        name: usernameOrEmail,
        badge: 'Owner',
        memberSince: 'Jul 2026',
        phone: '',
        email: usernameOrEmail.contains('@') ? usernameOrEmail : '${usernameOrEmail.toLowerCase().replaceAll(' ', '')}@example.com',
        birthday: '',
        skinType: '',
        hairType: '',
        preferredTech: '',
        points: 0,
        age: 0,
      );
      await LocalDatabase.setCurrentUser(user, persist: false);
      return user;
    } else {
      final customers = await LocalDatabase.getCustomers();
      final user = customers.firstWhere(
        (c) => c.name.toLowerCase() == usernameOrEmail.toLowerCase() || c.phone == usernameOrEmail,
        orElse: () => Customer(
          id: 'cust-${DateTime.now().millisecondsSinceEpoch}',
          name: usernameOrEmail,
          badge: 'Occasional',
          memberSince: 'Jul 2026',
          phone: '+91 1234567890',
          email: usernameOrEmail.contains('@') ? usernameOrEmail : '${usernameOrEmail.toLowerCase().replaceAll(' ', '')}@example.com',
          birthday: 'Jan 01',
          skinType: 'Normal',
          hairType: 'Straight',
          preferredTech: 'Selvi',
        ),
      );
      await LocalDatabase.setCurrentUser(user);
      return user;
    }
  }

  static Future<Customer?> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
    required bool isOwner,
    String? dob,
    int? age,
  }) async {
    if (_useFirebase) {
      if (isOwner) {
        // Writing role:'owner' from the client would let anyone self-promote.
        throw AuthException(
          'Owner accounts are set up by the parlour and cannot be created here.',
        );
      }

      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final fbUser = credential.user;
      if (fbUser == null) {
        throw AuthException('Sign up failed. Please try again.');
      }

      final user = Customer(
        id: fbUser.uid,
        name: name,
        badge: 'Punctual',
        memberSince: 'Jul 2026',
        phone: phone,
        email: email,
        birthday: dob ?? '',
        skinType: 'Sensitive, Dry',
        hairType: 'Curly, 3B',
        preferredTech: 'Selvi',
        points: 200,
        age: age ?? 22,
      );
      await LocalDatabase.setCurrentUser(user);
      return user;
    }

    // Offline registration fallback flow
    final uid = 'cust-${DateTime.now().millisecondsSinceEpoch}';
    if (isOwner) {
      final user = Customer(
        id: uid,
        name: name,
        badge: 'Owner',
        memberSince: 'Jul 2026',
        phone: phone,
        email: email,
        birthday: '',
        skinType: '',
        hairType: '',
        preferredTech: '',
        points: 0,
        age: 0,
      );
      await LocalDatabase.setCurrentUser(user, persist: false);
      return user;
    } else {
      final user = Customer(
        id: uid,
        name: name,
        badge: 'Punctual',
        memberSince: 'Jul 2026',
        phone: phone,
        email: email,
        birthday: dob ?? 'Jan 14',
        skinType: 'Sensitive, Dry',
        hairType: 'Curly, 3B',
        preferredTech: 'Selvi',
        points: 200,
        age: age ?? 22,
      );
      final customers = await LocalDatabase.getCustomers();
      customers.add(user);
      await LocalDatabase.saveCustomers(customers);
      await LocalDatabase.setCurrentUser(user);
      return user;
    }
  }

  static Future<void> logout() async {
    if (_useFirebase) {
      await _firebaseAuth.signOut();
    }
  }

  static Stream<fb.User?> get authStateChanges => _firebaseAuth.authStateChanges();
}
