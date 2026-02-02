import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProvider with ChangeNotifier {
  Map<String, dynamic>? _user;
  bool _isLoading = false;

  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> login(String uid, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Fetch user doc
      final doc = await _firestore.collection('users').doc(uid).get();
      
      if (!doc.exists) {
        _isLoading = false;
        notifyListeners();
        return false; // User not found
      }

      final userData = doc.data()!;
      
      // 2. Check Password (in real app, use hashing!)
      if (userData['password'] == password) {
        // Successful Login
        _user = userData;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        // Wrong password
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      // print("Login Error: $e"); // Removed for production
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _user = null;
    notifyListeners();
  }
}
