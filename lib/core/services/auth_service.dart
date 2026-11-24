import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/enums.dart';
import '../constants/app_constants.dart';
import 'package:cropCompliance/providers/locale_provider.dart';

/// Thrown when a user tries to sign in (or resume a session) on an account an
/// admin has deactivated.
class AccountDeactivatedException implements Exception {
  static String get message => LocaleProvider.instance.l10n.authDeactivated;
  @override
  String toString() => message;
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  /// The signed-in account once Firebase has finished restoring it.
  ///
  /// On the web, `currentUser` is null for a short moment after a page reload
  /// while Firebase reads the saved session from the browser. Reading it too
  /// early made a signed-in user look signed out. `authStateChanges()` emits
  /// its first value only once that restore is complete.
  Future<User?> restoredUser({Duration timeout = const Duration(seconds: 8)}) async {
    final now = _auth.currentUser;
    if (now != null) return now;
    try {
      return await _auth.authStateChanges().first.timeout(timeout);
    } catch (_) {
      return _auth.currentUser;
    }
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> getUserData(String uid) async {
    // One retry: a transient network/permission hiccup right after a reload
    // used to be read as "no profile", which treated a signed-in user as
    // signed out.
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final doc = await _firestore
            .collection(AppConstants.usersCollection)
            .doc(uid)
            .get();

        if (doc.exists) {
          return UserModel.fromMap(doc.data()!, doc.id);
        }
        return null; // genuinely no profile
      } catch (e) {
        print('Error getting user data (attempt ${attempt + 1}): $e');
        if (attempt == 0) {
          await Future<void>.delayed(const Duration(milliseconds: 700));
        }
      }
    }
    return null;
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

  /// Signs in. Returns null for bad credentials / missing profile. Throws
  /// [AccountDeactivatedException] when an admin has deactivated the account —
  /// either the Firebase Auth account is disabled, or the profile is flagged
  /// inactive — so the UI can say so instead of "invalid password".
  Future<UserModel?> loginUser({
    required String email,
    required String password,
  }) async {
    UserCredential credential;
    try {
      credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-disabled') throw AccountDeactivatedException();
      print('Error logging in: $e');
      return null;
    } catch (e) {
      print('Error logging in: $e');
      return null;
    }

    final uid = credential.user?.uid;
    if (uid == null) return null;

    final user = await getUserData(uid);
    if (user != null && !user.isActive) {
      // Don't leave a live session behind for a deactivated account.
      await _auth.signOut();
      throw AccountDeactivatedException();
    }
    return user;
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