import 'package:campign_project/features/users/repository/user.repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import '../screens/profile.screen.dart';

class UserProvider extends ChangeNotifier {
  final UserRepository userRepository;
  AppUser? _user;
  bool _isLoading = false;

  int _commentCount = 0;
  int get commentCount => _commentCount;
  String? _error;
  bool _isInitialized = false;
  final Map<String, String?> _profileImages = {};

  StreamSubscription<User?>? _authSubscription;

  UserProvider({required this.userRepository}) {
    _initializeUser();
  }

  AppUser? get user => _user;

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  void _initializeUser() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        getUser(user.uid);
      } else {
        _clearUser();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> getUser(String uid) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final fetchedUser = await userRepository.fetchUserProfile(uid);
      _user = fetchedUser;
      _error = null;
      _isInitialized = true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Failed to fetch user: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUserComment() async {
    if (_user == null) return;
    try {
      final snapShot =
          await FirebaseFirestore.instance.collectionGroup('comments').where('userId', isEqualTo: _user!.uid).get();
      _commentCount = snapShot.docs.length;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to fetch comment count: $e');
      _commentCount = 0;
      notifyListeners();
    }
  }

  String? getProfileImage(String userId) => _profileImages[userId];

  Future<void> fetchProfileImage(String userId) async {
    if (_profileImages.containsKey(userId)) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

      if (doc.exists) {
        _profileImages[userId] = doc.data()?['profileImageUrl']?.toString();
      } else {
        _profileImages[userId] = null;
      }
    } catch (e) {
      debugPrint('Error fetching profile image for $userId: $e');
      _profileImages[userId] = null;
    }

    notifyListeners();
  }

  Future<void> refreshUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await getUser(currentUser.uid);
    }
  }

  void _clearUser() {
    _user = null;
    _isInitialized = true;
    notifyListeners();
  }
}
