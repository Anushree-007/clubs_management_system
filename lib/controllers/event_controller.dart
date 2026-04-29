// This file is the brain of all event-related operations
// It sits between the UI screens and the FirestoreService
// The screens call methods here, and this controller talks to Firestore

// GetX package for state management and navigation
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Our EventModel so we can work with event objects
import 'package:club_management_app/models/event_model.dart';

// FirestoreService to talk to the database
import 'package:club_management_app/services/firestore_service.dart';

// EventController extends GetxController — this makes it a GetX controller
// GetX will manage its lifecycle (create it, destroy it automatically)
class EventController extends GetxController {

  // Create one instance of FirestoreService to use throughout this controller
  // Think of this as our "database helper" object
  final FirestoreService _firestoreService = FirestoreService();

  // RxList — a reactive list of events
  // "Reactive" means the UI automatically updates when this list changes
  // Starts as an empty list
  final RxList<EventModel> events = <EventModel>[].obs;

  // Rx<EventModel?> — the event currently being viewed or edited
  // Starts as null (no event selected yet)
  final Rx<EventModel?> selectedEvent = Rx<EventModel?>(null);

  // RxBool — tracks whether data is currently being loaded
  // When true, we show a loading spinner in the UI
  final RxBool isLoading = false.obs;

  // -------------------------------------------------------
  // FETCH ALL EVENTS
  // Call this when opening the Event List screen
  // Pass the clubId and tenureId to filter events correctly
  // -------------------------------------------------------
  Future<void> fetchEvents(String clubId, String tenureId) async {
    try {
      // Show the loading spinner
      isLoading.value = true;

      // Ask FirestoreService to get all events for this club and tenure
      final result = await _firestoreService.getEvents(clubId, tenureId);

      // Save the result into our reactive list
      // The UI will automatically refresh when this changes
      events.assignAll(result);

    } catch (e) {
      // If something goes wrong, show a red error message at the top of the screen
      Get.snackbar(
        'Error',
        'Could not load events: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      // Whether it succeeded or failed, always hide the loading spinner
      isLoading.value = false;
    }
  }

  // -------------------------------------------------------
  // ADD A NEW EVENT
  // Call this when the chairperson submits the Add Event form
  // -------------------------------------------------------
  Future<void> addEvent(EventModel event) async {
    try {
      // Show loading spinner while saving
      isLoading.value = true;

      // Save the new event to Firestore
      await _firestoreService.addEvent(event);

      // Refresh the events list so the new event appears immediately
      await fetchEvents(event.clubId, event.tenureId);

      // Show a green success message
      Get.back();
      await Future.delayed(const Duration(milliseconds: 300));
      Get.snackbar(
        'Event Saved',
        'Event has been saved successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF0F6E56),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(12),
        borderRadius: 10,
        icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
      );

    } catch (e) {
      // Show error if saving failed
      Get.snackbar(
        'Error',
        'Could not add event: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      // Always hide loading spinner when done
      isLoading.value = false;
    }
  }

  // -------------------------------------------------------
  // UPDATE AN EXISTING EVENT
  // Call this when the chairperson saves edits on the Edit Event form
  // eventId — which event to update
  // data — a Map of only the fields that changed
  // clubId and tenureId — needed to refresh the list after updating
  // -------------------------------------------------------
  Future<void> updateEvent(
      String eventId, Map<String, dynamic> data, String clubId, String tenureId) async {
    try {
      // Show loading spinner
      isLoading.value = true;

      // Tell Firestore to update only the changed fields
      await _firestoreService.updateEvent(eventId, data);

      // Refresh the list so the updated event shows immediately
      await fetchEvents(clubId, tenureId);

      // Show success message
      Get.back();
      await Future.delayed(const Duration(milliseconds: 300));
      Get.snackbar(
        'Success',
        'Event updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF0F6E56),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(12),
        borderRadius: 10,
        icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
      );

    } catch (e) {
      // Show error if update failed
      Get.snackbar(
        'Error',
        'Could not update event: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      // Always hide loading spinner
      isLoading.value = false;
    }
  }

  // -------------------------------------------------------
  // DELETE AN EVENT
  // Call this when chairperson wants to remove an event
  // -------------------------------------------------------
  Future<void> deleteEvent(
      String eventId, String clubId, String tenureId) async {
    try {
      // Show loading spinner
      isLoading.value = true;

      // Delete the event from Firestore permanently
      await _firestoreService.deleteEvent(eventId);

      // Refresh the list so the deleted event disappears immediately
      await fetchEvents(clubId, tenureId);

      // Show success message
      Get.snackbar(
        'Success',
        'Event deleted',
        snackPosition: SnackPosition.BOTTOM,
      );

    } catch (e) {
      // Show error if delete failed
      Get.snackbar(
        'Error',
        'Could not delete event: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      // Always hide loading spinner
      isLoading.value = false;
    }
  }

  // -------------------------------------------------------
  // SELECT AN EVENT AND GO TO DETAIL SCREEN
  // Call this when user taps an event card in the list
  // -------------------------------------------------------
  void selectEvent(EventModel event) {
    // Save the tapped event as the selected one
    selectedEvent.value = event;

    // Navigate to the event detail screen
    Get.toNamed('/event-detail');
  }

  // -------------------------------------------------------
  // GO TO ADD EVENT FORM
  // Call this when chairperson taps the + button
  // -------------------------------------------------------
  void goToAddEvent() {
    // Clear selectedEvent so the form knows it's in ADD mode
    selectedEvent.value = null;

    // Navigate to the event form screen
    Get.toNamed('/event-form');
  }

  // -------------------------------------------------------
  // GO TO EDIT EVENT FORM
  // Call this from the detail screen when chairperson taps Edit
  // selectedEvent is already set so the form knows it's in EDIT mode
  // -------------------------------------------------------
  void goToEditEvent() {
    // selectedEvent is already set from selectEvent() so we don't change it
    // Just navigate to the form — the form will detect it's in edit mode
    Get.toNamed('/event-form');
  }

  // -------------------------------------------------------
  // GETTERS — these are computed values based on the events list
  // A getter is like a variable that calculates its value automatically
  // -------------------------------------------------------

  // Returns the total number of events
  int get totalEvents => events.length;

  // Returns only future events — where the event date is after right now
  List<EventModel> get upcomingEvents =>
      events.where((e) => e.date.isAfter(DateTime.now())).toList();

  // Returns only past events — where the event date is before right now
  List<EventModel> get pastEvents =>
      events.where((e) => e.date.isBefore(DateTime.now())).toList();
}