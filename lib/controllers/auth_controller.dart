// Import the Get package - this provides GetX for state management and navigation
import 'package:get/get.dart';

// Import Material Design - this gives us the Color class for styling
import 'package:flutter/material.dart';

// Import the UserModel - we use this to store user data
import 'package:club_management_app/models/user_model.dart';

// Import the AuthService - this handles Firebase authentication (login/logout)
import 'package:club_management_app/services/auth_service.dart';

// Import the FirestoreService - this handles reading user data from Firestore database
import 'package:club_management_app/services/firestore_service.dart';

// ✅ NEW: Import ClubController for refresh after login
import 'package:club_management_app/controllers/club_controller.dart';

class AuthController extends GetxController {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  late RxBool showPassword = RxBool(false);
  late Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  late RxBool isLoading = RxBool(false);

  // ✅ NEW: Chairperson's club ID - reactive
  late RxString myClubId = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    try {
      final firebaseUser = _authService.getCurrentUser();
      if (firebaseUser == null) return;

      final user = await _firestoreService.getUser(firebaseUser.uid);
      currentUser.value = user;

      // ✅ NEW: Set myClubId for chairpersons
      if (user.role == 'chairperson' && user.clubId != null) {
        myClubId.value = user.clubId!;
      }

      // ✅ NEW: Refresh clubs after session restore
      final clubController = Get.find<ClubController>();
      await clubController.refreshClubs();

      Get.offAllNamed('/dashboard');
    } catch (e) {
      await _authService.signOut();
    }
  }

  Future<void> login(String email, String password) async {
    try {
      isLoading.value = true;

      final userCredential = await _authService.signIn(email, password);
      String userId = userCredential.user!.uid;

      UserModel user = await _firestoreService.getUser(userId);
      currentUser.value = user;

      // ✅ CRITICAL: Set chairperson's club ID
      if (user.role == 'chairperson' && user.clubId != null) {
        myClubId.value = user.clubId!;
      }

      // ✅ REFRESH CLUBS so new clubs appear immediately
      final clubController = Get.find<ClubController>();
      await clubController.refreshClubs();

      Get.offAllNamed('/dashboard');

      Get.snackbar('Success', 'Login successful!');
    } catch (e) {
      String errorMessage = e.toString();
      Get.snackbar(
        'Login Error',
        errorMessage,
        backgroundColor: const Color.fromARGB(255, 244, 67, 54),
        colorText: const Color.fromARGB(255, 255, 255, 255),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      await _authService.signOut();
      currentUser.value = null;
      myClubId.value = ''; // ✅ Clear club ID
      Get.offAllNamed('/login');
      Get.snackbar('Logged Out', 'You have been logged out successfully.');
    } catch (e) {
      Get.snackbar(
        'Logout Error',
        e.toString(),
        backgroundColor: const Color.fromARGB(255, 244, 67, 54),
        colorText: const Color.fromARGB(255, 255, 255, 255),
      );
    }
  }

  bool get isChairperson => currentUser.value?.role == 'chairperson';
  bool get isTeacher => currentUser.value?.role == 'teacher';

  bool canManageClub(String clubId) {
    if (isTeacher) return true;
    return isChairperson && myClubId.value == clubId;
  }

  // ✅ UPDATED: Reactive getter for dashboard filtering
  String get myClubIdReactive => myClubId.value;
}