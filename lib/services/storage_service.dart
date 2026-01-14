import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload image to Firebase Storage
  Future<String> uploadImage(File imageFile, String userId) async {
    try {
      // Create unique filename
      String fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Reference to storage location
      Reference ref = _storage.ref().child('posts/$fileName');

      // Upload file
      UploadTask uploadTask = ref.putFile(imageFile);

      // Wait for upload to complete
      TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Upload profile picture
  Future<String> uploadProfilePicture(File imageFile, String userId) async {
    try {
      String fileName = 'profile_$userId.jpg';
      Reference ref = _storage.ref().child('profile_pictures/$fileName');
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload profile picture: $e');
    }
  }

  // Delete image from storage
  Future<void> deleteImage(String imageUrl) async {
    try {
      Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }
}
