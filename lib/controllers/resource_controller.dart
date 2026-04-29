// This is the Resource Controller
// It manages all resource and booking operations
// Screens call methods here, this talks to FirestoreService
//
// KEY DESIGN CHANGE (production fix):
// The old code set resource.status = 'occupied' permanently in Firestore
// when a booking was approved. This meant a resource stayed "occupied"
// forever, even after the event ended, blocking other clubs from booking it.
//
// The correct approach: resource status in Firestore stays 'free' always.
// We compute "is this resource occupied right now?" dynamically by checking
// whether any approved booking's time window covers the current moment.
// This is done in the getters at the bottom of this file.

import 'package:get/get.dart';
import 'package:club_management_app/models/resource_model.dart';
import 'package:club_management_app/models/booking_model.dart';
import 'package:club_management_app/services/firestore_service.dart';
import 'package:club_management_app/controllers/auth_controller.dart';

class ResourceController extends GetxController {

  final FirestoreService _firestoreService = FirestoreService();

  // Reactive list of all resources
  final RxList<ResourceModel> resources = <ResourceModel>[].obs;

  // Reactive list of all bookings
  final RxList<BookingModel> bookings = <BookingModel>[].obs;

  // Loading state
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchResources();
  }

  // -------------------------------------------------------
  // FETCH ALL RESOURCES
  // -------------------------------------------------------
  Future<void> fetchResources() async {
    try {
      isLoading.value = true;
      final result = await _firestoreService.getAllResources();
      resources.assignAll(result);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not load resources: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // -------------------------------------------------------
  // FETCH BOOKINGS
  // Teachers see all bookings
  // Chairpersons see only their club's bookings
  // -------------------------------------------------------
  Future<void> fetchBookings() async {
    try {
      isLoading.value = true;

      final authController = Get.find<AuthController>();
      List<BookingModel> result;

      if (authController.isTeacher) {
        result = await _firestoreService.getAllBookings();
      } else {
        final clubId = authController.currentUser.value?.clubId ?? '';
        result = await _firestoreService.getBookingsByClub(clubId);
      }

      bookings.assignAll(result);

    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not load bookings: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // -------------------------------------------------------
  // SUBMIT A BOOKING REQUEST
  // -------------------------------------------------------
  Future<void> submitBooking(BookingModel booking) async {
    try {
      isLoading.value = true;
      await _firestoreService.addBooking(booking);
      await fetchBookings();

      // Navigation is handled by the calling screen after showing confirmation

    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not submit booking: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // -------------------------------------------------------
  // APPROVE A BOOKING
  // NOTE: We no longer flip resource.status to 'occupied' in
  // Firestore. Whether a resource is currently occupied is
  // computed dynamically from approved booking time windows.
  // This means a resource automatically becomes "free" again
  // after the booked slot ends — no manual cleanup needed.
  // -------------------------------------------------------
  Future<void> approveBooking(BookingModel booking) async {
    try {
      isLoading.value = true;

      final authController = Get.find<AuthController>();
      final teacherId = authController.currentUser.value?.id ?? '';

      // Only update the booking status — do NOT touch resource.status
      await _firestoreService.updateBookingStatus(
          booking.id, 'approved', teacherId);

      await fetchBookings();
      await fetchResources();

      Get.snackbar(
        'Approved',
        'Booking has been approved',
        snackPosition: SnackPosition.BOTTOM,
      );

    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not approve booking: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // -------------------------------------------------------
  // REJECT A BOOKING
  // -------------------------------------------------------
  Future<void> rejectBooking(BookingModel booking) async {
    try {
      isLoading.value = true;

      final authController = Get.find<AuthController>();
      final teacherId = authController.currentUser.value?.id ?? '';

      await _firestoreService.updateBookingStatus(
          booking.id, 'rejected', teacherId);

      await fetchBookings();

      Get.snackbar(
        'Rejected',
        'Booking has been rejected',
        snackPosition: SnackPosition.BOTTOM,
      );

    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not reject booking: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // -------------------------------------------------------
  // GETTERS — derived from live booking data
  // -------------------------------------------------------

  // A resource is "currently occupied" if any approved booking
  // for it has a time window that covers right now
  bool isResourceOccupiedNow(String resourceId) {
    final now = DateTime.now();
    return bookings.any((b) =>
        b.resourceId == resourceId &&
        b.status == 'approved' &&
        b.startTime.isBefore(now) &&
        b.endTime.isAfter(now));
  }

  // Resources with no active booking right now
  List<ResourceModel> get freeResources =>
      resources.where((r) => !isResourceOccupiedNow(r.id)).toList();

  // Resources with an active booking right now
  List<ResourceModel> get occupiedResources =>
      resources.where((r) => isResourceOccupiedNow(r.id)).toList();

  // All approved bookings for a specific resource, sorted by time
  List<BookingModel> approvedBookingsFor(String resourceId) =>
      bookings
          .where((b) =>
              b.resourceId == resourceId && b.status == 'approved')
          .toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));

  // Only pending bookings
  List<BookingModel> get pendingBookings =>
      bookings.where((b) => b.status == 'pending').toList();

  // Only approved bookings
  List<BookingModel> get approvedBookings =>
      bookings.where((b) => b.status == 'approved').toList();
}