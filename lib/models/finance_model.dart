// This file defines what a "Finance record" looks like in our app
// Every event has one finance record attached to it
// It tracks all the money related information for that event

import 'package:cloud_firestore/cloud_firestore.dart';

class FinanceModel {

  final String id;              // Unique ID of this finance record
  final String eventId;         // Which event this finance belongs to
  final String clubId;          // Which club this finance belongs to
  final double totalBudget;     // Total money allocated for the event
  final double totalExpenses;   // Total money actually spent
  final double netBalance;      // totalBudget minus totalExpenses
  final double totalSponsorship;// Total money received from all sponsors
  final String notes;           // Any extra notes about the finance
  final List<Map<String, dynamic>> breakdown; // List of expense categories
  // breakdown example: [{category: 'Food', amount: 5000, description: 'Snacks'}]

  FinanceModel({
    required this.id,
    required this.eventId,
    required this.clubId,
    required this.totalBudget,
    required this.totalExpenses,
    required this.netBalance,
    required this.totalSponsorship,
    required this.notes,
    required this.breakdown,
  });

  // Build a FinanceModel from a Firestore document
  factory FinanceModel.fromJson(String id, Map<String, dynamic> json) {
    return FinanceModel(
      id: id,
      eventId: json['eventId'] ?? '',
      clubId: json['clubId'] ?? '',
      // Convert to double safely — Firestore may return int or double
      totalBudget: (json['totalBudget'] ?? 0).toDouble(),
      totalExpenses: (json['totalExpenses'] ?? 0).toDouble(),
      netBalance: (json['netBalance'] ?? 0).toDouble(),
      totalSponsorship: (json['totalSponsorship'] ?? 0).toDouble(),
      notes: json['notes'] ?? '',
      // Cast the breakdown list safely
      // Each item in the list is a Map with category, amount, description
      breakdown: List<Map<String, dynamic>>.from(
        json['breakdown'] ?? [],
      ),
    );
  }

  // Convert FinanceModel back to a Map to save in Firestore
  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'clubId': clubId,
      'totalBudget': totalBudget,
      'totalExpenses': totalExpenses,
      'netBalance': netBalance,
      'totalSponsorship': totalSponsorship,
      'notes': notes,
      'breakdown': breakdown,
    };
  }
}