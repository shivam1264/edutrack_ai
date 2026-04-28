import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/user_model.dart';
import 'brain_dna_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current Firebase user
  User? get currentUser => _auth.currentUser;

  // ─── Login ───────────────────────────────────────────────────────────────────
  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      final user = credential.user;
      if (user == null) return null;
      return await getUserModel(user.uid);
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthError(e);
    }
  }

  // ─── Register (Admin use) ────────────────────────────────────────────────────
  Future<UserModel?> register({
    required String name,
    required String email,
    required String password,
    required String role,
    required String schoolId,
    String? classId,
    List<String>? assignedClasses,
    List<String>? parentOf,
    List<String>? subjects,
    String? rollNo,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      final user = credential.user;
      if (user == null) return null;

      await user.updateDisplayName(name);

      final parsedRole = UserRole.values.firstWhere(
        (r) => r.name == role,
        orElse: () => UserRole.student,
      );

      final userModel = UserModel(
        uid: user.uid,
        name: name,
        email: email,
        role: parsedRole,
        schoolId: schoolId,
        createdAt: DateTime.now(),
        classId: classId,
        assignedClasses: assignedClasses,
        parentOf: parentOf,
        subjects: subjects,
        rollNo: rollNo,
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userModel.toMap());

      // Initialize Learning DNA for students
      if (parsedRole == UserRole.student && subjects != null && subjects.isNotEmpty) {
        await BrainDNAService.instance.initializeDNA(user.uid, subjects);
      }

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthError(e);
    }
  }

  // ─── Logout ───────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _auth.signOut();
  }

  // ─── Get UserModel from Firestore ─────────────────────────────────────────────
  Future<UserModel?> getUserModel(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data()!);
    } catch (e) {
      return null;
    }
  }

  // ─── Get current UserModel ────────────────────────────────────────────────────
  Future<UserModel?> getCurrentUserModel() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return getUserModel(user.uid);
  }

  // ─── Get user role ────────────────────────────────────────────────────────────
  Future<UserRole?> getUserRole(String uid) async {
    final model = await getUserModel(uid);
    return model?.role;
  }

  // ─── Update FCM Token ─────────────────────────────────────────────────────────
  Future<void> updateFcmToken(String uid, String token) async {
    await _firestore.collection('users').doc(uid).update({
      'fcm_token': token,
    });
  }

  // ─── Password Reset ───────────────────────────────────────────────────────────
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthError(e);
    }
  }

  // ─── Delete User Record (Admin) ───────────────────────────────────────────
  Future<void> deleteUserRecord(String uid) async {
    await _firestore.collection('users').doc(uid).delete();
  }

  // ─── Delete Full Account (Auth + Firestore via Cloud Function) ─────────────
  Future<void> deleteUserFullAccount(String uid) async {
    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('deleteUser');
      await callable.call({'targetUid': uid});
    } catch (e) {
      debugPrint('❌ Failed to delete full account: $e');
      // Fallback: at least delete from Firestore if function fails
      await deleteUserRecord(uid);
      throw e;
    }
  }

  // ─── Update User Profile Data ─────────────────────────────────────────────
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
  }

  // ─── Error mapping ────────────────────────────────────────────────────────────
  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}
