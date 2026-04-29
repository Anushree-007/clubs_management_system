// This file defines what a "Booking request" looks like
// When a chairperson wants to use a resource for an event
// they create a booking request which a teacher approves or rejects

import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {

  final String id;            // Unique ID of this booking
  final String resourceId;    // Which resource is being booked
  final String resourceName;  // Name of the resource (stored for easy display)
  final String clubId;        // Which club is requesting
  final String clubName;      // Club name (stored for easy display)
  final String eventId;       // Which event needs this resource
  final String eventName;     // Event name (stored for easy display)
  final String requestedBy;   // User ID of the chairperson who requested
  final DateTime startTime;   // When the booking starts
  final DateTime endTime;     // When the booking ends
  final String status;        // "pending", "approved", "rejected"
  final String approvedBy;    // User ID of teacher who approved or rejected
  final String notes;         // Any extra notes from the requester
  final DateTime createdAt;   // When the request was made

  BookingModel({
    required this.id,
    required this.resourceId,
    required this.resourceName,
    required this.clubId,
    required this.clubName,
    required this.eventId,
    required this.eventName,
    required this.requestedBy,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.approvedBy,
    required this.notes,
    required this.createdAt,
  });

  // Build a BookingModel from a Firestore document
  factory BookingModel.fromJson(String id, Map<String, dynamic> json) {
    return BookingModel(
      id: id,
      resourceId: json['resourceId'] ?? '',
      resourceName: json['resourceName'] ?? '',
      clubId: json['clubId'] ?? '',
      clubName: json['clubName'] ?? '',
      eventId: json['eventId'] ?? '',
      eventName: json['eventName'] ?? '',
      requestedBy: json['requestedBy'] ?? '',
      // Convert Timestamps to DateTime
      startTime: _parseDate(json['startTime']),
      endTime: _parseDate(json['endTime']),
      status: json['status'] ?? 'pending',
      approvedBy: json['approvedBy'] ?? '',
      notes: json['notes'] ?? '',
      createdAt: _parseDate(json['createdAt']),
    );
  }

  // Convert BookingModel to a Map to save in Firestore
  Map<String, dynamic> toJson() {
    return {
      'resourceId': resourceId,
      'resourceName': resourceName,
      'clubId': clubId,
      'clubName': clubName,
      'eventId': eventId,
      'eventName': eventName,
      'requestedBy': requestedBy,
      'startTime': startTime,
      'endTime': endTime,
      'status': status,
      'approvedBy': approvedBy,
      'notes': notes,
      'createdAt': createdAt,
    };
  }
  static DateTime _parseDate(dynamic value) {
  if (value == null) return DateTime.now();
  try { return value.toDate(); } catch (_) {}
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
}
}