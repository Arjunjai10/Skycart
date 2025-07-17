import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class UserService {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  // Constructor allows for dependency injection (useful for testing)
  UserService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  // Constants for collection and field names
  static const String _usersCollection = 'users';
  static const String _preferencesCollection = 'user_preferences';
  static const String _profileImagesPath = 'profile_images';

  /// Saves user data to Firestore
  Future<void> saveUserData(String uid, String name, String email) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).set({
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'selectedCities': ['London'], // Default city
        'profileImage': null,
      }, SetOptions(merge: true));
    } catch (e) {
      throw _handleFirestoreError('saving user data', e);
    }
  }

  /// Gets user data from Firestore
  Future<Map<String, dynamic>> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();
      return doc.data() ?? {};
    } catch (e) {
      throw _handleFirestoreError('loading user data', e);
    }
  }

  /// Updates user profile information
  Future<void> updateProfile(String uid, String name, String email) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).update({
        'name': name,
        'email': email,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw _handleFirestoreError('updating profile', e);
    }
  }

  /// Updates selected cities for a user
  Future<void> updateSelectedCities(String uid, List<String> cities) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).update({
        'selectedCities': cities,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw _handleFirestoreError('updating selected cities', e);
    }
  }

  /// Uploads profile image to Firebase Storage
  Future<String> uploadProfileImage(String uid, String filePath) async {
    try {
      final ref = _storage.ref().child('$_profileImagesPath/$uid.jpg');
      final uploadTask = ref.putFile(File(filePath));
      final snapshot = await uploadTask.whenComplete(() {});

      if (snapshot.state != TaskState.success) {
        throw Exception('Upload failed with state: ${snapshot.state}');
      }

      return await ref.getDownloadURL();
    } catch (e) {
      throw _handleStorageError('uploading profile image', e);
    }
  }

  /// Updates profile image URL in Firestore
  Future<void> updateProfileImageUrl(String uid, String imageUrl) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).update({
        'profileImage': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw _handleFirestoreError('updating profile image URL', e);
    }
  }

  /// Gets user preferences
  Future<Map<String, dynamic>> getUserPreferences(String uid) async {
    try {
      final doc = await _firestore.collection(_preferencesCollection).doc(uid).get();
      return doc.exists
          ? {'isCelsius': doc.data()?['isCelsius'] ?? true}
          : {'isCelsius': true};
    } catch (e) {
      throw _handleFirestoreError('loading preferences', e);
    }
  }

  /// Updates user preferences
  Future<void> updatePreferences({
    required String uid,
    required bool isCelsius,
  }) async {
    try {
      await _firestore.collection(_preferencesCollection).doc(uid).set({
        'isCelsius': isCelsius,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw _handleFirestoreError('updating preferences', e);
    }
  }

  /// Signs out the current user
  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: ${e.toString()}');
    }
  }

  // Error handling helpers
  Exception _handleFirestoreError(String operation, dynamic error) {
    print('Error $operation: $error');
    return Exception('Failed to $operation. Please try again.');
  }

  Exception _handleStorageError(String operation, dynamic error) {
    print('Error $operation: $error');
    return Exception('Failed to $operation. Please try again.');
  }
}