// Import GetX so we can use GetxController, reactive variables, and navigation helpers
import 'package:get/get.dart';

// Import the MemberModel class so we can store member data in this controller
import 'package:club_management_app/models/member_model.dart';

// Import the FirestoreService class so we can load and save members from Firestore
import 'package:club_management_app/services/firestore_service.dart';

// This controller manages the member list and member form state for the app
class MemberController extends GetxController {
  // Reactive list of MemberModel objects, starts empty
  final RxList<MemberModel> members = <MemberModel>[].obs;

  // The selected member for editing, starts as null when no member is selected
  final Rx<MemberModel?> selectedMember = Rx<MemberModel?>(null);

  // Loading state for async operations, starts as false
  final RxBool isLoading = false.obs;

  // FirestoreService instance to perform database operations
  final FirestoreService _firestoreService = FirestoreService();

  // Fetch members for the given club and tenure
  // This sets loading state, loads members, and handles errors
  Future<void> fetchMembers(String clubId, String tenureId) async {
    // Mark loading as true so the UI can show a spinner
    isLoading.value = true;

    try {
      // Call the Firestore service to get members for this club and tenure
      List<MemberModel> result =
          await _firestoreService.getMembers(clubId, tenureId);

      // Save the loaded members into the reactive list
      members.assignAll(result);
    } catch (error) {
      // Show an error snackbar if something goes wrong
      Get.snackbar('Error', 'Failed to load members: $error');
    } finally {
      // Mark loading as false once the work is finished
      isLoading.value = false;
    }
  }

  // Add a new member and refresh the members list
  Future<void> addMember(String clubId, MemberModel member) async {
    try {
      // Add the member document to Firestore
      await _firestoreService.addMember(clubId, member);

      // Refresh the list after adding a new member
      await fetchMembers(clubId, member.tenureId);

      // Show success feedback
      Get.defaultDialog(
        title: 'Success',
        middleText: 'Member added successfully',
        barrierDismissible: false,
      );

      // Wait a bit for the user to see the message
      await Future.delayed(const Duration(seconds: 2));

      // Close the dialog
      Get.back();

      // Navigate back to the member list
      Get.back();
    } catch (error) {
      // Show error feedback if the add operation fails
      Get.snackbar('Error', 'Failed to add member: $error');
    }
  }

  // Update an existing member and refresh the members list
  Future<void> updateMember(
      String clubId, String memberId, Map<String, dynamic> data) async {
    try {
      // Update the member document in Firestore
      await _firestoreService.updateMember(clubId, memberId, data);

      // Refresh the list after updating the member
      // Use the updated tenureId if the change included it
      // Otherwise fallback to the currently selected member or loaded list
      String tenureId = data['tenureId'] as String? ??
          selectedMember.value?.tenureId ??
          (members.isNotEmpty ? members.first.tenureId : '');
      if (tenureId.isNotEmpty) {
        await fetchMembers(clubId, tenureId);
      }

      // Show success feedback
      Get.defaultDialog(
        title: 'Success',
        middleText: 'Member updated successfully',
        barrierDismissible: false,
      );

      // Wait a bit for the user to see the message
      await Future.delayed(const Duration(seconds: 2));

      // Close the dialog
      Get.back();

      // Navigate back to the member list
      Get.back();
    } catch (error) {
      // Show error feedback if the update operation fails
      Get.snackbar('Error', 'Failed to update member: $error');
    }
  }

  // Delete a member and refresh the members list
  Future<void> deleteMember(String clubId, String memberId) async {
    try {
      // Delete the member document from Firestore
      await _firestoreService.deleteMember(clubId, memberId);

      // Refresh the list after deleting the member
      // Use the currently selected member tenure if available
      // Otherwise use the tenure from the already loaded list
      String tenureId = selectedMember.value?.tenureId ??
          (members.isNotEmpty ? members.first.tenureId : '');
      if (tenureId.isNotEmpty) {
        await fetchMembers(clubId, tenureId);
      }

      // Show success feedback
      Get.snackbar('Success', 'Member removed');
    } catch (error) {
      // Show error feedback if the delete operation fails
      Get.snackbar('Error', 'Failed to remove member: $error');
    }
  }

  // Select a member for editing and navigate to the member form screen
  void selectMember(MemberModel member) {
    selectedMember.value = member;
    Get.toNamed('/member-form');
  }

  // Prepare the controller for adding a new member and navigate to the member form screen
  void goToAddMember() {
    selectedMember.value = null;
    Get.toNamed('/member-form');
  }
}
