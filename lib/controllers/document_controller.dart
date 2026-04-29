// This is the Document Controller
// It handles uploading, fetching, and deleting documents
// It uses both FirestoreService (for metadata) and StorageService (for files)

import 'dart:io'; // For working with local phone files
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart'; // For picking files from phone
import 'package:club_management_app/models/document_model.dart';
import 'package:club_management_app/services/firestore_service.dart';
import 'package:club_management_app/services/storage_service.dart';
import 'package:club_management_app/controllers/auth_controller.dart';

class DocumentController extends GetxController {

  // Database helper for saving metadata
  final FirestoreService _firestoreService = FirestoreService();

  // Storage helper for uploading actual files
  final StorageService _storageService = StorageService();

  // Reactive list of all documents for the current club
  final RxList<DocumentModel> documents = <DocumentModel>[].obs;

  // Loading state
  final RxBool isLoading = false.obs;

  // Upload progress — shows how much of the file has uploaded
  final RxDouble uploadProgress = 0.0.obs;

  // -------------------------------------------------------
  // FETCH DOCUMENTS FOR A CLUB
  // -------------------------------------------------------
  Future<void> fetchDocuments(String clubId, {String? eventId}) async {
    try {
      isLoading.value = true;
      final result = await _firestoreService.getDocuments(
        clubId,
        eventId: eventId,
      );
      documents.assignAll(result);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not load documents: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // -------------------------------------------------------
  // PICK AND UPLOAD A FILE
  // Opens file picker, user selects a file
  // We upload it to Storage then save metadata in Firestore
  // -------------------------------------------------------
  Future<void> pickAndUploadFile(String clubId, {String eventId = ''}) async {
    try {
      // Open the file picker
      // allowMultiple: false means user picks one file at a time
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        // Allow these file types
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'jpg', 'jpeg', 'png'],
      );

      // If user cancelled the picker, stop here
      if (result == null || result.files.isEmpty) return;

      isLoading.value = true;

      // Get the picked file
      final pickedFile = result.files.first;

      // Make sure the file path exists on the device
      if (pickedFile.path == null) return;

      // Create a File object from the path
      final file = File(pickedFile.path!);

      // Get the file name
      final fileName = pickedFile.name;

      // Determine file type from extension
      final extension = fileName.split('.').last.toLowerCase();
      String fileType;
      if (extension == 'pdf') {
        fileType = 'pdf';
      } else if (['jpg', 'jpeg', 'png'].contains(extension)) {
        fileType = 'image';
      } else if (['doc', 'docx'].contains(extension)) {
        fileType = 'docx';
      } else if (['xls', 'xlsx'].contains(extension)) {
        fileType = 'xlsx';
      } else {
        fileType = 'other';
      }

      // Upload the file to Firebase Storage
      final downloadUrl = await _storageService.uploadFile(
        file: file,
        clubId: clubId,
        // Add timestamp to filename to avoid duplicates
        fileName: '${DateTime.now().millisecondsSinceEpoch}_$fileName',
      );

      // Get the current user ID
      final authController = Get.find<AuthController>();
      final userId = authController.currentUser.value?.id ?? '';

      // Build the DocumentModel to save in Firestore
      final document = DocumentModel(
        id: '',
        clubId: clubId,
        eventId: eventId,
        name: fileName,
        fileType: fileType,
        storageUrl: downloadUrl,
        uploadedBy: userId,
        uploadedAt: DateTime.now(),
      );

      // Save the document metadata to Firestore
      await _firestoreService.addDocument(document);

      // Refresh the documents list
      await fetchDocuments(clubId, eventId: eventId);

      Get.snackbar(
        'Success',
        'File uploaded successfully',
        snackPosition: SnackPosition.BOTTOM,
      );

    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not upload file: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // -------------------------------------------------------
  // DELETE A DOCUMENT
  // Deletes both the file from Storage and metadata from Firestore
  // -------------------------------------------------------
  Future<void> deleteDocument(
      DocumentModel document, String clubId) async {
    try {
      // Delete the actual file from Firebase Storage
      await _storageService.deleteFile(document.storageUrl);

      // Delete the metadata record from Firestore
      await _firestoreService.deleteDocument(document.id);

      // Refresh the list
      await fetchDocuments(clubId);

      Get.snackbar(
        'Deleted',
        'Document deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
      );

    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not delete document: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // -------------------------------------------------------
  // GETTER — Get icon for each file type
  // Used in the documents list screen
  // -------------------------------------------------------
  String getFileTypeLabel(String fileType) {
    switch (fileType) {
      case 'pdf':
        return 'PDF';
      case 'image':
        return 'Image';
      case 'docx':
        return 'Word';
      case 'xlsx':
        return 'Excel';
      default:
        return 'File';
    }
  }
}