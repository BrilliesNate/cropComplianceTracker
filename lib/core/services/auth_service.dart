import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/enums.dart';
import '../constants/app_constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();

      if (doc.exists) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  Future<UserModel?> registerUser({
    required String email,
    required String password,
    required String name,
    required String companyId,
    UserRole role = UserRole.USER,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final user = UserModel(
          id: userCredential.user!.uid,
          email: email,
          name: name,
          role: role,
          companyId: companyId,
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(user.id)
            .set(user.toMap());

        return user;
      }
      return null;
    } catch (e) {
      print('Error registering user: $e');
      return null;
    }
  }

  Future<UserModel?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        return await getUserData(userCredential.user!.uid);
      }
      return null;
    } catch (e) {
      print('Error logging in: $e');
      return null;
    }
  }

  Future<void> logoutUser() async {
    await _auth.signOut();
  }

  Future<bool> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      print('Error resetting password: $e');
      return false;
    }
  }

  Future<UserModel?> updateUserRole(String userId, UserRole role) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({'role': role.toString().split('.').last});

      return await getUserData(userId);
    } catch (e) {
      print('Error updating user role: $e');
      return null;
    }
  }
}