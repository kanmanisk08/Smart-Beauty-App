import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer.dart';
import '../services/auth_service.dart';
import '../services/database.dart';

enum AuthRole { customer, owner }

class AuthProvider extends ChangeNotifier {
  Customer? _currentUser;
  AuthRole _activeLoginRole = AuthRole.customer;
  AuthRole _activeSignupRole = AuthRole.customer;
  String _currentPerspective = 'customer'; // 'customer' or 'owner'
  bool _isLoading = false;

  Customer? get currentUser => _currentUser;
  AuthRole get activeLoginRole => _activeLoginRole;
  AuthRole get activeSignupRole => _activeSignupRole;
  String get currentPerspective => _currentPerspective;
  bool get isLoading => _isLoading;

  void selectLoginRole(AuthRole role) {
    _activeLoginRole = role;
    notifyListeners();
  }

  void selectSignupRole(AuthRole role) {
    _activeSignupRole = role;
    notifyListeners();
  }

  Future<void> switchPerspective(String perspective) async {
    _currentPerspective = perspective;
    await LocalDatabase.setCurrentPerspective(perspective);
    notifyListeners();
  }

  Future<void> loadCurrentUser() async {
    _currentUser = await LocalDatabase.getCurrentUser();
    _currentPerspective = await LocalDatabase.getCurrentPerspective();
    
    // Check if Firebase Auth is logged in but local DB is empty
    try {
      final fbUser = fb.FirebaseAuth.instance.currentUser;
      if (fbUser != null && _currentUser == null) {
        final docOwner = await FirebaseFirestore.instance.collection('owners').doc(fbUser.uid).get();
        if (docOwner.exists) {
          final data = docOwner.data()!;
          _currentUser = Customer(
            id: fbUser.uid,
            name: data['name'] ?? '',
            email: data['email'] ?? fbUser.email ?? '',
            phone: data['phone'] ?? '',
            badge: 'Owner',
            memberSince: 'Jul 2026',
            birthday: '',
            skinType: '',
            hairType: '',
            preferredTech: '',
            points: 0,
            age: 0,
          );
          _currentPerspective = 'owner';
          await LocalDatabase.setCurrentUser(_currentUser!);
          await LocalDatabase.setCurrentPerspective('owner');
        } else {
          final docCust = await FirebaseFirestore.instance.collection('customers').doc(fbUser.uid).get();
          if (docCust.exists) {
            _currentUser = Customer.fromJson(docCust.data()!);
            _currentPerspective = 'customer';
            await LocalDatabase.setCurrentUser(_currentUser!);
            await LocalDatabase.setCurrentPerspective('customer');
          }
        }
      }
    } catch (e) {
      print("Error loading current user from Firebase: $e");
    }
    
    notifyListeners();
  }

  Future<bool> login(String usernameOrEmail, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final isOwner = _activeLoginRole == AuthRole.owner;
      final user = await AuthService.login(usernameOrEmail, password, isOwner: isOwner);
      if (user != null) {
        _currentUser = user;
        _currentPerspective = isOwner ? 'owner' : 'customer';
        await LocalDatabase.setCurrentUser(user);
        await LocalDatabase.setCurrentPerspective(_currentPerspective);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print("Login error: $e");
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
    String? dob,
    int? age,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final isOwner = _activeSignupRole == AuthRole.owner;
      final user = await AuthService.signUp(
        name: name,
        email: email,
        phone: phone,
        password: password,
        isOwner: isOwner,
        dob: dob,
        age: age,
      );
      if (user != null) {
        _currentUser = user;
        _currentPerspective = isOwner ? 'owner' : 'customer';
        await LocalDatabase.setCurrentUser(user);
        await LocalDatabase.setCurrentPerspective(_currentPerspective);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print("Signup error: $e");
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> updateDiagnostics({
    required String skinType,
    required String hairType,
    required String skinConcerns,
    required String hairConcerns,
    required String beautyGoal,
  }) async {
    if (_currentUser != null) {
      final updated = Customer(
        id: _currentUser!.id,
        name: _currentUser!.name,
        email: _currentUser!.email,
        phone: _currentUser!.phone,
        badge: _currentUser!.badge,
        memberSince: _currentUser!.memberSince,
        birthday: _currentUser!.birthday,
        skinType: skinType,
        hairType: hairType,
        preferredTech: _currentUser!.preferredTech,
        points: _currentUser!.points,
        age: _currentUser!.age,
        reliability: _currentUser!.reliability,
        hospitalityRating: _currentUser!.hospitalityRating,
        cancellations: _currentUser!.cancellations,
        privateNote: _currentUser!.privateNote,
        skinConcerns: skinConcerns,
        hairConcerns: hairConcerns,
        beautyGoal: beautyGoal,
      );
      
      _currentUser = updated;
      await LocalDatabase.setCurrentUser(updated);
      
      try {
        await FirebaseFirestore.instance
            .collection('customers')
            .doc(updated.id)
            .update({
          'skinType': skinType,
          'hairType': hairType,
          'skinConcerns': skinConcerns,
          'hairConcerns': hairConcerns,
          'beautyGoal': beautyGoal,
        });
      } catch (e) {
        print("Firestore diagnostics update error: $e");
      }
      
      notifyListeners();
    }
  }

  Future<void> updateProfileDetails({
    required String name,
    required String phone,
    required String email,
    required String birthday,
    required int age,
    required String skinType,
    required String hairType,
    required String skinConcerns,
    required String hairConcerns,
    required String beautyGoal,
  }) async {
    if (_currentUser != null) {
      final updated = Customer(
        id: _currentUser!.id,
        name: name,
        email: email,
        phone: phone,
        badge: _currentUser!.badge,
        memberSince: _currentUser!.memberSince,
        birthday: birthday,
        skinType: skinType,
        hairType: hairType,
        preferredTech: _currentUser!.preferredTech,
        points: _currentUser!.points,
        age: age,
        reliability: _currentUser!.reliability,
        hospitalityRating: _currentUser!.hospitalityRating,
        cancellations: _currentUser!.cancellations,
        privateNote: _currentUser!.privateNote,
        skinConcerns: skinConcerns,
        hairConcerns: hairConcerns,
        beautyGoal: beautyGoal,
      );
      
      _currentUser = updated;
      await LocalDatabase.setCurrentUser(updated);
      
      try {
        await FirebaseFirestore.instance
            .collection('customers')
            .doc(updated.id)
            .update({
          'name': name,
          'phone': phone,
          'email': email,
          'birthday': birthday,
          'age': age,
          'skinType': skinType,
          'hairType': hairType,
          'skinConcerns': skinConcerns,
          'hairConcerns': hairConcerns,
          'beautyGoal': beautyGoal,
        });
      } catch (e) {
        print("Firestore profile update error: $e");
      }
      
      notifyListeners();
    }
  }

  Future<void> updateUserPoints(int newPoints) async {
    if (_currentUser != null) {
      final updated = Customer(
        id: _currentUser!.id,
        name: _currentUser!.name,
        email: _currentUser!.email,
        phone: _currentUser!.phone,
        badge: _currentUser!.badge,
        memberSince: _currentUser!.memberSince,
        birthday: _currentUser!.birthday,
        skinType: _currentUser!.skinType,
        hairType: _currentUser!.hairType,
        preferredTech: _currentUser!.preferredTech,
        points: newPoints,
        age: _currentUser!.age,
      );
      
      _currentUser = updated;
      await LocalDatabase.setCurrentUser(updated);
      
      try {
        await FirebaseFirestore.instance
            .collection('customers')
            .doc(updated.id)
            .update({
          'points': newPoints,
        });
      } catch (e) {
        print("Firestore points update error: $e");
      }
      
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await AuthService.logout();
    await LocalDatabase.clearCurrentUser();
    await LocalDatabase.clearCurrentPerspective();
    _currentUser = null;
    _currentPerspective = 'customer';
    notifyListeners();
  }
}
