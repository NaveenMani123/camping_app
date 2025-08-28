import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthRepository with ChangeNotifier {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  User? get currentUser => firebaseAuth.currentUser;
  Stream<User?> get authStateChange => firebaseAuth.authStateChanges();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _storage = const FlutterSecureStorage();

  Future<UserCredential> signIn({required String email, required String password}) async {
    return await firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> createAccount({required String email, required String password}) async {
    return await firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await firebaseAuth.signOut();
    notifyListeners();
  }



  Future<void> resetPassword({required String email}) async {
    await firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> updateUserName({required String userName}) async {
    await currentUser!.updateDisplayName(userName);
  }

  Future<void> resetPasswordFromCurrentPassword({
    required String currentPassword,
    required String newPassword,
    required String email,
  }) async {
    AuthCredential credential = EmailAuthProvider.credential(email: email, password: currentPassword);
    await currentUser!.reauthenticateWithCredential(credential);
    await currentUser!.updatePassword(newPassword);
  }

  Future<void> saveUserCredentials(String phone, String password) async {
    await _firestore.collection('users').doc(phone).set({'password': password});
    await _storage.write(key: phone, value: password);
  }

  Future<void> signInWithPhone({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) codeSent,
    required Function(String error) verificationFailed,
    required Function(PhoneAuthCredential credential) verificationCompleted,
    required Function() codeAutoRetrievalTimeout,
  }) async {
    await firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: verificationCompleted,
      verificationFailed: (e) => verificationFailed(e.message ?? e.toString()),
      codeSent: (id, token) => codeSent(id, token),
      codeAutoRetrievalTimeout: (_) => codeAutoRetrievalTimeout(),
    );
  }

  Future<UserCredential> verifyOtp({required String verificationId, required String smsCode}) async {
    final cred = PhoneAuthProvider.credential(verificationId: verificationId, smsCode: smsCode);
    return await firebaseAuth.signInWithCredential(cred);
  }
}
