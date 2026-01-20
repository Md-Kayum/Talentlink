import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// -------------------------
  /// LOGIN
  /// -------------------------
  Future<void> login({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// -------------------------
  /// REGISTER
  /// -------------------------
  Future<void> register({
    required String email,
    required String password,
    required String role, // student | company | admin
    required Map<String, dynamic> extraData,
  }) async {
    // 1. Create auth user
    UserCredential credential =
        await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;

    // 2. Create Firestore user document
    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'email': email,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
      ...extraData,
    });
  }

  /// -------------------------
  /// LOGOUT
  /// -------------------------
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// -------------------------
  /// CURRENT USER ROLE
  /// -------------------------
  Future<String?> getCurrentUserRole() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc =
        await _firestore.collection('users').doc(user.uid).get();

    if (!doc.exists) return null;

    final data = doc.data();
    return data?['role'] as String?;
  }
}
