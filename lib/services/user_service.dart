import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Save user data after registration
  Future<void> saveUserData(String uid, String name, String email) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'selectedCities': ['London'], // Default city
        'profileImage': null,
      }, SetOptions(merge: true)); // Use merge to avoid overwriting existing data
    } catch (e) {
      print('Error saving user data: $e');
      throw Exception('Failed to save user data');
    }
  }

  // Sign out user
  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  // Get user data
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
      return {};
    } catch (e) {
      print('Error getting user data: $e');
      throw Exception('Failed to load user data');
    }
  }

  // Update user profile
  Future<void> updateProfile(String uid, String name, String email) async {
    await _firestore.collection('users').doc(uid).update({
      'name': name,
      'email': email,
    });
  }

  // Update selected cities
  Future<void> updateSelectedCities(String uid, List<String> cities) async {
    await _firestore.collection('users').doc(uid).update({
      'selectedCities': cities,
    });
  }

  // Upload profile image and return download URL
  Future<String> uploadProfileImage(String uid, String filePath) async {
    try {
      final ref = _storage.ref().child('profile_images/$uid.jpg');
      final uploadTask = ref.putFile(File(filePath));
      final snapshot = await uploadTask.whenComplete(() {});
      if (snapshot.state == TaskState.success) {
        return await ref.getDownloadURL();
      } else {
        throw Exception('Upload failed');
      }
    } catch (e) {
      print('Error uploading image: $e');
      throw Exception('Failed to upload image');
    }
  }

  // Update Firestore with profile image URL
  Future<void> updateProfileImageUrl(String uid, String imageUrl) async {
    await _firestore.collection('users').doc(uid).update({
      'profileImage': imageUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }


  // Get user preferences
  Future<Map<String, dynamic>> getUserPreferences(String uid) async {
    DocumentSnapshot doc = await _firestore.collection('user_preferences').doc(uid).get();
    if (doc.exists) {
      return doc.data() as Map<String, dynamic>;
    }
    return {
      'isDarkMode': false,
      'isCelsius': true,
    };
  }

  // Update user preferences
  Future<void> updatePreferences(String uid, bool isDarkMode, bool isCelsius) async {
    await _firestore.collection('user_preferences').doc(uid).set({
      'isDarkMode': isDarkMode,
      'isCelsius': isCelsius,
    }, SetOptions(merge: true));
  }
}
