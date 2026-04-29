import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:club_management_app/models/user_request_model.dart';
import 'package:club_management_app/services/auth_service.dart';
import 'package:club_management_app/services/firestore_service.dart';

// UserRequestController manages the full lifecycle of a registration request:
//
//   submitRequest()  — new user fills the form → Firestore doc with 'pending'.
//   fetchRequests()  — admin loads all pending/reviewed requests.
//   approveRequest() — admin approves → Firebase Auth account created,
//                      Firestore profile written, request marked approved.
//   rejectRequest()  — admin rejects with a reason, request marked rejected.
//   checkStatus()    — unauthenticated user looks up their own request by email.
//
// pendingCount drives the badge on the admin dashboard.

class UserRequestController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  // Full list shown on the admin screen
  final RxList<UserRequestModel> requests = <UserRequestModel>[].obs;

  // Badge counter — live count of pending requests
  final RxInt pendingCount = 0.obs;

  // Loading flags so the UI shows spinners at the right moments
  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;

  // Holds the result of checkStatus() so the CheckStatusScreen can read it
  final Rx<UserRequestModel?> checkedRequest = Rx<UserRequestModel?>(null);
  final RxBool isCheckingStatus = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Populate the badge immediately so the dashboard shows the right count
    _refreshPendingCount();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // submitRequest — called from RegisterRequestScreen.
  //
  // We deliberately do NOT create a Firebase Auth account here.
  // The document sits in Firestore with status 'pending' until the admin
  // acts on it.  This keeps the auth user table clean.
  //
  // FIX: Duplicate check added.  Without this, the same email could submit
  // multiple requests and spam the admin queue.  We query Firestore for an
  // existing request with the same email and block the submission if one
  // is found, showing a clear message about the existing status.
  // ─────────────────────────────────────────────────────────────────────────
  Future<bool> submitRequest({
    required String name,
    required String email,
    required String role,
    required String phone,
    required String employeeId,
    String? clubId,
    String? clubName,
    String? unlisted, // free-text club name when club is not in the system yet
  }) async {
    isSubmitting.value = true;
    try {
      // Duplicate guard — check before writing to Firestore
      final existingStatus =
          await _firestoreService.checkExistingRequest(email);
      if (existingStatus != null) {
        String message;
        switch (existingStatus) {
          case 'pending':
            message =
                'A request with this email is already pending review. Please wait for the admin to respond.';
            break;
          case 'approved':
            message =
                'This email already has an approved account. Use the login screen to sign in.';
            break;
          case 'rejected':
            message =
                'A previous request for this email was rejected. Please contact the admin directly.';
            break;
          default:
            message = 'A request for this email already exists.';
        }
        Get.snackbar(
          'Request Already Exists',
          message,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5),
        );
        return false;
      }

// In user_request_controller.dart, inside submitRequest(), add to the data map:
      final data = {
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'role': role,
        'phone': phone.trim(),
        'employeeId': employeeId.trim(),
        if (clubId != null && clubId.isNotEmpty) 'clubId': clubId,
        if (clubName != null && clubName.isNotEmpty) 'clubName': clubName,
        if (unlisted != null && unlisted.isNotEmpty)
          'unlistedClubName': unlisted.trim(),
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
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> fetchRequests() async {
    isLoading.value = true;
    try {
      final rawList = await _firestoreService.getAllUserRequests();
      requests.assignAll(
        rawList
            .map((raw) =>
                UserRequestModel.fromJson(raw['id'] as String, raw))
            .toList(),
      );
      pendingCount.value =
          requests.where((r) => r.status == 'pending').length;
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
  //   1. Create Firebase Auth account via a secondary app so the admin's own
  //      session is NOT replaced.
  //   2. Write the full user profile to Firestore users/{uid}.
  //   3. Mark the request document as approved and store the temp password so
  //      the admin can see and copy it from the requests screen.
  //   4. Refresh local state.
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> approveRequest(UserRequestModel request) async {
    isLoading.value = true;
    try {
      // Generate temp password: CapFirstName + last4EmployeeId + '!'
      final rawName = request.name.trim();
      final namePart =
          rawName.isNotEmpty ? rawName.split(' ').first : 'User';
      final idPart = request.employeeId.length >= 4
          ? request.employeeId
              .substring(request.employeeId.length - 4)
          : (request.employeeId.isNotEmpty
              ? request.employeeId
              : '0000');
      final nameForPwd = namePart.length > 1
          ? '${namePart[0].toUpperCase()}${namePart.substring(1).toLowerCase()}'
          : namePart.toUpperCase();
      final tempPassword = '$nameForPwd${idPart}!';

      // Step 1 — create Firebase Auth account without logging the admin out
      final uid =
          await _authService.createUser(request.email, tempPassword);

      String? resolvedClubId = request.clubId;
      if (resolvedClubId == null || resolvedClubId.isEmpty) {
        // Check if there's an unlistedClubName on this request
        // We need to re-fetch the raw request to get this field
        final raw = await _firestoreService.getRequestById(request.id);
        final unlistedName = raw?['unlistedClubName'] as String?;
        if (unlistedName != null && unlistedName.isNotEmpty) {
          resolvedClubId = await _firestoreService.createClub({
            'name': unlistedName,
            'shortCode': '',
            'domain': 'other',
            'status': 'active',
            'description': '',
            'facultyName': '',
            'facultyEmail': '',
            'facultyPhone': '',
            'currentTenureId': '',
          });
        }
      }

      // Step 2 — write the Firestore user profile
      await _firestoreService.createUserProfile(uid, {
        'id': uid,
        'name': request.name,
        'email': request.email,
        'role': request.role,
        'phone': request.phone,
        if (request.clubId != null) 'clubId': request.clubId,
        'createdAt': DateTime.now(),
      });

      // Step 3 — mark the request approved and persist the temp password.
      // Storing it on the request doc means the admin can re-open the screen
      // later and still see/copy the password without needing to regenerate it.
      await _firestoreService.updateUserRequest(request.id, {
        'status': 'approved',
        'reviewedAt': DateTime.now(),
        'tempPassword': tempPassword,
      });

      // Step 4 — refresh local list so the screen updates immediately
      await fetchRequests();

      Get.snackbar(
        'Approved',
        '${request.name} approved.\nTemp password: $tempPassword\n(shown on the request card — copy it to share)',
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
  // rejectRequest — stores the reason and marks the request rejected.
  // No Firebase Auth account is created.
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> rejectRequest(
      UserRequestModel request, String reason) async {
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

  // ─────────────────────────────────────────────────────────────────────────
  // checkStatus — called from CheckStatusScreen.
  //
  // Allows an unauthenticated user to look up their own request by email.
  // The result is written to checkedRequest so the screen can react to it.
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> checkStatus(String email) async {
    isCheckingStatus.value = true;
    checkedRequest.value = null;
    try {
      final raw =
          await _firestoreService.getRequestByEmail(email);
      if (raw == null) {
        Get.snackbar(
          'Not Found',
          'No request found for this email address.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      checkedRequest.value =
          UserRequestModel.fromJson(raw['id'] as String, raw);
    } catch (e) {
      Get.snackbar('Error', 'Could not check status: $e');
    } finally {
      isCheckingStatus.value = false;
    }
  }

  // Fetches just the pending count — used on init and after status changes.
  Future<void> _refreshPendingCount() async {
    try {
      pendingCount.value =
          await _firestoreService.getPendingRequestCount();
    } catch (_) {
      // Badge shows 0 if Firestore is unreachable — not critical
    }
  }
}