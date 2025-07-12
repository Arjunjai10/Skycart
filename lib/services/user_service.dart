import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> saveUserData(String uid, String name, String email) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'selectedCities': ['London'],
        'profileImage': null,
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error saving user data: $e');
      throw Exception('Failed to save user data');
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

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

  Future<void> updateProfile(String uid, String name, String email) async {
    await _firestore.collection('users').doc(uid).update({
      'name': name,
      'email': email,
    });
  }

  Future<void> updateSelectedCities(String uid, List<String> cities) async {
    await _firestore.collection('users').doc(uid).update({
      'selectedCities': cities,
    });
  }

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

  Future<void> updateProfileImageUrl(String uid, String imageUrl) async {
    await _firestore.collection('users').doc(uid).update({
      'profileImage': imageUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }


  Future<Map<String, dynamic>> getUserPreferences(String uid) async {
    DocumentSnapshot doc = await _firestore.collection('user_preferences').doc(uid).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'isCelsius': data['isCelsius'] ?? true,
      };
    }
    return {'isCelsius': true};
  }


  Future<void> updatePreferences({required String uid, required bool isCelsius}) async {
    await _firestore.collection('user_preferences').doc(uid).set({
      'isCelsius': isCelsius,
    }, SetOptions(merge: true));
  }
}
