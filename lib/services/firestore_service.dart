// Import the Cloud Firestore package - this lets us read/write data to Firestore database
import 'package:cloud_firestore/cloud_firestore.dart';

// Import the UserModel class - we'll use this to convert Firestore data into UserModel objects
import 'package:club_management_app/models/user_model.dart';

// Import the ClubModel class - we'll use this to convert Firestore club data into ClubModel objects
import 'package:club_management_app/models/club_model.dart';

// Import the MemberModel class - we'll use this to convert Firestore member data into MemberModel objects
import 'package:club_management_app/models/member_model.dart';

// Import the TenureModel class - we'll use this to convert Firestore tenure data into TenureModel objects
import 'package:club_management_app/models/tenure_model.dart';

// Import the EventModel class - we need this for the event methods below
import 'package:club_management_app/models/event_model.dart';

// This is the FirestoreService class - it handles all database operations with Firestore
// We put all database-related code here to keep it organized and reusable across the app
class FirestoreService {
  // This is a private variable that holds a reference to the Firestore database
  // The underscore (_) at the start means it's private - only this class can use it
  // We use 'late' keyword because we'll initialize it immediately after declaring it
  late final FirebaseFirestore _firestore;

  // This is the constructor - it runs when we create a new FirestoreService object
  // The constructor initializes Firestore when the class is first created
  FirestoreService() {
    // 'FirebaseFirestore.instance' gets the Firestore database instance
    // This is a singleton, meaning there's only one instance for the whole app
    _firestore = FirebaseFirestore.instance;
  }

  // This method fetches a user document from Firestore and converts it to a UserModel
  // It takes one parameter: userId (the unique identifier of the user)
  // 'Future<UserModel>' means this method takes time to complete (it's async)
  // and will eventually return a UserModel object when done
  Future<UserModel> getUser(String userId) async {
    // The 'async' keyword means this method can do slow operations without blocking the UI
    // 'try' block - we attempt to fetch data from Firestore (which might fail)
    try {
      // '_firestore.collection('users')' - we access the 'users' collection in Firestore
      // '.doc(userId)' - we specify which document we want (identified by userId)
      // '.get()' - we fetch the document from Firestore
      // 'await' waits for Firestore to respond with the document before continuing
      DocumentSnapshot documentSnapshot =
          await _firestore.collection('users').doc(userId).get();

      // Check if the document exists in Firestore
      // '.exists' is a boolean property - true if the document was found, false if not
      if (documentSnapshot.exists) {
        // If the document exists, we extract the data as a Map
        // '.data() as Map<String, dynamic>' converts the document data into a Map
        // A Map is like a dictionary - it has keys and values
        Map<String, dynamic> data =
            documentSnapshot.data() as Map<String, dynamic>;

        // Add the document ID to the data map since Firestore doesn't include it automatically
        data['id'] = documentSnapshot.id;

        // Now we convert the Map data into a UserModel object
        // 'UserModel.fromJson(data)' uses the fromJson factory constructor
        // It takes the Map and creates a proper UserModel object from it
        UserModel user = UserModel.fromJson(data);

        // Return the newly created UserModel object to whoever called this method
        return user;
      }
      // If the document doesn't exist, throw an exception to indicate there's an error
      else {
        // 'throw Exception()' creates and throws an error/exception
        // This tells the calling code that something went wrong
        // The error message helps developers understand what happened
        throw Exception('User with ID: $userId not found');
      }
    }
    // 'catch' block - if something goes wrong (network error, invalid data, etc.)
    catch (e) {
      // If there's any error, re-throw it so the calling code can handle it
      // 're-throw' means we throw the error again for the caller to catch
      rethrow;
    }
  }

  // This method fetches ALL clubs from the 'clubs' collection in Firestore
  // It returns a List (array) of ClubModel objects
  // 'Future<List<ClubModel>>' means this method takes time to complete (it's async)
  // and will eventually return a list of ClubModel objects when done
  Future<List<ClubModel>> getAllClubs() async {
    // The 'async' keyword means this method can do slow operations without blocking the UI
    // 'try' block - we attempt to fetch data from Firestore (which might fail)
    try {
      // '_firestore.collection('clubs')' - we access the 'clubs' collection in Firestore
      // '.get()' - we fetch ALL documents from this collection at once
      // 'await' waits for Firestore to respond with all the documents before continuing
      QuerySnapshot querySnapshot = await _firestore.collection('clubs').get();

      // '.docs' is a list that contains all the documents we fetched
      // '.map((doc) => ...)' goes through each document one by one and transforms it
      // For each document, we extract the data and convert it to a ClubModel object
      List<ClubModel> clubs = querySnapshot.docs
          // '.map' takes each document and converts it
          .map((doc) {
            // '...doc.data() as Map' gets the data from this document as a Map
            // 'Map<String, dynamic>' means a map with String keys and any type of value
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            
            // Add the document ID to the data map since Firestore doesn't include it automatically
            data['id'] = doc.id;
            
            // 'ClubModel.fromJson(data)' uses the fromJson factory constructor
            // It converts the Map data into a proper ClubModel object
            return ClubModel.fromJson(data);
          })
          // '.toList()' converts the mapped results into a List
          .toList();

      // Return the list of all ClubModel objects to whoever called this method
      return clubs;
    }
    // 'catch' block - if something goes wrong (network error, invalid data, etc.)
    catch (e) {
      // If there's any error, re-throw it so the calling code can handle it
      rethrow;
    }
  }

  // This method fetches ONE specific club by its ID from the 'clubs' collection
  // It takes one parameter: clubId (the unique identifier of the club)
  // 'Future<ClubModel>' means this method takes time to complete (it's async)
  // and will eventually return a single ClubModel object when done
  Future<ClubModel> getClubById(String clubId) async {
    // The 'async' keyword means this method can do slow operations without blocking the UI
    // 'try' block - we attempt to fetch data from Firestore (which might fail)
    try {
      // '_firestore.collection('clubs')' - we access the 'clubs' collection in Firestore
      // '.doc(clubId)' - we specify which document we want (identified by clubId)
      // '.get()' - we fetch that specific document from Firestore
      // 'await' waits for Firestore to respond with the document before continuing
      DocumentSnapshot documentSnapshot =
          await _firestore.collection('clubs').doc(clubId).get();

      // Check if the document exists in Firestore
      // '.exists' is a boolean property - true if the document was found, false if not
      if (documentSnapshot.exists) {
        // If the document exists, we extract the data as a Map
        // '.data() as Map<String, dynamic>' converts the document data into a Map
        Map<String, dynamic> data =
            documentSnapshot.data() as Map<String, dynamic>;

        // Add the document ID to the data map since Firestore doesn't include it automatically
        data['id'] = documentSnapshot.id;

        // Now we convert the Map data into a ClubModel object
        // 'ClubModel.fromJson(data)' uses the fromJson factory constructor
        // It takes the Map and creates a proper ClubModel object from it
        ClubModel club = ClubModel.fromJson(data);

        // Return the newly created ClubModel object to whoever called this method
        return club;
      }
      // If the document doesn't exist, throw an exception to indicate there's an error
      else {
        // 'throw Exception()' creates and throws an error/exception
        // The error message tells us that the club wasn't found
        throw Exception('Club with ID: $clubId not found');
      }
    }
    // 'catch' block - if something goes wrong (network error, invalid data, etc.)
    catch (e) {
      // If there's any error, re-throw it so the calling code can handle it
      rethrow;
    }
  }

  // This method updates an existing club document in Firestore with new data
  // It takes two parameters:
  // - clubId: the unique identifier of the club to update
  // - data: a Map containing the fields we want to update
  // 'Future<void>' means this method takes time to complete (it's async)
  // and doesn't return any value when done (void = nothing)
  Future<void> updateClub(String clubId, Map<String, dynamic> data) async {
    // The 'async' keyword means this method can do slow operations without blocking the UI
    // 'try' block - we attempt to update data in Firestore (which might fail)
    try {
      // '_firestore.collection('clubs')' - we access the 'clubs' collection in Firestore
      // '.doc(clubId)' - we specify which document we want to update (identified by clubId)
      // '.update(data)' - we update the document with the provided data
      // The data Map contains only the fields we want to change
      // Other fields in the document will remain unchanged
      // 'await' waits for Firestore to complete the update before continuing
      await _firestore.collection('clubs').doc(clubId).update(data);

      // The update is complete - Firestore has saved the changes
      // This method doesn't return anything (void), so we're done
    }
    // 'catch' block - if something goes wrong (network error, document doesn't exist, etc.)
    catch (e) {
      // If there's any error, re-throw it so the calling code can handle it
      rethrow;
    }
  }

  // This method fetches a specific tenure (term/year) for a club from a subcollection
  // It takes two parameters:
  // - clubId: the unique identifier of the club
  // - tenureId: the unique identifier of the tenure within that club
  // 'Future<TenureModel>' means this method takes time to complete (it's async)
  // and will eventually return a single TenureModel object when done
  // The tenure data is stored in: clubs/{clubId}/tenures/{tenureId}
  // This is a subcollection - a collection nested inside another document
  Future<TenureModel> getCurrentTenure(
      String clubId, String tenureId) async {
    // The 'async' keyword means this method can do slow operations without blocking the UI
    // 'try' block - we attempt to fetch data from Firestore (which might fail)
    try {
      // '_firestore.collection('clubs')' - we access the 'clubs' collection in Firestore
      // '.doc(clubId)' - we specify which club document we want
      // '.collection('tenures')' - we access the 'tenures' subcollection inside that club
      // This is a collection of tenures nested inside the club document
      // '.doc(tenureId)' - we specify which tenure document we want from the subcollection
      // '.get()' - we fetch that specific tenure document from Firestore
      // 'await' waits for Firestore to respond with the document before continuing
      DocumentSnapshot documentSnapshot = await _firestore
          .collection('clubs')
          .doc(clubId)
          .collection('tenures')
          .doc(tenureId)
          .get();

      // Check if the document exists in Firestore
      // '.exists' is a boolean property - true if the document was found, false if not
      if (documentSnapshot.exists) {
        // If the document exists, we extract the data as a Map
        // '.data() as Map<String, dynamic>' converts the document data into a Map
        Map<String, dynamic> data =
            documentSnapshot.data() as Map<String, dynamic>;

        // Add the document ID to the data map since Firestore doesn't include it automatically
        data['id'] = documentSnapshot.id;

        // Now we convert the Map data into a TenureModel object
        // 'TenureModel.fromJson(data)' uses the fromJson factory constructor
        // It takes the Map and creates a proper TenureModel object from it
        TenureModel tenure = TenureModel.fromJson(data);

        // Return the newly created TenureModel object to whoever called this method
        return tenure;
      }
      // If the document doesn't exist, throw an exception to indicate there's an error
      else {
        // 'throw Exception()' creates and throws an error/exception
        // The error message tells us that the tenure wasn't found
        throw Exception(
            'Tenure with ID: $tenureId not found for club: $clubId');
      }
    }
    // 'catch' block - if something goes wrong (network error, invalid data, etc.)
    catch (e) {
      // If there's any error, re-throw it so the calling code can handle it
      rethrow;
    }
  }

  // This method fetches members for a specific club and tenure
  // It reads from the subcollection: clubs/{clubId}/members
  // Only members with the matching tenureId are returned
  // Results are ordered by member name in ascending order
  // It returns a List of MemberModel objects
  Future<List<MemberModel>> getMembers(
      String clubId, String tenureId) async {
    // The 'async' keyword means this method can do slow operations without blocking the UI
    try {
      // Start with the club document in the 'clubs' collection
      // Then go into the 'members' subcollection inside that club
      // Filter members where the 'tenureId' field matches the passed value
      // Order them by the 'name' field so the list is sorted alphabetically
      QuerySnapshot querySnapshot = await _firestore
          .collection('clubs')
          .doc(clubId)
          .collection('members')
          .where('tenureId', isEqualTo: tenureId)
          .orderBy('name')
          .get();

      // Convert each Firestore document into a MemberModel object
      List<MemberModel> members = querySnapshot.docs
          .map((doc) {
            // Extract the raw document data as a Map
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

            // Add the Firestore document ID to the data map
            data['id'] = doc.id;

            // Convert the data map into a MemberModel object
            return MemberModel.fromJson(data);
          })
          .toList();

      // Return the list of members to the caller
      return members;
    } catch (e) {
      // If anything goes wrong, re-throw the error for the caller to handle
      rethrow;
    }
  }

  // This method adds a new member document to the specified club's members subcollection
  // It uses member.toJson() to convert the MemberModel object into a Firestore map
  Future<void> addMember(String clubId, MemberModel member) async {
    try {
      // Access the club document, then the members subcollection
      // Call .add() to create a new document with the member data
      await _firestore
          .collection('clubs')
          .doc(clubId)
          .collection('members')
          .add(member.toJson());
    } catch (e) {
      // If anything goes wrong, re-throw the error for the caller to handle
      rethrow;
    }
  }

  // This method updates an existing member document in the members subcollection
  // It takes the clubId, the member's document ID, and a map of fields to update
  Future<void> updateMember(
      String clubId, String memberId, Map<String, dynamic> data) async {
    try {
      // Access the specific member document and update it using the provided data map
      await _firestore
          .collection('clubs')
          .doc(clubId)
          .collection('members')
          .doc(memberId)
          .update(data);
    } catch (e) {
      // If anything goes wrong, re-throw the error for the caller to handle
      rethrow;
    }
  }

  // This method deletes a member document from the members subcollection
  // It takes the clubId and the member's document ID
  Future<void> deleteMember(String clubId, String memberId) async {
    try {
      // Access the member document and delete it from Firestore
      await _firestore
          .collection('clubs')
          .doc(clubId)
          .collection('members')
          .doc(memberId)
          .delete();
    } catch (e) {
      // If anything goes wrong, re-throw the error for the caller to handle
      rethrow;
    }
  }

  // -------------------------------------------------------
// EVENT METHODS
// These methods handle all event-related database operations
// -------------------------------------------------------

// This method fetches all events for a specific club and tenure
// clubId — which club's events we want
// tenureId — which tenure's events we want
Future<List<EventModel>> getEvents(String clubId, String tenureId) async {
  // Go to the 'events' collection in Firestore
  // Filter by clubId AND tenureId so we only get relevant events
  // Order them by date, newest first
  final snapshot = await _firestore
      .collection('events')
      .where('clubId', isEqualTo: clubId)
      .where('tenureId', isEqualTo: tenureId)
      .orderBy('date', descending: true)
      .get();

  // Convert each Firestore document into an EventModel and return as a list
  // doc.id is the document's unique ID
  // doc.data() is the actual fields and values
  return snapshot.docs
      .map((doc) => EventModel.fromJson(doc.id, doc.data()))
      .toList();
}

// This method fetches one single event by its ID
// Useful when we want to open the detail screen of a specific event
Future<EventModel?> getEventById(String eventId) async {
  // Fetch the document directly using its ID
  final doc = await _firestore.collection('events').doc(eventId).get();

  // If the document doesn't exist, return null
  if (!doc.exists) return null;

  // Convert the document to an EventModel and return it
  return EventModel.fromJson(doc.id, doc.data()!);
}

// This method adds a brand new event to Firestore
// Returns the newly created document's ID so we can use it later
Future<String> addEvent(EventModel event) async {
  // .add() automatically creates a new document with a unique ID
  // event.toJson() converts our EventModel into a Map that Firestore understands
  final docRef = await _firestore.collection('events').add(event.toJson());

  // Return the new document's ID
  return docRef.id;
}

// This method updates an existing event document
// eventId — which event to update
// data — a Map of only the fields we want to change
Future<void> updateEvent(String eventId, Map<String, dynamic> data) async {
  // .update() only changes the fields we pass in
  // It does NOT delete any other existing fields
  await _firestore.collection('events').doc(eventId).update(data);
}

// This method permanently deletes an event from Firestore
// Be careful — this cannot be undone!
Future<void> deleteEvent(String eventId) async {
  await _firestore.collection('events').doc(eventId).delete();
}


}