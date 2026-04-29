// This file defines what "Ticket info" looks like for an event
// Each event has one ticket record
// It tracks ticket price, how many were sold, and total revenue

import 'package:cloud_firestore/cloud_firestore.dart';

class TicketModel {

  final String id;              // Unique ID of this ticket record
  final String eventId;         // Which event these tickets belong to
  final String clubId;          // Which club this belongs to
  final double ticketPrice;     // Price of one ticket in rupees
  final int ticketsSold;        // How many tickets were sold
  final double totalRevenue;    // ticketPrice x ticketsSold
  final bool vierpVerified;     // Was this verified through VIERP system
  final String manualNote;      // Manual note if VIERP not available

  TicketModel({
    required this.id,
    required this.eventId,
    required this.clubId,
    required this.ticketPrice,
    required this.ticketsSold,
    required this.totalRevenue,
    required this.vierpVerified,
    required this.manualNote,
  });

  // Build a TicketModel from Firestore document data
  factory TicketModel.fromJson(String id, Map<String, dynamic> json) {
    return TicketModel(
      id: id,
      eventId: json['eventId'] ?? '',
      clubId: json['clubId'] ?? '',
      ticketPrice: (json['ticketPrice'] ?? 0).toDouble(),
      ticketsSold: (json['ticketsSold'] ?? 0).toInt(),
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      vierpVerified: json['vierpVerified'] ?? false,
      manualNote: json['manualNote'] ?? '',
    );
  }

  // Convert TicketModel to a Map to save in Firestore
  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'clubId': clubId,
      'ticketPrice': ticketPrice,
      'ticketsSold': ticketsSold,
      'totalRevenue': totalRevenue,
      'vierpVerified': vierpVerified,
      'manualNote': manualNote,
    };
  }
}