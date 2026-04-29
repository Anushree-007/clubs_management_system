// This file defines what a "Sponsor" looks like in our app
// Each event can have multiple sponsors
// Each sponsor is stored as a separate document in Firestore

import 'package:cloud_firestore/cloud_firestore.dart';

class SponsorModel {

  final String id;          // Unique ID of this sponsor record
  final String eventId;     // Which event this sponsor is associated with
  final String clubId;      // Which club this belongs to
  final String name;        // Sponsor name e.g. "TechCorp Pvt Ltd"
  final double amount;      // How much money they contributed
  final String notes;       // Any extra notes — optional

  SponsorModel({
    required this.id,
    required this.eventId,
    required this.clubId,
    required this.name,
    required this.amount,
    required this.notes,
  });

  // Build a SponsorModel from Firestore document data
  factory SponsorModel.fromJson(String id, Map<String, dynamic> json) {
    return SponsorModel(
      id: id,
      eventId: json['eventId'] ?? '',
      clubId: json['clubId'] ?? '',
      name: json['name'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      notes: json['notes'] ?? '',
    );
  }

  // Convert SponsorModel to a Map to save in Firestore
  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'clubId': clubId,
      'name': name,
      'amount': amount,
      'notes': notes,
    };
  }
}