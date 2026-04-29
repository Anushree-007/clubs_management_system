import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:club_management_app/models/user_request_model.dart';
import 'package:club_management_app/services/auth_service.dart';
import 'package:club_management_app/services/firestore_service.dart';

// UserRequestController manages the full lifecycle of a user registration request:
//
//   1. submitRequest()  — new user fills the form, document lands in Firestore
//                         with status 'pending'.
//   2. fetchRequests()  — admin loads the list of all pending/reviewed requests.
//   3. approveRequest() — admin approves: Firebase Auth account is created,
//                         Firestore user profile is written, request marked approved.
//   4. rejectRequest()  — admin rejects with a reason, request marked rejected.
//
// The controller also exposes pendingCount so the dashboard badge stays live.

class UserRequestController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  // Full list of requests shown on the admin screen
  final RxList<UserRequestModel> requests = <UserRequestModel>[].obs;

  // How many are still pending — drives the badge on the admin dashboard
  final RxInt pendingCount = 0.obs;

  // Loading flags so the UI can show spinners at the right time
  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Load the pending count immediately so the dashboard badge is accurate
    // as soon as the controller is registered.
    _refreshPendingCount();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // submitRequest — called from RegisterRequestScreen.
  //
  // We deliberately do NOT create a Firebase Auth account here.
  // The document just sits in Firestore with status 'pending' until the
  // admin acts on it.  This keeps the auth user table clean and ensures
  // nobody can log in before the admin approves them.
  // ─────────────────────────────────────────────────────────────────────────
  Future<bool> submitRequest({
    required String name,
    required String email,
    required String role,
    required String phone,
    required String employeeId,
    String? clubId,
    String? clubName,
    Map<String, dynamic>? newClubData, // ADD THIS
  }) async {
    isSubmitting.value = true;
    try {
      final data = {
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'role': role,
        'phone': phone.trim(),
        'employeeId': employeeId.trim(),
        if (clubId != null && clubId.isNotEmpty) 'clubId': clubId,
        if (clubName != null && clubName.isNotEmpty) 'clubName': clubName,
        if (newClubData != null) 'newClubData': newClubData, // ADD THIS
        'status': 'pending',
        'createdAt': DateTime.now(),
      };

      await _firestoreService.submitUserRequest(data);
      await _refreshPendingCount();
      return true;
    } catch (e) {
      Get.snackbar(
        'Submission Failed',
        'Could not submit your request. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // fetchRequests — populates the admin requests screen.
  // Loads all requests (pending, approved, rejected) newest-first.
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> fetchRequests() async {
    isLoading.value = true;
    try {
      final rawList = await _firestoreService.getAllUserRequests();
      requests.assignAll(
        rawList.map((raw) => UserRequestModel.fromJson(raw['id'] as String, raw)).toList(),
      );
      // Keep count in sync after every full fetch
      pendingCount.value = requests.where((r) => r.status == 'pending').length;
    } catch (e) {
      Get.snackbar('Error', 'Failed to load requests: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // approveRequest — the core admin action.
  //
  // Steps:
  //   1. Create Firebase Auth account using a temporary secondary app
  //      (so the admin's own session is NOT replaced).
  //   2. Write the full user profile to Firestore users/{uid}.
  //   3. Mark the request document as approved.
  //   4. Refresh the local list and pending count.
  //
  // If step 1 or 2 fails, we do NOT mark the request approved, so the
  // admin can try again without creating orphaned auth accounts.
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> approveRequest(UserRequestModel request) async {
    isLoading.value = true;
    try {
      // Generate temporary password
// Generate temporary password — FIXED
    final rawName = request.name.trim();
    final namePart = rawName.isNotEmpty ? rawName.split(' ').first : 'User';
    final idPart = request.employeeId.length >= 4
        ? request.employeeId.substring(request.employeeId.length - 4)
        : (request.employeeId.isNotEmpty ? request.employeeId : '0000');

    // FIXED: Use namePart instead of nameForPwd in the fallback
    final nameForPwd = namePart.length > 1
        ? '${namePart[0].toUpperCase()}${namePart.substring(1).toLowerCase()}'
        : namePart.toUpperCase();  // ✅ CHANGED: namePart.toUpperCase()
    final tempPassword = '$nameForPwd${idPart}!';

      String finalClubId = request.clubId ?? '';

      // CREATE NEW CLUB if chairperson requested one
      if (request.newClubData != null && request.role == 'chairperson') {
        final newClubId = await _firestoreService.createClubFromData(request.newClubData!);
        finalClubId = newClubId;
        
        // Update the request document with the new club ID before approval
        await _firestoreService.updateUserRequest(request.id, {
          'clubId': newClubId,
          'clubName': request.newClubData!['name'],
        });
      }

      // Step 1 — create Firebase Auth account
      final uid = await _authService.createUser(request.email, tempPassword);

      // Step 2 — write user profile with final club ID
      await _firestoreService.createUserProfile(uid, {
        'id': uid,
        'name': request.name,
        'email': request.email,
        'role': request.role,
        'phone': request.phone,
        if (finalClubId.isNotEmpty) 'clubId': finalClubId,
        'createdAt': DateTime.now(),
      });

      // Step 3 — mark request approved
      await _firestoreService.updateUserRequest(request.id, {
        'status': 'approved',
        'reviewedAt': DateTime.now(),
        'tempPassword': tempPassword,
      });

      await fetchRequests();

      Get.snackbar(
        'Approved',
        '${request.name} has been approved.\n'
        'Temporary password: $tempPassword\n'
        '(Share this securely with the user)',
        duration: const Duration(seconds: 8),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF0F6E56),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Approval Failed',
        'Could not approve request: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
  // ─────────────────────────────────────────────────────────────────────────
  // rejectRequest — marks a request rejected and stores the admin's reason.
  //
  // No Firebase Auth account is created, so the user simply cannot log in.
  // The reason is stored on the request document so it can be shown in a
  // future "check my status" screen or emailed to the applicant.
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> rejectRequest(UserRequestModel request, String reason) async {
    if (reason.trim().isEmpty) {
      Get.snackbar(
        'Reason Required',
        'Please provide a rejection reason before rejecting.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isLoading.value = true;
    try {
      await _firestoreService.updateUserRequest(request.id, {
        'status': 'rejected',
        'rejectionReason': reason.trim(),
        'reviewedAt': DateTime.now(),
      });

      await fetchRequests();

      Get.snackbar(
        'Rejected',
        '${request.name}\'s request has been rejected.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to reject request: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Internal helper — fetches just the count without loading the full list.
  // Used on init and after any status change.
  Future<void> _refreshPendingCount() async {
    try {
      pendingCount.value = await _firestoreService.getPendingRequestCount();
    } catch (_) {
      // Silently ignore — the badge will just show 0 if Firestore is unreachable
    }
  }
}