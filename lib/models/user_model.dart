import 'package:cloud_firestore/cloud_firestore.dart';

// This is the UserModel class - it represents a user in our Firebase app
class UserModel {
  // The 'final' keyword means these values cannot be changed after the object is created
  // This makes the object safe and prevents accidental modifications
  
  // 'id' stores the unique identifier for this user (like a passport number for users)
  final String id;
  
  // 'name' stores the full name of the user
  final String name;
  
  // 'email' stores the user's email address for login and communication
  final String email;
  
  // 'role' stores what type of user this is - either 'teacher' or 'chairperson'
  // This determines what permissions and features the user can access
  final String role;
  
  // 'phone' stores the user's phone number for contact purposes
  final String phone;
  
  // 'clubId' stores which club this user manages - only chairpersons have this
  // The '?' means this field is optional (nullable) - it can be null/empty
  // Teachers don't have a club, so their clubId is null
  final String? clubId;
  
  // 'createdAt' stores when this user account was created (the date and time)
  final DateTime createdAt;

  // This is the constructor - it's like a blueprint that creates a new UserModel object
  // All the parameters (id, name, email, etc.) must be provided when creating a new object
  UserModel({
    // The 'required' keyword means you MUST provide this parameter - it's mandatory
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.phone,
    // 'this.clubId' without 'required' means it's optional - you can skip it if you want
    this.clubId,
    required this.createdAt,
  });

  // This is a 'factory constructor' named 'fromJson' - it creates a UserModel from Firestore data
  // 'factory' means this constructor can return an object in a special way
  // 'fromJson' is a common naming pattern for converting data INTO objects
  factory UserModel.fromJson(Map<String, dynamic> json) {
    // The parameter 'json' is a Map (like a dictionary) containing all the user data from Firestore
    // 'Map<String, dynamic>' means: a map with String keys and values of any type
    
    // We create and return a new UserModel object by extracting data from the json map
    return UserModel(
      // Get 'id' from json - this should always be present after our Firestore fix
      id: json['id'] as String,
      
      // Get 'name' from json with null safety - defaults to 'User' if missing
      name: (json['name'] as String?) ?? 'User',
      
      // Get 'email' from json with null safety - defaults to empty string if missing
      email: (json['email'] as String?) ?? '',
      
      // Get 'role' from json with null safety - defaults to 'teacher' if missing
      // This will be either 'teacher' or 'chairperson'
      role: (json['role'] as String?) ?? 'teacher',
      
      // Get 'phone' from json with null safety - defaults to empty string if missing
      phone: (json['phone'] as String?) ?? '',
      
      // Get the 'clubId' value from json
      // Since it can be null, we use 'as String?' to allow null values
      // If 'clubId' doesn't exist in json, this will be null (no error)
      clubId: json['clubId'] as String?,
      
      // Get the 'createdAt' value from json and convert it safely to DateTime.
      // Firestore may return a Timestamp, a DateTime, or a String depending
      // on how the value was written, so we parse safely.
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  // This is the 'toJson' method - it converts a UserModel object back into a Map
  // This is used when saving user data to Firestore
  // 'toJson' is a common naming pattern for converting objects INTO data
  Map<String, dynamic> toJson() {
    // We return a Map with String keys and dynamic values
    // This is the exact format Firestore expects
    return {
      // 'id' key gets the value from 'this.id' (this object's id field)
      // We're putting all our object data into a map format
      'id': id,
      
      // 'name' key gets the value from 'this.name'
      'name': name,
      
      // 'email' key gets the value from 'this.email'
      'email': email,
      
      // 'role' key gets the value from 'this.role'
      'role': role,
      
      // 'phone' key gets the value from 'this.phone'
      'phone': phone,
      
      // 'clubId' key gets the value from 'this.clubId'
      // This can be null for teachers, and Firestore handles null values fine
      'clubId': clubId,
      
      // 'createdAt' key stores the DateTime object
      // Firestore automatically converts DateTime objects to its timestamp format
      // So we just pass the DateTime and Firestore handles the conversion
      'createdAt': createdAt,
    };
  }
}
