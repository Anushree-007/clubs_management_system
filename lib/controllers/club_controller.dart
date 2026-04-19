// This imports the GetX package so we can use GetxController, Rx, and Get utilities
import 'package:get/get.dart';

// Import the ClubModel class so we can store club data in this controller
import 'package:club_management_app/models/club_model.dart';

// Import the TenureModel class so we can store tenure data in this controller
import 'package:club_management_app/models/tenure_model.dart';

// Import the FirestoreService class so this controller can call Firestore methods
import 'package:club_management_app/services/firestore_service.dart';

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
    // Set isLoading to true so the UI can show a loading indicator
    isLoading.value = true;

    // 'try' block - we attempt to fetch clubs from Firestore
    try {
      // Call the FirestoreService method to get all clubs
      List<ClubModel> allClubs = await _firestoreService.getAllClubs();

      // Replace the current list contents with the fetched club list
      clubs.assignAll(allClubs);
    }
    // 'catch' block - if anything goes wrong during the fetch
    catch (error) {
      // Show a snackbar with the error message using GetX
      Get.snackbar(
        'Error',
        'Failed to load clubs: $error',
      );
    }
    // 'finally' block runs whether or not the fetch succeeded
    finally {
      // Set isLoading back to false once the fetch is complete
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
    // Set isLoading to true so the UI can show a loading indicator
    isLoading.value = true;

    // 'try' block - we attempt to update the club document in Firestore
    try {
      // Call the FirestoreService method to update the club data
      await _firestoreService.updateClub(clubId, data);

      // Refresh the club data by fetching all clubs again
      await fetchAllClubs();

      // Show a success snackbar when the update completes
      Get.snackbar('Success', 'Club updated successfully');
    }
    // 'catch' block - if the update fails
    catch (error) {
      // Show an error snackbar with the failure message
      Get.snackbar('Error', 'Failed to update club: $error');
    }
    // 'finally' block runs whether or not the update succeeded
    finally {
      // Set isLoading back to false once the update is complete
      isLoading.value = false;
    }
  }
}
