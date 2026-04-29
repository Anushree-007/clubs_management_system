// This file handles uploading files to Firebase Storage
// Firebase Storage is like Google Drive for your app
// Files are stored there and we save the download URL in Firestore

import 'dart:io'; // Needed to work with files on the device
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/widgets.dart';

class StorageService {

  // Get the Firebase Storage instance
  // This is our connection to the file storage system
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // -------------------------------------------------------
  // UPLOAD A FILE
  // Takes a local file from the phone and uploads it to Storage
  // Returns the download URL so we can save it in Firestore
  // -------------------------------------------------------
  Future<String> uploadFile({
    required File file,         // The actual file from the phone
    required String clubId,     // Which club this file belongs to
    required String fileName,   // What to name the file in Storage
  }) async {

    // Create a reference — think of this as the file path in Storage
    // Files are organized as: clubs/clubId/documents/fileName
    final ref = _storage
        .ref()
        .child('clubs')
        .child(clubId)
        .child('documents')
        .child(fileName);

    // Upload the file to that path
    // putFile() starts the upload and returns a task
    final uploadTask = await ref.putFile(file);

    // Once upload is done, get the public download URL
    // This URL is what we save in Firestore so we can open the file later
    final downloadUrl = await uploadTask.ref.getDownloadURL();

    // Return the URL
    return downloadUrl;
  }

  // -------------------------------------------------------
  // DELETE A FILE FROM STORAGE
  // Used when a document record is deleted
  // -------------------------------------------------------
  Future<void> deleteFile(String storageUrl) async {
    try {
      // Get a reference to the file using its URL
      final ref = _storage.refFromURL(storageUrl);
      // Delete the file
      await ref.delete();
    } catch (e) {
      // If file doesn't exist or already deleted just continue
      // We don't want to crash the app for this
      // debugPrint() is stripped from release builds automatically by the
      // Flutter compiler — print() is not, and it can expose internal paths
      // or error details in production logs.
      debugPrint('StorageService: file delete warning — $e');
    }
  }
}