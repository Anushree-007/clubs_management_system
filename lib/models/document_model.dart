// This file defines what a "Document" looks like in our app
// A document is any file uploaded to the app
// Examples: event report PDF, sponsorship letter, photos

import 'package:cloud_firestore/cloud_firestore.dart';

class DocumentModel {

  final String id;          // Unique ID of this document record
  final String clubId;      // Which club this document belongs to
  final String eventId;     // Which event — empty string if not event specific
  final String name;        // Display name e.g. "Sponsorship Letter"
  final String fileType;    // "pdf", "image", "docx", "xlsx", "other"
  final String storageUrl;  // The download URL from Firebase Storage
  final String uploadedBy;  // User ID of who uploaded it
  final DateTime uploadedAt; // When it was uploaded

  DocumentModel({
    required this.id,
    required this.clubId,
    required this.eventId,
    required this.name,
    required this.fileType,
    required this.storageUrl,
    required this.uploadedBy,
    required this.uploadedAt,
  });

  // Build a DocumentModel from Firestore data
  factory DocumentModel.fromJson(String id, Map<String, dynamic> json) {
    return DocumentModel(
      id: id,
      clubId: json['clubId'] ?? '',
      eventId: json['eventId'] ?? '',
      name: json['name'] ?? '',
      fileType: json['fileType'] ?? 'other',
      storageUrl: json['storageUrl'] ?? '',
      uploadedBy: json['uploadedBy'] ?? '',
      // Convert Timestamp to DateTime
      uploadedAt: _parseDate(json['uploadedAt']),
    );
  }

  // Convert DocumentModel to Map to save in Firestore
  Map<String, dynamic> toJson() {
    return {
      'clubId': clubId,
      'eventId': eventId,
      'name': name,
      'fileType': fileType,
      'storageUrl': storageUrl,
      'uploadedBy': uploadedBy,
      'uploadedAt': uploadedAt,
    };
  }
static DateTime _parseDate(dynamic value) {
  if (value == null) return DateTime.now();
  try { return value.toDate(); } catch (_) {}
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
}
}