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

// This is the AuthController class - it manages authentication state for the app
// 'extends GetxController' means it inherits from GetxController, which provides GetX features
// Controllers manage the business logic and state - they don't display anything, they just handle data
class AuthController extends GetxController {
  // This creates an instance of AuthService to use for authentication operations
  final AuthService _authService = AuthService();

  // This creates an instance of FirestoreService to use for fetching user data from database
  final FirestoreService _firestoreService = FirestoreService();

  // This is an Rx boolean that tracks whether the password is visible or hidden
  // 'RxBool' is a reactive boolean - when it changes, the UI automatically updates
  // We use this to show/hide the password text in the login screen
  late RxBool showPassword = RxBool(false);
  // We initialize it to false because we want the password hidden by default

  // This is an Rx variable that holds the currently logged-in user
  // 'Rx<UserModel?>' means it's a reactive variable that can hold a UserModel or null
  // The '?' means it can be null (empty) - this is important because we start with no user
  // 'Rx' makes this variable reactive - any time it changes, the UI automatically updates
  late Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  // We initialize it to null because at first, nobody is logged in

  // This is an Rx boolean that tracks whether a login operation is happening
  // 'RxBool' is a reactive boolean - when it changes, the UI automatically updates
  // We use this to show a loading spinner or disable the login button while signing in
  late RxBool isLoading = RxBool(false);
  // We initialize it to false because we're not loading anything at first

  // This method logs in a user with their email and password
  // It takes two parameters: email (String) and password (String)
  // 'Future<void>' means this is async (takes time) and doesn't return any value
  Future<void> login(String email, String password) async {
    // The 'async' keyword means this method can do slow operations without blocking the UI

    // 'try' block - we attempt to sign in the user (which might fail)
    try {
      // Set isLoading to true to show a loading spinner
      // This tells the UI "something is happening, show a loader"
      isLoading.value = true;

      // Call AuthService to sign in the user with their email and password
      // 'await' waits for Firebase to respond before continuing
      final userCredential =
          await _authService.signIn(email, password);

      // If sign in was successful, we get back a UserCredential with the user's UID
      // '.user?.uid' extracts the unique ID from the UserCredential
      // The '?.' is safe navigation - if user is null, it returns null instead of crashing
      String userId = userCredential.user!.uid;

      // Now we need to fetch the user's details from Firestore using their ID
      // We call FirestoreService to get the UserModel from the 'users' collection
      // 'await' waits for Firestore to return the user data
      UserModel user = await _firestoreService.getUser(userId);

      // Save the fetched user data to the currentUser reactive variable
      // This automatically notifies the UI to rebuild with the new user data
      currentUser.value = user;

      // Navigate to the dashboard screen
      // '/dashboard' is the route name we defined somewhere else in the app
      // GetX automatically handles the navigation
      Get.offAllNamed('/dashboard');

      // Show a success message to the user
      // 'Get.snackbar()' displays a snackbar (message at bottom of screen)
      // First parameter is the title, second is the message
      Get.snackbar(
        'Success', // Title of the snackbar
        'Login successful!', // Message to show the user
      );
    }
    // 'catch' block - if anything goes wrong (wrong password, network error, user not found, etc.)
    catch (e) {
      // Extract the error message from the exception
      // 'e.toString()' converts the error into a readable string
      String errorMessage = e.toString();

      // Show an error snackbar to the user
      // This tells them what went wrong (e.g., "User not found" or "Wrong password")
      Get.snackbar(
        'Login Error', // Title of the snackbar
        errorMessage, // The actual error message
        backgroundColor: const Color.fromARGB(255, 244, 67, 54), // Red background
        colorText: const Color.fromARGB(255, 255, 255, 255), // White text
      );
    }
    // 'finally' block - this code runs no matter what (success or error)
    finally {
      // Set isLoading back to false to hide the loading spinner
      // This tells the UI "we're done, stop showing the loader"
      isLoading.value = false;
    }
  }

  // This method logs out the currently logged-in user
  // 'Future<void>' means this is async and doesn't return any value
  Future<void> logout() async {
    // The 'async' keyword means this method can do slow operations

    // 'try' block - we attempt to sign out the user
    try {
      // Call AuthService to sign out the user from Firebase
      // 'await' waits for Firebase to complete the sign out
      await _authService.signOut();

      // Clear the currentUser variable by setting it to null
      // This removes the logged-in user from memory
      currentUser.value = null;

      // Navigate back to the login screen
      // '/login' is the route name for the login page
      // 'offAllNamed' removes all previous routes from the stack
      Get.offAllNamed('/login');

      // Show a success message to the user
      Get.snackbar(
        'Logged Out', // Title
        'You have been logged out successfully.', // Message
      );
    }
    // 'catch' block - if something goes wrong during logout
    catch (e) {
      // Show an error message
      Get.snackbar(
        'Logout Error', // Title
        e.toString(), // The error message
        backgroundColor: const Color.fromARGB(255, 244, 67, 54), // Red background
        colorText: const Color.fromARGB(255, 255, 255, 255), // White text
      );
    }
  }

  // This is a getter method that checks if the current user is a chairperson
  // 'bool' means it returns a boolean (true or false)
  // Getters don't have parentheses - you access them like properties
  bool get isChairperson {
    // Check if currentUser is not null AND their role is 'chairperson'
    // 'currentUser.value' gets the actual UserModel from the reactive variable
    // 'currentUser.value?.role' safely gets the role (or null if currentUser is null)
    // The '==' operator checks if the role equals 'chairperson'
    return currentUser.value?.role == 'chairperson';
  }

  // This is a getter method that checks if the current user is a teacher
  // 'bool' means it returns a boolean (true or false)
  bool get isTeacher {
    // Check if currentUser is not null AND their role is 'teacher'
    // 'currentUser.value' gets the actual UserModel from the reactive variable
    // 'currentUser.value?.role' safely gets the role (or null if currentUser is null)
    // The '==' operator checks if the role equals 'teacher'
    return currentUser.value?.role == 'teacher';
  }
}
