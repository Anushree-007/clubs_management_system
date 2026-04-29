// This imports the GetX package so we can use GetxController, Rx, and Get utilities
import 'package:get/get.dart';

// Import the ClubModel class so we can store club data in this controller
import 'package:club_management_app/models/club_model.dart';

// Import the TenureModel class so we can store tenure data in this controller
import 'package:club_management_app/models/tenure_model.dart';

// Import the FirestoreService class so this controller can call Firestore methods
import 'package:club_management_app/services/firestore_service.dart';
import 'package:club_management_app/controllers/auth_controller.dart';

// This is the ClubController class - it manages club-related state and actions
class ClubController extends GetxController {
  // 'RxList<ClubModel>' stores a reactive list of ClubModel objects
  // This starts empty because we haven't loaded any club data yet
  final RxList<ClubModel> clubs = <ClubModel>[].obs;

  // 'Rx<ClubModel?>' stores the currently selected club
  // It starts as null because no club is selected at first
  final Rx<ClubModel?> selectedClub = Rx<ClubModel?>(null);

  // 'Rx<TenureModel?>' stores the current tenure for the selected club
  // It starts as null because we haven't loaded tenure data yet
  final Rx<TenureModel?> currentTenure = Rx<TenureModel?>(null);

  // 'RxBool' stores whether the controller is currently loading data
  // It starts false because we are not loading anything at initialization
  final RxBool isLoading = false.obs;

  // 'RxString' stores the selected club ID used by dropdowns or selection UI
  // It starts as an empty string because no item is selected initially
  final RxString selectedClubId = ''.obs;

  // Create a FirestoreService instance so this controller can call Firestore methods
  final FirestoreService _firestoreService = FirestoreService();

  // This method runs automatically when the controller is initialized
  // We override onInit() to load club data right when the controller starts
  @override
  void onInit() {
    // First, call the base class onInit() method
    super.onInit();

    // Fetch all clubs from Firestore immediately when the controller starts
    fetchAllClubs();
  }


  // This method fetches all clubs from Firestore and saves them into the clubs list
  Future<void> fetchAllClubs() async {
    isLoading.value = true;
    try {
      List<ClubModel> allClubs = await _firestoreService.getAllClubs();
      clubs.assignAll(allClubs);

      // If the previously selected club is no longer in the list, clear it
      // This prevents the DropdownButton assertion crash on reload
      if (selectedClubId.value.isNotEmpty &&
          !allClubs.any((c) => c.id == selectedClubId.value)) {
        selectedClubId.value = '';
        selectedClub.value = null;
      }
    } catch (error) {
      Get.snackbar('Error', 'Failed to load clubs: $error');
    } finally {
      isLoading.value = false;
    }
  }

  // This method selects a club by its ID and loads its current tenure
  Future<void> selectClub(String clubId) async {
    // Save the selected club ID for dropdown or UI state
    selectedClubId.value = clubId;

    // Find the club in the existing clubs list by matching the id
    ClubModel? club = clubs.firstWhereOrNull((item) => item.id == clubId);

    // Set the selectedClub reactive value
    selectedClub.value = club;

    // If the club does not exist, show an error snackbar and stop
    if (club == null) {
      Get.snackbar('Error', 'Club not found for ID: $clubId');
      return;
    }

    // Load the current tenure for the selected club from Firestore
    try {
      // Guard: if currentTenureId is empty the club has no active tenure yet.
      // Sending an empty string to Firestore would produce a "document not
      // found" error.  Show a clear message instead and stay on the dashboard.
      if (club.currentTenureId.isEmpty) {
        Get.snackbar('No Tenure', 'This club has no active tenure set up yet.');
        return;
      }

      TenureModel tenure = await _firestoreService.getCurrentTenure(
        clubId,
        club.currentTenureId,
      );

      // Save the tenure in the reactive variable
      currentTenure.value = tenure;

      // Navigate to the club profile page using GetX routing
      Get.toNamed('/club-profile');
    }
    // If fetching the tenure fails, show an error snackbar
    catch (error) {
      Get.snackbar('Error', 'Failed to load tenure: $error');
    }
  }

  // This method updates a club in Firestore and refreshes the list afterward
  Future<void> updateClub(String clubId, Map<String, dynamic> data) async {
    // ── Ownership guard ──────────────────────────────────────────────────
    // Double-check permission here even though the UI should already prevent
    // unauthorised edits. This stops anyone who bypasses the UI (e.g. via
    // deep-linking directly to /club-edit) from writing to Firestore.
    final authController = Get.find<AuthController>();
    if (!authController.canManageClub(clubId)) {
      Get.snackbar(
        'Access Denied',
        'You can only edit your own club.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    // ─────────────────────────────────────────────────────────────────────

    isLoading.value = true;

    try {
      await _firestoreService.updateClub(clubId, data);
      await fetchAllClubs();
      Get.snackbar('Success', 'Club updated successfully');
    } catch (error) {
      Get.snackbar('Error', 'Failed to update club: $error');
    } finally {
      isLoading.value = false;
    }
  }

  // ✅ NEW: Refresh method for after login
// Add this method to ClubController:
  Future<void> refreshClubs() async {
    await fetchAllClubs();
}
}