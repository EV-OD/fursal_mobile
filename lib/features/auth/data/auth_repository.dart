import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../domain/auth_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    FirebaseAuth.instance,
    FirebaseFirestore.instance,
    GoogleSignIn(),
  );
});

final authStateProvider = StreamProvider<AuthUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  AuthRepository(this._auth, this._firestore, this._googleSignIn);

  Stream<AuthUser?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;

      // Fetch user data from Firestore
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          return AuthUser.fromMap(doc.data()!, user.uid);
        } else {
          // If user exists in Auth but not Firestore (e.g. first google login), create it
          // Or return a basic user and let the UI handle profile completion
          // For now, we'll return a basic user with 'user' role
          return AuthUser(
            uid: user.uid,
            email: user.email ?? '',
            displayName: user.displayName,
            photoURL: user.photoURL,
            role: 'user',
          );
        }
      } catch (e) {
        // Fallback if firestore fails
        return AuthUser(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName,
          photoURL: user.photoURL,
          role: 'user',
        );
      }
    });
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> createUserWithEmailAndPassword(
      String email, String password, String name) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (credential.user != null) {
      await _saveUserToFirestore(credential.user!, name);
    }
  }

  Future<void> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return; // User canceled

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    if (userCredential.user != null) {
      // Check if user exists, if not create
      final doc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();
      if (!doc.exists) {
        await _saveUserToFirestore(
            userCredential.user!, googleUser.displayName ?? 'User');
      }
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> _saveUserToFirestore(User user, String name) async {
    final authUser = AuthUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: name,
      photoURL: user.photoURL,
      role: 'user', // Default role
    );

    await _firestore.collection('users').doc(user.uid).set({
      ...authUser.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    if (displayName != null) {
      await user.updateDisplayName(displayName);
    }
    if (photoURL != null) {
      await user.updatePhotoURL(photoURL);
    }

    // Update Firestore
    final updates = <String, dynamic>{};
    if (displayName != null) updates['displayName'] = displayName;
    if (photoURL != null) updates['photoURL'] = photoURL;

    if (updates.isNotEmpty) {
      await _firestore.collection('users').doc(user.uid).update(updates);
    }
  }

  Future<String> uploadProfileImage(File file, String userId) async {
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('user_profiles')
        .child(userId)
        .child('profile.jpg');

    await storageRef.putFile(file);
    return await storageRef.getDownloadURL();
  }
}
