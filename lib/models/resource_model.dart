// This file defines what a "Resource" looks like in our app
// A resource is anything the college owns that clubs can book
// Examples: Seminar Hall A, Auditorium, Projector, Sound System

import 'package:cloud_firestore/cloud_firestore.dart';

class ResourceModel {

  final String id;        // Unique ID of this resource
  final String name;      // Name e.g. "Seminar Hall A"
  final String type;      // Type: "hall", "classroom", "equipment"
  final int capacity;     // How many people it can hold (0 if not applicable)
  final String status;    // "free" or "occupied"

  ResourceModel({
    required this.id,
    required this.name,
    required this.type,
    required this.capacity,
    required this.status,
  });

  // Build a ResourceModel from a Firestore document
  factory ResourceModel.fromJson(String id, Map<String, dynamic> json) {
    return ResourceModel(
      id: id,
      name: json['name'] ?? '',
      type: json['type'] ?? 'hall',
      // Convert to int safely
      capacity: (json['capacity'] ?? 0).toInt(),
      status: json['status'] ?? 'free',
    );
  }

  // Convert ResourceModel to a Map to save in Firestore
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'capacity': capacity,
      'status': status,
    };
  }
}