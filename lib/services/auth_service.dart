import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'database.dart';
import '../models/customer.dart';

class AuthService {
  static final fb.FirebaseAuth _firebaseAuth = fb.FirebaseAuth.instance;
  static bool _useFirebase = true;

  static void setUseFirebase(bool val) {
    _useFirebase = val;
  }

  static bool get isFirebaseEnabled => _useFirebase;

  static Future<Customer?> login(String usernameOrEmail, String password, {required bool isOwner}) async {
    if (_useFirebase) {
      try {
        String email = usernameOrEmail;
        if (!usernameOrEmail.contains('@')) {
          // Attempt firestore email lookup by name or phone
          final collection = isOwner ? 'owners' : 'customers';
          final queryName = await FirebaseFirestore.instance
              .collection(collection)
              .where('name', isEqualTo: usernameOrEmail)
              .get();
          if (queryName.docs.isNotEmpty) {
            email = queryName.docs.first.get('email') as String;
          } else {
            final queryPhone = await FirebaseFirestore.instance
                .collection(collection)
                .where('phone', isEqualTo: usernameOrEmail)
                .get();
            if (queryPhone.docs.isNotEmpty) {
              email = queryPhone.docs.first.get('email') as String;
            } else {
              // Fallback to example email
              email = '${usernameOrEmail.toLowerCase().replaceAll(' ', '')}@example.com';
            }
          }
        }

        final credential = await _firebaseAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        
        if (credential.user != null) {
          final uid = credential.user!.uid;
          if (isOwner) {
            final doc = await FirebaseFirestore.instance.collection('owners').doc(uid).get();
            if (!doc.exists) {
              // Create default owner record if signed in but no doc exists
              final newOwner = {
                'id': uid,
                'name': usernameOrEmail.contains('@') ? usernameOrEmail.split('@').first : usernameOrEmail,
                'email': email,
                'phone': '',
                'role': 'owner',
              };
              await FirebaseFirestore.instance.collection('owners').doc(uid).set(newOwner);
              final user = Customer(
                id: uid,
                name: newOwner['name'] as String,
                badge: 'Owner',
                memberSince: 'Jul 2026',
                phone: '',
                email: email,
                birthday: '',
                skinType: '',
                hairType: '',
                preferredTech: '',
                points: 0,
                age: 0,
              );
              await LocalDatabase.setCurrentUser(user);
              return user;
            } else {
              final data = doc.data()!;
              final user = Customer(
                id: uid,
                name: data['name'] ?? '',
                badge: 'Owner',
                memberSince: 'Jul 2026',
                phone: data['phone'] ?? '',
                email: data['email'] ?? '',
                birthday: '',
                skinType: '',
                hairType: '',
                preferredTech: '',
                points: 0,
                age: 0,
              );
              await LocalDatabase.setCurrentUser(user);
              return user;
            }
          } else {
            final doc = await FirebaseFirestore.instance.collection('customers').doc(uid).get();
            if (!doc.exists) {
              // Find or create local customer profile matching this email
              final customers = await LocalDatabase.getCustomers();
              final existing = customers.firstWhere(
                (c) => c.email.toLowerCase() == email.toLowerCase(),
                orElse: () => Customer(
                  id: uid,
                  name: usernameOrEmail.contains('@') ? usernameOrEmail.split('@').first : usernameOrEmail,
                  badge: 'Occasional',
                  memberSince: 'Jul 2026',
                  phone: '+91 1234567890',
                  email: email,
                  birthday: 'Jan 01',
                  skinType: 'Normal',
                  hairType: 'Straight',
                  preferredTech: 'Selvi',
                ),
              );
              await LocalDatabase.setCurrentUser(existing);
              return existing;
            } else {
              final existing = Customer.fromJson(doc.data()!);
              await LocalDatabase.setCurrentUser(existing);
              return existing;
            }
          }
        }
      } catch (e) {
        print("Firebase auth login failure: $e");
        rethrow;
      }
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
      await LocalDatabase.setCurrentUser(user);
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
      try {
        final credential = await _firebaseAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        
        if (credential.user != null) {
          final uid = credential.user!.uid;
          if (isOwner) {
            final ownerData = {
              'id': uid,
              'name': name,
              'email': email,
              'phone': phone,
              'role': 'owner',
            };
            await FirebaseFirestore.instance.collection('owners').doc(uid).set(ownerData);
            
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
            await LocalDatabase.setCurrentUser(user);
            return user;
          } else {
            final user = Customer(
              id: uid,
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
            await LocalDatabase.saveCustomer(user);
            await LocalDatabase.setCurrentUser(user);
            return user;
          }
        }
      } catch (e) {
        print("Firebase auth register failure: $e");
        rethrow;
      }
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
      await LocalDatabase.setCurrentUser(user);
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
