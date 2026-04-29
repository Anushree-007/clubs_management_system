import 'package:cloud_firestore/cloud_firestore.dart';

// This is the ClubModel class - it represents a club in our college club management app
class ClubModel {
  // The 'final' keyword means these values cannot be changed after the object is created
  // This makes the object safe and prevents accidental modifications
  
  // 'id' stores the unique identifier for this club (like a passport number for clubs)
  final String id;
  
  // 'name' stores the full name of the club (e.g., "National Service Scheme")
  final String name;
  
  // 'shortCode' stores an abbreviation of the club name (e.g., "NSS", "CSSI", "ROTARACT")
  final String shortCode;
  
  // 'domain' stores what category this club belongs to
  // It can be one of: "technical", "cultural", "social", or "sports"
  final String domain;
  
  // 'description' stores information about what this club does
  final String description;
  
  // 'status' stores whether the club is currently running or not
  // It can be either "active" or "inactive"
  final String status;
  
  // 'logoUrl' stores the URL (web address) of the club's logo image
  // The '?' means this field is optional (nullable) - it can be null/empty
  // Some clubs might not have a logo, so this can be empty
  final String? logoUrl;
  
  // 'currentTenureId' stores which tenure/year this club data belongs to
  // A tenure is like a school year (2023-2024, 2024-2025, etc.)
  final String currentTenureId;
  
  // 'facultyName' stores the full name of the faculty coordinator/advisor for this club
  final String facultyName;
  
  // 'facultyEmail' stores the email address of the faculty coordinator
  final String facultyEmail;
  
  // 'facultyPhone' stores the phone number of the faculty coordinator
  final String facultyPhone;
  
  // 'createdAt' stores when this club record was created (the date and time)
  final DateTime createdAt;

  // This is the constructor - it's like a blueprint that creates a new ClubModel object
  // All the parameters (id, name, shortCode, etc.) must be provided when creating a new object
  ClubModel({
    // The 'required' keyword means you MUST provide this parameter - it's mandatory
    required this.id,
    required this.name,
    required this.shortCode,
    required this.domain,
    required this.description,
    required this.status,
    // 'this.logoUrl' without 'required' means it's optional - you can skip it if you want
    this.logoUrl,
    required this.currentTenureId,
    required this.facultyName,
    required this.facultyEmail,
    required this.facultyPhone,
    required this.createdAt,
  });

  // This is a 'factory constructor' named 'fromJson' - it creates a ClubModel from Firestore data
  // 'factory' means this constructor can return an object in a special way
  // 'fromJson' is a common naming pattern for converting data INTO objects
  factory ClubModel.fromJson(Map<String, dynamic> json) {
    // The parameter 'json' is a Map (like a dictionary) containing all the club data from Firestore
    // 'Map<String, dynamic>' means: a map with String keys and values of any type
    
    // We create and return a new ClubModel object by extracting data from the json map
    return ClubModel(
      // Get 'id' from json - this should always be present after our Firestore fix
      id: json['id'] as String,
      
      // Get 'name' from json with null safety - defaults to 'Club' if missing
      name: (json['name'] as String?) ?? 'Club',
      
      // Get 'shortCode' from json with null safety - defaults to empty string if missing
      shortCode: (json['shortCode'] as String?) ?? '',
      
      // Get 'domain' from json with null safety - defaults to 'technical' if missing
      domain: (json['domain'] as String?) ?? 'technical',
      
      // Get 'description' from json with null safety - defaults to empty string if missing
      description: (json['description'] as String?) ?? '',
      
      // Get 'status' from json with null safety - defaults to 'active' if missing
      status: (json['status'] as String?) ?? 'active',
      
      // Get 'logoUrl' from json - it can be null, so we use 'as String?'
      // This allows the field to be null without any error
      logoUrl: json['logoUrl'] as String?,
      
      // Get 'currentTenureId' from json with null safety - defaults to empty string if missing
      currentTenureId: (json['currentTenureId'] as String?) ?? '',
      
      // Get 'facultyName' from json with null safety - defaults to empty string if missing
      facultyName: (json['facultyName'] as String?) ?? '',
      
      // Get 'facultyEmail' from json with null safety - defaults to empty string if missing
      facultyEmail: (json['facultyEmail'] as String?) ?? '',
      
      // Get 'facultyPhone' from json with null safety - defaults to empty string if missing
      facultyPhone: (json['facultyPhone'] as String?) ?? '',

      // Get 'createdAt' value from json and convert it safely to DateTime.
      // Firestore may return a Timestamp, a DateTime, or a String depending on how the data was written.
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) {
      return DateTime.now();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  // This is the 'toJson' method - it converts a ClubModel object back into a Map
  // This is used when saving club data to Firestore
  // 'toJson' is a common naming pattern for converting objects INTO data
  Map<String, dynamic> toJson() {
    // We return a Map with String keys and dynamic values
    // This is the exact format Firestore expects
    return {
      // 'id' key gets the value from 'this.id' (this object's id field)
      // We're putting all our object data into a map format for Firestore
      'id': id,
      
      // 'name' key gets the value from 'this.name'
      'name': name,
      
      // 'shortCode' key gets the value from 'this.shortCode'
      'shortCode': shortCode,
      
      // 'domain' key gets the value from 'this.domain'
      'domain': domain,
      
      // 'description' key gets the value from 'this.description'
      'description': description,
      
      // 'status' key gets the value from 'this.status'
      'status': status,
      
      // 'logoUrl' key gets the value from 'this.logoUrl'
      // This can be null for clubs without a logo, and Firestore handles null values fine
      'logoUrl': logoUrl,
      
      // 'currentTenureId' key gets the value from 'this.currentTenureId'
      'currentTenureId': currentTenureId,
      
      // 'facultyName' key gets the value from 'this.facultyName'
      'facultyName': facultyName,
      
      // 'facultyEmail' key gets the value from 'this.facultyEmail'
      'facultyEmail': facultyEmail,
      
      // 'facultyPhone' key gets the value from 'this.facultyPhone'
      'facultyPhone': facultyPhone,
      
      // 'createdAt' key stores the DateTime object
      // Firestore automatically converts DateTime objects to its timestamp format
      // So we just pass the DateTime and Firestore handles the conversion
      'createdAt': createdAt,
    };
  }
}
