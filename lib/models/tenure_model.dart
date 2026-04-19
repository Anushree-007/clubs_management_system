// This is the TenureModel class - it represents a tenure (term/year) for a club
// A tenure is a period when specific people hold leadership positions in the club
class TenureModel {
  // The 'final' keyword means these values cannot be changed after the object is created
  // This makes the object safe and prevents accidental modifications
  
  // 'id' stores the unique identifier for this tenure
  final String id;
  
  // 'clubId' stores which club this tenure belongs to
  // This links the tenure to a specific club
  final String clubId;
  
  // 'startDate' stores when this tenure started (the beginning date)
  final DateTime startDate;
  
  // 'endDate' stores when this tenure ended (the ending date)
  // The '?' means this field is optional (nullable) - it can be null/empty
  // If a tenure is still ongoing, endDate will be null (not finished yet)
  final DateTime? endDate;
  
  // 'isActive' stores whether this tenure is currently active or finished
  // true = currently active, false = finished/ended
  final bool isActive;
  
  // 'hierarchy' stores the leadership structure for this tenure
  // It's a List (array) of Maps (dictionaries)
  // Each map has two keys: 'position' (like "President") and 'memberName' (like "John Doe")
  // Example: [{'position': 'President', 'memberName': 'John Doe'}, {'position': 'Vice President', 'memberName': 'Jane Smith'}]
  final List<Map<String, String>> hierarchy;

  // This is the constructor - it's like a blueprint that creates a new TenureModel object
  // All the parameters must be provided when creating a new object
  TenureModel({
    // The 'required' keyword means you MUST provide this parameter - it's mandatory
    required this.id,
    required this.clubId,
    required this.startDate,
    // 'this.endDate' without 'required' means it's optional - you can skip it if you want
    // This is because active tenures don't have an end date yet
    this.endDate,
    required this.isActive,
    required this.hierarchy,
  });

  // This is a 'factory constructor' named 'fromJson' - it creates a TenureModel from Firestore data
  // 'factory' means this constructor can return an object in a special way
  // 'fromJson' is a common naming pattern for converting data INTO objects
  factory TenureModel.fromJson(Map<String, dynamic> json) {
    // The parameter 'json' is a Map (like a dictionary) containing all the tenure data from Firestore
    // 'Map<String, dynamic>' means: a map with String keys and values of any type
    
    // We create and return a new TenureModel object by extracting data from the json map
    return TenureModel(
      // Get 'id' from json - this should always be present after our Firestore fix
      id: json['id'] as String,
      
      // Get 'clubId' from json with null safety - defaults to empty string if missing
      clubId: (json['clubId'] as String?) ?? '',
      
      // Get 'startDate' value from json - it's stored as a timestamp in Firestore
      // Firestore stores timestamps as special objects, so we need to convert them
      // We use '?.toDate()' to safely convert the timestamp to a DateTime object
      // The '?.' means: only call toDate() if the value is not null
      // If null, we use DateTime.now() as the default start date
      startDate: (json['startDate'] as dynamic)?.toDate() ?? DateTime.now(),
      
      // Get 'endDate' value from json - it's also stored as a timestamp in Firestore
      // Since endDate can be null (for active tenures), we use '?.toDate()' 
      // This safely converts the timestamp if it exists, or returns null if it doesn't
      // The result will be null if the tenure is still active (no end date yet)
      endDate: (json['endDate'] as dynamic)?.toDate(),
      
      // Get 'isActive' from json with null safety - defaults to true if missing
      // The 'as bool?' safely casts to a boolean, and '?? true' defaults to true if null
      isActive: (json['isActive'] as bool?) ?? true,
      
      // Get 'hierarchy' from json - it's a list of maps
      // 'as List?' safely casts to a List if it exists
      // 'map((item) => ...)' converts each item in the list using the function
      // 'Map.from(item as Map)' creates a new map and safely converts to Map<String, String>
      // '.cast<String, String>()' tells Dart to treat the keys and values as Strings
      // '.toList()' converts the result back to a List
      // If 'hierarchy' doesn't exist or is null, we use '?? []' to default to an empty list
      hierarchy: (json['hierarchy'] as List?)
              ?.map((item) => Map<String, String>.from(item as Map).cast<String, String>())
              .toList() ??
          [],
    );
  }

  // This is the 'toJson' method - it converts a TenureModel object back into a Map
  // This is used when saving tenure data to Firestore
  // 'toJson' is a common naming pattern for converting objects INTO data
  Map<String, dynamic> toJson() {
    // We return a Map with String keys and dynamic values
    // This is the exact format Firestore expects
    return {
      // 'id' key gets the value from 'this.id' (this object's id field)
      // We're putting all our object data into a map format for Firestore
      'id': id,
      
      // 'clubId' key gets the value from 'this.clubId'
      'clubId': clubId,
      
      // 'startDate' key stores the DateTime object
      // Firestore automatically converts DateTime objects to its timestamp format
      // So we just pass the DateTime and Firestore handles the conversion
      'startDate': startDate,
      
      // 'endDate' key stores the DateTime object (or null if tenure is still active)
      // Firestore handles null values fine, so we can save null here
      'endDate': endDate,
      
      // 'isActive' key gets the value from 'this.isActive' (boolean true or false)
      'isActive': isActive,
      
      // 'hierarchy' key stores the list of maps
      // Each map contains the position (like "President") and member name
      // This is exactly the format Firestore expects
      'hierarchy': hierarchy,
    };
  }
}
